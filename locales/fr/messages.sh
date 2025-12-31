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
MSG_PROMPT_IP="Enter the IP address to use for accessing $SOLUTION"
MSG_PROMPT_URL="Enter the URL or hostname to use for accessing $SOLUTION"
MSG_USING_IP="IP has been set to"
MSG_USING_URL="URL has been set to"
MSG_INSTALL_MARIADB="Installing and Configure MariaDB"
MSG_INSTALL_APACHE="Installing and Configure Apache"
MSG_INSTALL_PHP="Installing and Configure PHP"
MSG_INSTALL_SOLUTION="Installing and Configure "
