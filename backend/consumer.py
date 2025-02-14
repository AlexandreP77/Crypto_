from kafka import KafkaConsumer
import json

# consommateur Kafka
consumer = KafkaConsumer(
    'data-crypto',
    bootstrap_servers='kafka:9092',
    auto_offset_reset='earliest',
    value_deserializer=lambda v: json.loads(v.decode('utf-8'))
)

print("En attente de messages...")

for message in consumer:
    print(f"Message reçu : {message.value}")
