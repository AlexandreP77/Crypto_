<template>
  <div class="container mt-10">
    <h2 class="text-center">📊 Prédiction du Prix de Clôture</h2>

    <div class="card shadow p-4 mt-10">
      <form @submit.prevent="predict">
        <div class="mb-3">
          <label class="form-label">📅 Date :</label>
          <input type="date" class="form-control" v-model="date" required />
        </div>

        <div class="mb-3">
          <label class="form-label">💰 Cryptomonnaie :</label>
          <input type="text" class="form-control" v-model="cryptomonnaie" required placeholder="Ex: Bitcoin, Ethereum" />
        </div>

        <div class="mb-3">
          <label class="form-label">📈 Prix Ouverture :</label>
          <input type="number" class="form-control" v-model="prixOuverture" required placeholder="Ex: 23030.07" />
        </div>

        <div class="mb-3">
          <label class="form-label">📉 Prix Clôture :</label>
          <input type="number" class="form-control" v-model="prixCloture" required placeholder="Ex: 32431.59" />
        </div>

        <div class="mb-3">
          <label class="form-label">📊 Volume :</label>
          <input type="number" class="form-control" v-model="volume" required placeholder="Ex: 3577.43" />
        </div>

        <button type="submit" class="btn btn-primary w-100">🔍 Prédire</button>
      </form>

      <div v-if="prediction !== null" class="alert alert-success mt-4">
        📢 Prix prédit : <strong>{{ prediction }}</strong>
      </div>
      
      <div v-if="kafkaStatus" class="alert alert-info mt-3">
        {{ kafkaStatus }}
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  data() {
    return {
      date: '',
      cryptomonnaie: '',
      prixOuverture: '',
      prixCloture: '',
      volume: '',
      prediction: null,
      kafkaStatus: ''
    };
  },
  methods: {
    async predict() {
      try {
        const response = await axios.post('http://localhost:5000/predict', {
          Date: this.date,
          Cryptomonnaie: this.cryptomonnaie,
          PrixOuverture: parseFloat(this.prixOuverture),
          PrixCloture: parseFloat(this.prixCloture),
          Volume: parseFloat(this.volume)
        });

        this.prediction = response.data.Predicted_PrixCloture;
        this.kafkaStatus = "✅ Prédiction envoyée à Kafka !";
      } catch (error) {
        console.error('Erreur de prédiction:', error);
        this.kafkaStatus = "❌ Erreur lors de l'envoi à Kafka.";
      }
    }
  }
};
</script>

<style>
body {
  background-color: #f8f9fa;
}

.container {
  max-width: 500px;
  margin: auto;
}

.card {
  background: white;
  border-radius: 10px;
}

.btn-primary {
  background-color: #007bff;
  border: none;
}

.btn-primary:hover {
  background-color: #0056b3;
}
</style>
