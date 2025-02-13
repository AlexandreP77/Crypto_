<template>
  <br><br><br><br>
  <div class="mt-10">
    <h1>Objets détectés</h1>
    <p v-if="objects.length === 0">Chargement des objets...</p>
    <ul>
      <li v-for="obj in objects" :key="obj.id">
        {{ obj.name }}
      </li>
    </ul>

    <p v-if="alert">🚨 Alerte : {{ alert.name }} est une menace !</p>
    <p v-else>Aucune menace détectée.</p>
    <br><br>
    <div ref="sceneContainer" class="scene-container text-align-center"></div>
  </div>
</template>

<script>
import { ref, onMounted } from "vue";
import axios from "axios";
import * as THREE from "three";

export default {
  setup() {
    const objects = ref([]);
    const alert = ref(null);
    const sceneContainer = ref(null);

    const fetchData = async () => {
      try {
        const objRes = await axios.get("http://localhost:5000/objects");
        objects.value = objRes.data;

        const alertRes = await axios.get("http://localhost:5000/alerts");
        if (alertRes.data.length > 0) {
          alert.value = alertRes.data[0];
        }

        updateScene(objects.value);
      } catch (error) {
        console.error("Erreur API :", error);
      }
    };

    let scene, camera, renderer;
    const updateScene = (data) => {
      if (!sceneContainer.value) return;

      // Nettoie la scène si elle existe déjà
      if (renderer) {
        sceneContainer.value.innerHTML = "";
      }

      // Création de la scène
      scene = new THREE.Scene();
      camera = new THREE.OrthographicCamera(-50, 50, 50, -50, 0.1, 1000);
      camera.position.z = 10;

      renderer = new THREE.WebGLRenderer();
      renderer.setSize(400, 400);
      sceneContainer.value.appendChild(renderer.domElement);

      // Ajoute des objets en 2D
      data.forEach((obj) => {
        const geometry = new THREE.PlaneGeometry(5, 5);
        const material = new THREE.MeshBasicMaterial({ color: obj.name === alert.value?.name ? 0xff0000 : 0x00ff00 });
        const mesh = new THREE.Mesh(geometry, material);

        // Place les objets selon x et y
        mesh.position.set(obj.x, obj.y, 0);
        scene.add(mesh);
      });

      renderer.render(scene, camera);
    };

    onMounted(() => {
      fetchData();
    });

    return { objects, alert, sceneContainer };
  }
};
</script>
