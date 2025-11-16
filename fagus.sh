#!/usr/bin/env bash

# ==============================================================================
# LANCEUR UNIVERSEL FAGUS
# Orchestre le téléchargement, la mise en cache et l'exécution du mailer.
# ==============================================================================

# --- Fonction d'aide ---
# Affiche l'aide et quitte le script.
show_help() {
cat << EOF
Fagus - Un système de notification par e-mail simple et robuste.

Cet outil envoie un message (ou le contenu d'un fichier) par e-mail via une
API Google Apps Script configurée localement.

USAGE:
  fagus.sh <message_source> [subsystem] [cooldown_minutes]
  fagus.sh --help | -h

ARGUMENTS:
  <message_source>    Le message à envoyer, entre guillemets, ou le chemin
                        vers un fichier texte (relatif ou absolu). Requis.

  [subsystem]           Un nom de sous-système optionnel qui sera ajouté au
                        sujet de l'e-mail. Ex: "Backup Error".

  [cooldown_minutes]    Optionnel. Durée en minutes avant qu'un nouvel e-mail
                        puisse être envoyé.
                        Défaut : 60 minutes.
                        Mettre à 0 pour désactiver la limitation et forcer l'envoi.

OPTIONS:
  -h, --help            Affiche cette aide et quitte.

CONFIGURATION:
  Le script requiert un fichier 'fagus.conf' dans le même répertoire, contenant
  les variables PASSWORD, API_URL_ID, et ORIGIN.

EXEMPLES:
  # Envoyer un message simple:
  ./fagus.sh "Le script de nuit est terminé."

  # Envoyer un log d'erreur avec un sous-système:
  ./fagus.sh /var/log/backup.log "Backup Error"

  # Forcer l'envoi d'un message urgent sans limitation de débit:
  ./fagus.sh "Alerte: Espace disque critique !" "Urgent" 0
EOF
}

# --- Traitement des options d'aide ---
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# --- Détermination du chemin du script ---
# ... (le reste du script est identique) ...
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# --- Définition des constantes de l'architecture ---
CONFIG_FILE="${DIR}/fagus.conf"
CORE_SCRIPT="${DIR}/mailer.sh"
GIST_RAW_URL="https://gist.githubusercontent.com/kafkaah/25fe711fc3f31a9197d54ef3b0a77dab/raw/mailer.sh"

# --- Vérification des dépendances ---
check_dependencies() {
  local missing=0
  for cmd in curl date wc head tail iconv readlink; do
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
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Erreur critique : Fichier de configuration '${CONFIG_FILE}' introuvable." >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [ -z "$PASSWORD" ] || [ -z "$API_URL_ID" ] || [ -z "$ORIGIN" ]; then
  echo "Erreur critique : Des variables requises (PASSWORD, API_URL_ID, ORIGIN) sont manquantes dans '${CONFIG_FILE}'." >&2
  exit 1
fi
if [[ "$PASSWORD" == "CHANGEME" || "$API_URL_ID" == "CHANGEME" ]]; then
  echo "Erreur : Les valeurs par défaut n'ont pas été changées dans '${CONFIG_FILE}'." >&2
  exit 1
fi

# --- Normalisation des paramètres ---
ORIGINAL_PWD=$(pwd)
MESSAGE_SOURCE=$1
if [ -f "$MESSAGE_SOURCE" ]; then
  cd "$ORIGINAL_PWD" || exit 1
  MESSAGE_SOURCE=$(readlink -f "$MESSAGE_SOURCE")
fi

# --- Mise à jour du script de base ---
echo "Vérification de la version du mailer centralisé..."
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

"$CORE_SCRIPT" "$MESSAGE_SOURCE" "$2" "$3"
