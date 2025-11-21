#!/bin/bash

# Vérification des variables d'environnement
set -e

# Connexion au serveur Bitwarden
bw config server "${BW_HOST}"

# Connexion avec la clé API si les variables sont définies
if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
    # Log
	echo "Connexion avec la clé API"

	# Connexion avec la clé API
	bw login --apikey --raw

	# Déverrouillage du coffre-fort
	BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
	export BW_SESSION
else
	# Connexion avec nom d'utilisateur et mot de passe
	echo "Connexion avec nom d'utilisateur et mot de passe"

	# Connexion avec nom d'utilisateur et mot de passe
	BW_SESSION=$(bw login "${BW_USER}" --passwordenv BW_PASSWORD --raw)
	export BW_SESSION
fi

# Vérification du déverrouillage du coffre-fort
bw unlock --check

# Log
echo "Lancement de bw server sur le port 8087"

# Lancement du serveur Bitwarden
bw serve --hostname 0.0.0.0 #--disable-origin-protection
