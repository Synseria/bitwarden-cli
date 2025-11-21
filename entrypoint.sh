#!/bin/bash
set -e

# ==============================================================================
# 1. VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
# ==============================================================================

# Fonction pour vérifier la présence d'une variable
check_required_env() {
	# Vérifie si la variable est définie et non vide
    local var_name="$1"
	# Vérification indirecte de la variable
    if [ -z "${!var_name}" ]; then
		# Message d'erreur
        echo "Erreur critique : La variable d'environnement '$var_name' est manquante ou vide."

		# Sortie avec code d'erreur
        exit 1
    fi
}

# Log
echo "Vérification de la configuration..."

# Liste des variables obligatoires
check_required_env "BW_HOST"
check_required_env "BW_CLIENTID"
check_required_env "BW_CLIENTSECRET"
check_required_env "BW_PASSWORD"

# Log
echo "Configuration validée."

# ==============================================================================
# 2. CONFIGURATION ET CONNEXION
# ==============================================================================

# Configuration du serveur
echo "Configuration du serveur : ${BW_HOST}"

# Application de la configuration
bw config server "${BW_HOST}"

# Log
echo "Authentification via API Key..."

# Connexion via API Key
bw login --apikey

# Log
echo "Déverrouillage du coffre..."

# Déverrouillage du coffre
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

# Vérification de la session
if [ -z "$BW_SESSION" ]; then
	# Log
    echo "❌ Erreur : Impossible de récupérer la session (Mot de passe incorrect ?)"

	# Sortie avec code d'erreur
    exit 1
fi

# Vérification finale
if bw unlock --check > /dev/null 2>&1; then
	# Log
    echo "Coffre déverrouillé avec succès."
else
	# Log
    echo "Erreur : Le coffre semble toujours verrouillé."

	# Sortie avec code d'erreur
    exit 1
fi

# ==============================================================================
# 3. LANCEMENT DU SERVEUR
# ==============================================================================

# Log
echo "Lancement du serveur Bitwarden CLI sur le port ${BW_PORT:-8087}"

# Exécution du serveur
exec bw serve --hostname 0.0.0.0 --port ${BW_PORT:-8087}