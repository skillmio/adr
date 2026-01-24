# === ADR MSGs === 
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "Checking for ADR updates..."; }
UPDATE_APPLY() { echo "Updating ADR..."; }

USAGE() { echo "Usage: adr <role>"; }

OPTIONS() {
  echo
  echo "Options:"
  echo "  -h, --help        Show help"
  echo "  -l, --list        List roles"
  echo "  -f, --find        Find role"
  echo "  -lg, --lang       Set language"
  echo "  -d, --diag        Diagnostics"
  echo "  -r, --repair     Repair ADR"
}

EXAMPLES() {
  echo
  echo "Examples:"
  echo "  adr wordpress     Install WordPress"
  echo "  adr -f stack      Find a role"
  echo "  adr -lg pt        Set language"
  echo "  adr -d            Diagnostics"
  echo "  adr -r            Repair ADR"
}

ROLE_DOWNLOAD() { echo "Downloading role..."; }
ROLE_NOT_FOUND() { echo "Error: role not found."; }
LANG_SET() { echo "Language saved."; }
DIAG_HEADER() { echo "ADR Diagnostics"; }
REPAIR_START() { echo "Repairing ADR (internet required)..."; }



# === ROLE MSGs ===
MSG_B_ROOT="Ce script doit être exécuté en tant que root"
MSG_START="=== Démarrage du provisionnement de $SOLUTION ==="
MSG_LOGPATH="Fichier de journal sensible (à supprimer après utilisation) : $LOGPATH"
MSG_PROMPT_IP="Entrez l'adresse IP qui sera utilisée pour accéder à $SOLUTION"
MSG_PROMPT_URL="Entrez l'URL ou le nom d'hôte qui sera utilisé pour accéder à $SOLUTION"
MSG_USING_IP="L'adresse IP a été définie sur"
MSG_USING_URL="L'URL a été définie sur"
MSG_INSTALL_PREREQUISITES="Installation des paquets requis"
MSG_VERSION_DETECTED="Version détectée"
MSG_ERR_VERSION="Version non trouvée"
MSG_INSTALL_MARIADB="Installation et configuration de MariaDB"
MSG_INSTALL_POSTGSQL="Installation et configuration de PostgreSQL"
MSG_INSTALL_APACHE="Installation et configuration d'Apache"
MSG_INSTALL_NGINX="Installation et configuration de Nginx"
MSG_INSTALL_PHP="Installation et configuration de PHP"
MSG_INSTALL_PHPMYADMIN="Installation et configuration de phpMyAdmin"
MSG_INSTALL_PGADMIN="Installation et configuration de pgAdmin"
MSG_INSTALL_SOLUTION="Installation et configuration de $SOLUTION"
MSG_FIREWALL="Création des règles d'autorisation sur le pare-feu"
MSG_INSTALL_COMPLETE="Installation de $SOLUTION terminée (CONSERVEZ CES INFORMATIONS)"
MSG_URL=" Accès via URL : http://"
MSG_IP=" Accès via IP : http://"
MSG_USER_LOGIN=" Utilisateur : "
MSG_USER_PASS=" Mot de passe : "
MSG_INSTALL_PATH=" Chemin d'installation : "
MSG_INSTALLED_VER=" Version : "
MSG_DB_NAME=" Nom de la base de données : "
MSG_DB_USER=" Utilisateur BD : "
MSG_DB_PASS=" Mot de passe BD : "
MSG_DB_ROOT=" Mot de passe root MariaDB : "
MSG_SELECT_CONTAINER="Insérez le mode du conteneur : 1=normal, 2=template"
MSG_SELECTED_CONTAINER="Mode du conteneur sélectionné : "
