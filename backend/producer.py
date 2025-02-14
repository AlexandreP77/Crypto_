from kafka import KafkaProducer
import json

# producteur Kafka
producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

topic_name = 'send-crypto'

message = {
    'Date': '2023-01-01',
    'Cryptomonnaie': 'Bitcoin',
    'PrixOuverture': 23030.07,
    'PrixCloture': 32431.59,
    'Volume': 3577.43
}

producer.send(topic_name, value=message)
producer.flush()
producer.close()

print("Message envoyé avec succès au topic Kafka")
