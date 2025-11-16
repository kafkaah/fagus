#!/usr/bin/env bash

# ==============================================================================
# LANCEUR UNIVERSEL FAGUS
# Orchestre le téléchargement, la mise en cache et l'exécution du mailer.
# Distribué via le dépôt Git Fagus.
# ==============================================================================

# --- Détermination du chemin du script ---
# ... (partie identique) ...
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# --- Définition des constantes de l'architecture ---
# Le répertoire de fagus.sh est le répertoire de travail
CONFIG_FILE="${DIR}/fagus.conf"
CORE_SCRIPT="${DIR}/mailer.sh"
GIST_RAW_URL="https://gist.githubusercontent.com/kafkaah/25fe711fc3f31a9197d54ef3b0a77dab/raw/mailer.sh"

# --- Vérification des dépendances ---
# ... (partie identique) ...
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
check_dependencies

# --- Chargement de la configuration locale ---
# ... (partie identique) ...
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Erreur critique : Fichier de configuration '${CONFIG_FILE}' introuvable." >&2
  exit 1
fi
source "$CONFIG_FILE"

if [ -z "$PASSWORD" ] || [ -z "$API_URL_ID" ] || [ -z "$ORIGIN" ]; then
  echo "Erreur critique : Variables manquantes dans '${CONFIG_FILE}'." >&2
  exit 1
fi
if [[ "$PASSWORD" == "CHANGEME" || "$API_URL_ID" == "CHANGEME" ]]; then
  echo "Erreur : Les valeurs par défaut n'ont pas été changées dans '${CONFIG_FILE}'." >&2
  exit 1
fi

# --- **NOUVELLE SECTION : Normalisation des paramètres** ---
# Sauvegarde du répertoire de travail actuel
ORIGINAL_PWD=$(pwd)

# Convertit le premier paramètre (source du message) en chemin absolu s'il s'agit d'un fichier.
# Cela garantit que le script 'mailer.sh' le trouvera, peu importe son propre répertoire de travail.
MESSAGE_SOURCE=$1
if [ -f "$MESSAGE_SOURCE" ]; then
  # On se place temporairement dans le répertoire d'appel pour résoudre le chemin
  cd "$ORIGINAL_PWD" || exit 1
  MESSAGE_SOURCE=$(readlink -f "$MESSAGE_SOURCE")
  # On retourne au répertoire du script pour la suite
  cd "$DIR" || exit 1
fi
# --- Fin de la nouvelle section ---


# --- Mise à jour du script de base (logique de cache) ---
echo "Vérification de la version du mailer centralisé..."
# On se place dans le répertoire du script pour que les fichiers soient au bon endroit
cd "$DIR" || exit 1
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

# Exécute le script en lui passant le chemin potentiellement modifié et le reste des paramètres
./"$CORE_SCRIPT" "$MESSAGE_SOURCE" "$2" "$3"
