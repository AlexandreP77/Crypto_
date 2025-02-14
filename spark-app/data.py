from pyspark.sql import SparkSession
from pyspark.sql.functions import input_file_name
import os

spark = SparkSession.builder.appName("CryptoHDFSMonitor").getOrCreate()

hdfs_path = "hdfs://namenode:9000/cryptodata/"
hdfs_output_path = "hdfs://namenode:9000/cryptodata/resultpredict/data.csv"
local_output_dir = "/cryptodata/resultpredict/"

# Création du répertoire de sortie local si inexistant
if not os.path.exists(local_output_dir):
    os.makedirs(local_output_dir)

# Lecture en streaming des fichiers Parquet
df = spark.readStream.format("parquet").load(hdfs_path)
df = df.withColumn("file_name", input_file_name())

def process_batch(batch_df, batch_id):
    if batch_df.count() == 0:
        return  # Ignore les batchs vides

    from py4j.java_gateway import java_import
    java_import(spark._jvm, 'org.apache.hadoop.fs.FileSystem')
    java_import(spark._jvm, 'org.apache.hadoop.fs.Path')

    hadoop_conf = spark._jsc.hadoopConfiguration()
    fs = spark._jvm.FileSystem.get(hadoop_conf)
    
    hdfs_file = spark._jvm.Path(hdfs_output_path)

    # Vérifier si le fichier HDFS existe
    if fs.exists(hdfs_file):
        file_status = fs.getFileStatus(hdfs_file)
        
        if file_status.getLen() == 0:
            # Si le fichier HDFS est vide, on écrit dedans (sans l'effacer)
            batch_df.coalesce(1).write.mode("append").csv(hdfs_output_path)
        else:
            # Si le fichier HDFS contient déjà des données, on écrit un nouveau fichier
            batch_df.coalesce(1).write.mode("append").csv(os.path.join(local_output_dir, f"batch_{batch_id}.csv"))
    else:
        # Si le fichier n'existe pas, on le crée
        batch_df.coalesce(1).write.mode("overwrite").csv(hdfs_output_path)

# Écriture du stream en traitant chaque batch avec la fonction `process_batch`
query = df.writeStream \
    .foreachBatch(process_batch) \
    .option("checkpointLocation", "/tmp/spark-checkpoint-hdfs") \
    .start()

query.awaitTermination()
