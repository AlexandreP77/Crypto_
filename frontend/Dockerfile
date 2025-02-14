# Utiliser une image de base Node.js
FROM node:21.1.0-alpine

# Définir le répertoire de travail
WORKDIR /frontend

# Copier les fichiers package.json et package-lock.json avant pour tirer parti du cache Docker
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste des fichiers du projet
COPY . .

# Exposer le port sur lequel l'application s'exécute
EXPOSE 3000

# Commande pour démarrer l'application
CMD ["npm", "run", "dev"]
