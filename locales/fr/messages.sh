VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "Vérification des mises à jour ADR..."; }
UPDATE_APPLY() { echo "Mise à jour de ADR..."; }

USAGE() { echo "Utilisation: adr <role>"; }

OPTIONS() {
  echo
  echo "Options:"
  echo "  -h, --help        Afficher l'aide"
  echo "  -l, --list        Lister les rôles"
  echo "  -f, --find        Rechercher un rôle"
  echo "  -lg, --lang       Définir la langue"
  echo "  -d, --diag        Diagnostic"
  echo "  -r, --repair     Réparer ADR"
}

EXAMPLES() {
  echo
  echo "Exemples:"
  echo "  adr wordpress     Installer WordPress"
  echo "  adr -f stack      Rechercher un rôle"
  echo "  adr -lg fr        Définir la langue"
  echo "  adr -d            Diagnostic"
  echo "  adr -r            Réparer ADR"
}

ROLE_DOWNLOAD() { echo "Téléchargement du rôle..."; }
ROLE_NOT_FOUND() { echo "Erreur : rôle introuvable."; }
LANG_SET() { echo "Langue enregistrée."; }
DIAG_HEADER() { echo "Diagnostic ADR"; }
REPAIR_START() { echo "Réparation d'ADR (internet requis)..."; }

#===BESZEL=====
MSG_STEP_COLLECT="Collecte de la configuration requise"
MSG_STEP_VERSION="Détection de la dernière version de $SOLUTION"
MSG_STEP_PACKAGES="Installation des paquets requis"
MSG_STEP_USER="Vérification de l'utilisateur $SOLUTION"
MSG_STEP_ARCH="Détection de l’architecture du système"
MSG_STEP_DOWNLOAD="Téléchargement de $SOLUTION"
MSG_STEP_INSTALL="Installation de $SOLUTION"
MSG_STEP_SERVICES="Configuration des services"
MSG_STEP_FIREWALL="Configuration du pare-feu"

MSG_PROMPT_IP="Entrez l’adresse IP pour accéder à $SOLUTION"
MSG_PROMPT_URL="Entrez l’URL ou le nom d’hôte de $SOLUTION"

MSG_USING_IP="IP utilisée"
MSG_USING_URL="URL utilisée"

MSG_TAIL_HINT="Vous pouvez suivre la progression avec :"
MSG_TAIL_CMD="tail -f"

MSG_VERSION_DETECTED="Dernière version détectée"
MSG_PROXY_FAIL="Échec du proxy, utilisation de GitHub"
MSG_ERR_VERSION="Impossible de déterminer la version"
MSG_ERR_ARCH="Architecture non prise en charge"

MSG_SAVE_HEADER="Conservez ces informations"
MSG_SAVE_VERSION="Version installée"
MSG_SAVE_PATH="Chemin d’installation"
MSG_SAVE_SERVICE="Service systemd"
MSG_SAVE_URL="URL d’accès"
MSG_SAVE_LOG="Fichier de log"

