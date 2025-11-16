#!/usr/bin/env bash

# ==============================================================================
# LANCEUR UNIVERSEL FAGUS
# Orchestre le téléchargement, la mise en cache et l'exécution du mailer.
# Distribué via le dépôt Git Fagus.
# ==============================================================================

# --- Détermination du chemin du script ---
# Cette section détermine le répertoire absolu où se trouve le script (le dépôt Fagus).
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# --- Changement de répertoire de travail ---
# On se place dans le répertoire du script pour pouvoir utiliser des chemins relatifs.
cd "$DIR" || { echo "Erreur critique : Impossible d'accéder au répertoire ${DIR}" >&2; exit 1; }

# --- Définition des constantes de l'architecture ---
CONFIG_FILE="fagus.conf"
CORE_SCRIPT="mailer.sh"
# URL pointant vers la dernière version du Gist
GIST_RAW_URL="https://gist.githubusercontent.com/kafkaah/25fe711fc3f31a9197d54ef3b0a77dab/raw/mailer.sh"

# --- Vérification des dépendances ---
check_dependencies() {
  local missing=0
  for cmd in curl date wc head tail iconv; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "Erreur critique : Dépendance manquante. La commande '${cmd}' est introuvable." >&2
      missing=1
    fi
  done
  if [ "$missing" -eq 1 ]; then
    echo "Veuillez installer les paquets manquants avant d'utiliser Fagus." >&2
    exit 1
  fi
}

# --- Exécution principale ---
check_dependencies

# --- Chargement de la configuration locale ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Erreur critique : Fichier de configuration '${CONFIG_FILE}' introuvable." >&2
  echo "Veuillez vous assurer que '${CONFIG_FILE}' existe dans le même répertoire que fagus.sh." >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Valide que les variables nécessaires ont bien été chargées
if [ -z "$PASSWORD" ] || [ -z "$API_URL_ID" ] || [ -z "$ORIGIN" ]; then
  echo "Erreur critique : Des variables requises (PASSWORD, API_URL_ID, ORIGIN) sont manquantes dans '${CONFIG_FILE}'." >&2
  echo "Veuillez éditer le fichier de configuration et remplir toutes les valeurs." >&2
  exit 1
fi
if [[ "$PASSWORD" == "CHANGEME" || "$API_URL_ID" == "CHANGEME" ]]; then
  echo "Erreur : Les valeurs par défaut n'ont pas été changées dans '${CONFIG_FILE}'." >&2
  echo "Veuillez éditer le fichier de configuration et remplacer les valeurs 'CHANGEME'." >&2
  exit 1
fi

# --- Mise à jour du script de base (logique de cache) ---
echo "Vérification de la version du mailer centralisé..."
if curl -s -f -o "${CORE_SCRIPT}.tmp" "$GIST_RAW_URL"; then
  mv "${CORE_SCRIPT}.tmp" "$CORE_SCRIPT"
  echo "Le mailer a été mis à jour avec succès."
else
  rm -f "${CORE_SCRIPT}.tmp"
  echo "Avertissement : Impossible de télécharger la dernière version du mailer. Utilisation de la version locale en cache."
fi

# --- Exécution du script de base ---
if [ ! -f "$CORE_SCRIPT" ]; then
  echo "Erreur critique : Aucune version locale du mailer n'existe et le téléchargement a échoué." >&2
  exit 1
fi

chmod u+x "$CORE_SCRIPT"

export API_URL="https://script.google.com/macros/s/${API_URL_ID}/exec"
export PASSWORD
export ORIGIN

# Exécute le script en lui passant tous les paramètres reçus par le lanceur
./"$CORE_SCRIPT" "$@"
