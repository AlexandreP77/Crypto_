<template>
  <nav class="bg-gray-800 text-white p-4 fixed top-0 w-full z-50 shadow">
    <div class="container mx-auto flex items-center justify-between flex-wrap p-2">
      <!-- Logo et titre, cliquable pour revenir à la page d'accueil -->
      <div class="flex items-center flex-shrink-0 text-white mr-6 cursor-pointer">
        <img src="\src\assets\img\images.jpg" alt="Logo Cinema Vue" class="h-12 w-16 mr-2">
        <span class="font-semibold text-xl tracking-tight">Astronomiques Real-Time</span>
      </div>
      <!-- Bouton menu mobile -->
      <div class="block lg:hidden">
        <button @click="toggle" class="flex items-center px-3 py-2 border rounded text-teal-200 border-teal-400 hover:text-white hover:border-white">
          <svg class="fill-current h-3 w-3" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><title>Menu</title><path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/></svg>
        </button>
      </div>
      <!-- Liens de navigation et champ de recherche -->
      <div :class="{'hidden': !isOpen, 'block': isOpen}" class="w-full block flex-grow lg:flex lg:items-center lg:w-auto">
        <div class="text-sm lg:flex-grow">
          <a href="#accueil" class="block mt-4 lg:inline-block lg:mt-0 text-teal-200 hover:text-white mr-4">
            Accueil
          </a>
          <a href="#nouveautes" class="block mt-4 lg:inline-block lg:mt-0 text-teal-200 hover:text-white mr-4">
            Nouveautés
          </a>
          <a href="#genres" class="block mt-4 lg:inline-block lg:mt-0 text-teal-200 hover:text-white">
            Genres
          </a>
        </div>
        
      </div>
    </div>
  </nav>
</template>

<script>
export default {
  name: 'Navbar',
  data() {
    return {
      isOpen: false
    };
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    }
  }
}
</script>

<style scoped>
/* Tu peux personnaliser davantage le style ici si nécessaire */
</style>
