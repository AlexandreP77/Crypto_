from pyspark.sql import SparkSession
from pyspark.sql.functions import avg, col, row_number
from pyspark.sql.window import Window

def main():
    # Initialisation de Spark
    spark = SparkSession.builder.appName("CryptoBatchProcessing").getOrCreate()

    # Chemin HDFS contenant tous les fichiers CSV des cryptos
    input_path = "hdfs://namenode:9000/cryptodata/"

    # Lecture de tous les fichiers CSV dans le répertoire
    df = spark.read.option("header", "true").option("inferSchema", "true").csv(input_path)

    # suppression des doublons et lignes qui on des valeurs Null
    df_clean = df.dropDuplicates().na.drop()

    # calc prix moyen de cloture par crypto
    df_avg = df_clean.groupBy("Cryptomonnaie").agg(avg("PrixCloture").alias("PrixCloture_Moyen"))
    df_avg.show()

    # identifier, pour chaque date, la cryptomonnaie avec le volume d'échange le plus élevé
    window_spec = Window.partitionBy("Date").orderBy(col("Volume").desc())
    df_vol = df_clean.withColumn("rang", row_number().over(window_spec)).filter(col("rang") == 1).drop("rang")
    df_vol.show()

    # chemins de sortie dans HDFS
    output_path_avg = "hdfs://namenode:9000/crypto_results/avg_cloture"
    output_path_vol = "hdfs://namenode:9000/crypto_results/vol_max"

    # svg des résultats en CSV et Parquet
    df_avg.write.mode("overwrite").option("header", "true").csv(output_path_avg)
    df_vol.write.mode("overwrite").parquet(output_path_vol)

    # fin de session spark
    spark.stop()

if __name__ == '__main__':
    main()
