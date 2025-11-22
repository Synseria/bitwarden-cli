#!/bin/bash
set -e

# Fonction de vérification
check_required_env() {
    local var_name="$1"
    if [ -z "${!var_name}" ]; then
        echo "❌ Erreur : Variable '$var_name' manquante."
        exit 1
    fi
}

echo "🔍 Vérification de la configuration..."
check_required_env "BW_HOST"
check_required_env "BW_CLIENTID"
check_required_env "BW_CLIENTSECRET"
check_required_env "BW_PASSWORD"

# ==============================================================================
# 1. CONFIGURATION SILENCIEUSE (La modification est ICI)
# ==============================================================================
# Au lieu de lancer 'bw config server' qui tente de joindre le cloud,
# on injecte directement la configuration dans le fichier JSON.

CONFIG_DIR="$HOME/.config/Bitwarden CLI"
mkdir -p "$CONFIG_DIR"

# On écrit directement la config pour forcer l'URL locale dès le départ
cat > "$CONFIG_DIR/data.json" <<EOF
{
  "environmentUrls": {
    "base": "${BW_HOST}",
    "api": null,
    "identity": null,
    "web": null,
    "icons": null,
    "notifications": null,
    "events": null
  }
}
EOF

echo "🌐 Configuration serveur forcée sur : ${BW_HOST}"

# ==============================================================================
# 2. CONNEXION
# ==============================================================================

echo "🔑 Authentification..."
# On redirige les erreurs potentielles de connexion non critiques
if ! bw login --apikey > /dev/null 2>&1; then
    echo "❌ Échec de l'authentification API. Vérifiez vos identifiants ou l'URL."
    # On affiche l'erreur réelle maintenant si ça a échoué
    bw login --apikey
    exit 1
fi
echo "✅ Authentifié."

echo "🔓 Déverrouillage du coffre..."
# On capture la session. Si ça échoue, BW_SESSION sera vide ou contiendra une erreur
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw 2>/dev/null)

if [ -z "$BW_SESSION" ]; then
    echo "❌ Erreur : Impossible de déverrouiller le coffre (Mot de passe maître incorrect ?)"
    exit 1
fi

echo "✅ Coffre déverrouillé."

# ==============================================================================
# 3. LANCEMENT
# ==============================================================================

echo "🚀 Lancement du serveur sur le port ${BW_PORT:-8087}"
exec bw serve --hostname 0.0.0.0 --port ${BW_PORT:-8087}