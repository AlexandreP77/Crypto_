from flask import Flask, jsonify, request
from flask_cors import CORS
from kafka import KafkaProducer
import json
import pickle
import numpy as np

# Initialisation de l'application Flask
app = Flask(__name__)
CORS(app)  # Active les CORS pour permettre les requêtes du frontend

# Chargement du modèle de régression
with open('models/modele_regression.pkl', 'rb') as f:
    model = pickle.load(f)

# Configuration de Kafka Producer
producer = KafkaProducer(
    bootstrap_servers='kafka:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

@app.route('/')
def index():
    """Endpoint racine"""
    return jsonify({"message": "Bienvenue sur l'API de prédiction"})

@app.route('/predict', methods=['POST'])
def predict():
    """
    Endpoint pour faire une prédiction basée sur les données fournies et envoyer le résultat à Kafka.
    Expects JSON input with:
    {
        "Date": "2023-01-01",
        "Cryptomonnaie": "Bitcoin",
        "PrixOuverture": 23030.07,
        "PrixCloture": 32431.59,
        "Volume": 3577.43
    }
    """
    try:
        data = request.get_json()
        
        # Extraction des données du JSON
        date = data.get("Date")
        cryptomonnaie = data.get("Cryptomonnaie")
        prix_ouverture = float(data.get("PrixOuverture", 0))
        prix_cloture = float(data.get("PrixCloture", 0))
        volume = float(data.get("Volume", 0))

        # Préparation des features pour la prédiction (actuellement basé uniquement sur le Volume)
        features = np.array([[volume]])
        predicted_prix_cloture = model.predict(features)[0]

        # Construction de la réponse
        prediction_result = {
            "Date": date,
            "Cryptomonnaie": cryptomonnaie,
            "PrixOuverture": prix_ouverture,
            "PrixCloture": prix_cloture,
            "Volume": volume,
            "Predicted_PrixCloture": predicted_prix_cloture
        }

        # Envoi du message à Kafka
        topic = "send-crypto"
        producer.send(topic, value=prediction_result)
        producer.flush()

        return jsonify(prediction_result)

    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
