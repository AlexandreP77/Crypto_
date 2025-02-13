from pyspark.sql import SparkSession, functions as F

def main():
    spark = SparkSession.builder \
        .appName("BatchCryptoAnalysis") \
        .getOrCreate()
    
    # 1) Lecture des CSV depuis HDFS
    df = spark.read.csv(
        "hdfs://namenode:9000/cryptodata/*.csv",
        header=True,
        inferSchema=True
    )
    
    # 2) Agrégation : prix de clôture moyen par cryptomonnaie
    df_grouped = df.groupBy("product_id").agg(
        F.mean("sale_price").alias("AvgClosingPrice")
    )
    
    # 3) Mise en forme pour Kafka:
    #    - Kafka attend deux colonnes obligatoires "key" et "value"
    #    - On peut mettre la cryptomonnaie en key, et un JSON complet en value.
    df_for_kafka = df_grouped.select(
        F.col("product_id").cast("string").alias("key"),
        F.to_json(F.struct("product_id", "AvgClosingPrice")).alias("value")
    )
    
    # 4) Écriture dans Kafka (topic: "data-crypto")
    #    => Assurez-vous que le topic existe ou qu'il soit créé dynamiquement
    df_for_kafka.write \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "kafka:9092") \
        .option("topic", "data-crypto") \
        .save()

    spark.stop()

if __name__ == "__main__":
    main()
        