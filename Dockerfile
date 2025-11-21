## Étape 1 : Utilisation d'une image Alpine légère pour télécharger le binaire Bitwarden CLI
FROM alpine:latest AS downloader

## Version de Bitwarden CLI à utiliser (modifiable lors du build)
ARG BW_VERSION=

## Installation des dépendances, téléchargement et vérification du binaire Bitwarden CLI
RUN apk update --no-cache \
 && apk add --no-cache curl jq \
    # Télécharge le binaire Bitwarden CLI
 && curl -sLo bw.zip "https://github.com/bitwarden/clients/releases/download/cli-v${BW_VERSION}/bw-oss-linux-${BW_VERSION}.zip" \
    # Récupère le hash SHA256 officiel depuis l'API GitHub et prépare le fichier de somme
 && echo $(\
    curl -sL "https://api.github.com/repos/bitwarden/clients/releases/tags/cli-v${BW_VERSION}" | \
    jq -r ".assets[] | select(.name == \"bw-oss-linux-${BW_VERSION}.zip\") | .digest" | \
    cut -f2 -d:) bw.zip > sum.txt \
    # Vérifie l'intégrité du binaire téléchargé
 && sha256sum -sc sum.txt \
    # Décompresse le binaire
 && unzip bw.zip

## Étape 2 : Utilisation d'une image Debian pour l'exécution finale
FROM debian:sid

## Copie du binaire Bitwarden CLI depuis l'étape précédente
COPY --from=downloader bw /usr/local/bin/

## Utilisation d'un utilisateur non-root pour plus de sécurité
USER 1000

## Définition du répertoire de travail
WORKDIR /bw

## Définition de la variable d'environnement HOME
ENV HOME=/bw

## Copie du script d'entrée dans l'image
COPY entrypoint.sh /

## Commande d'entrée du conteneur
ENTRYPOINT ["/entrypoint.sh"]
