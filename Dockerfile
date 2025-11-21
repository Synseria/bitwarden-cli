# Étape 1 : Utilisation de Node.js LTS sur Alpine
FROM node:24-alpine

# Déclaration de la version (Obligatoire pour l'utiliser après)
ARG BW_VERSION

# 2. Installation de Bitwarden CLI via NPM
RUN npm install -g @bitwarden/cli@${BW_VERSION}

# 3. VÉRIFICATION DE L'INSTALLATION
RUN echo "🔍 Vérification de l'installation..." \
    && INSTALLED_VERSION=$(bw --version) \
    && echo "Version installée : $INSTALLED_VERSION" \
    && echo "Version demandée  : $BW_VERSION" \
    && bw --version > /dev/null \
    && echo "Bitwarden CLI fonctionne correctement."

# 4. Création utilisateur sécurisé
RUN adduser -D -u 1000 bwuser

# 5. Gestion du script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && chown bwuser:bwuser /entrypoint.sh

# 6. Configuration de l'environnement
WORKDIR /bw
RUN chown bwuser:bwuser /bw

# Définition de la variable d'environnement HOME
ENV HOME=/bw
ENV BW_HOST="https://api.bitwarden.com"
ENV TZ="Europe/Paris"
ENV BW_PORT="8087"

# Passage en utilisateur non-root
USER bwuser

# Commande d'entrée
ENTRYPOINT ["/entrypoint.sh"]