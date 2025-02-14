from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, avg, to_json, struct, to_timestamp, window
from pyspark.sql.types import StructType, StructField, StringType, FloatType

spark = SparkSession.builder.appName("CryptoStreaming").getOrCreate()

schema = StructType([
    StructField("Date", StringType(), True),
    StructField("Cryptomonnaie", StringType(), True),
    StructField("PrixOuverture", FloatType(), True),
    StructField("PrixCloture", FloatType(), True),
    StructField("Volume", FloatType(), True)
])

kafka_df = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("subscribe", "send-crypto") \
    .load()

json_df = kafka_df.selectExpr("CAST(value AS STRING) as json_string")

data_df = json_df.select(from_json(col("json_string"), schema).alias("data")).select("data.*")

data_df = data_df.withColumn("Date", to_timestamp(col("Date"), "yyyy-MM-dd HH:mm:ss"))

streaming_avg = data_df \
    .withWatermark("Date", "10 minutes") \
    .groupBy("Cryptomonnaie", window("Date", "10 minutes")) \
    .agg(avg("PrixCloture").alias("PrixCloture_Moyen"))

result_df = streaming_avg.select(to_json(struct("*")).alias("value"))

query = result_df.writeStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka:9092") \
    .option("topic", "data-crypto") \
    .option("checkpointLocation", "/tmp/spark-checkpoint-crypto") \
    .outputMode("append") \
    .start()

query.awaitTermination()


# commande  /spark/bin/spark-submit --master spark://spark-master:7077 /app/crypto_streaming.py
