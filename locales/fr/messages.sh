# === ADR MSGs === 
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



# === ROLE MSGs === 
MSG_START="=== Starting $SOLUTION installation ==="
MSG_LOGPATH=" Log file: $LOGPATH"
MSG_PROMPT_IP="Enter the IP address that will be used to access $SOLUTION"
MSG_PROMPT_URL="Enter the URL or Hostname that will be used to access $SOLUTION"
MSG_USING_IP="IP has been set to"
MSG_USING_URL="URL has been set to"
MSG_INSTALL_PREREQUISITES="Installing Required Packages"
MSG_INSTALL_MARIADB="Installing and Configuring MariaDB"
MSG_INSTALL_POSTGSQL="Installing and Configuring PostgreSQL"
MSG_INSTALL_APACHE="Installing and Configuring Apache"
MSG_INSTALL_NGINX="Installing and Configuring Nginx"
MSG_INSTALL_PHP="Installing and Configuring PHP"
MSG_INSTALL_PHPMYADMIN="Installing and Configuring phpMyAdmin"
MSG_INSTALL_SOLUTION="Installing and Configuring $SOLUTION"
MSG_FIREWALL="Creating allow rules on the firewall"
MSG_INSTALL_COMPLETE="$SOLUTION installation completed (SAVE THIS INFO)"
MSG_URL=" URL: http://"
MSG_IP=" IP:  http://"
MSG_INSTALL_PATH=" Install path: "
MSG_INSTALLED_VER=" Installed version: "
MSG_DB_NAME=" Database name: "
MSG_DB_USER=" DB User: "
MSG_DB_PASS=" DB Pass: "
MSG_DB_ROOT=" MySQL root password: "
