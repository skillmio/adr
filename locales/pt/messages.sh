# === ADR MSGs === 
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "Vérification des mises à jour d’ADR..."; }
UPDATE_APPLY() { echo "Mise à jour d’ADR..."; }

USAGE() { echo "Utilisation : adr <rôle>"; }

OPTIONS() {
  echo
  echo "Options :"
  echo "  -h, --help        Afficher l’aide"
  echo "  -l, --list        Lister les rôles"
  echo "  -f, --find        Rechercher un rôle"
  echo "  -lg, --lang       Définir la langue"
  echo "  -d, --diag        Diagnósticos"
  echo "  -r, --repair     Réparer ADR"
}

EXAMPLES() {
  echo
  echo "Exemples :"
  echo "  adr wordpress     Installer WordPress"
  echo "  adr -f stack      Rechercher un rôle"
  echo "  adr -lg pt        Définir la langue"
  echo "  adr -d            Diagnósticos"
  echo "  adr -r            Réparer ADR"
}

ROLE_DOWNLOAD() { echo "Téléchargement du rôle..."; }
ROLE_NOT_FOUND() { echo "Erreur : rôle introuvable."; }
LANG_SET() { echo "Langue enregistrée."; }
DIAG_HEADER() { echo "Diagnostics ADR"; }
REPAIR_START() { echo "Réparation d’ADR (connexion Internet requise)..."; }



# === ROLE MSGs === 
MSG_START="=== Démarrage de l’installation de $SOLUTION ==="
MSG_LOGPATH="Fichier journal sensible (à supprimer après utilisation) : $LOGPATH"
MSG_PROMPT_IP="Entrez l’adresse IP qui sera utilisée pour accéder à $SOLUTION"
MSG_PROMPT_URL="Entrez l’URL ou le nom d’hôte qui sera utilisé pour accéder à $SOLUTION"
MSG_USING_IP="L’adresse IP a été définie sur"
MSG_USING_URL="L’URL a été définie sur"
MSG_INSTALL_PREREQUISITES="Installation des paquets requis"
MSG_INSTALL_MARIADB="Installation et configuration de MariaDB"
MSG_INSTALL_POSTGSQL="Installation et configuration de PostgreSQL"
MSG_INSTALL_APACHE="Installation et configuration d’Apache"
MSG_INSTALL_NGINX="Installation et configuration de Nginx"
MSG_INSTALL_PHP="Installation et configuration de PHP"
MSG_INSTALL_PHPMYADMIN="Installation et configuration de phpMyAdmin"
MSG_INSTALL_PGADMIN="Installation et configuration de pgAdmin"
MSG_INSTALL_SOLUTION="Installation et configuration de $SOLUTION"
MSG_FIREWALL="Création des règles d’autorisation sur le pare-feu"
MSG_INSTALL_COMPLETE="Installation de $SOLUTION terminée (CONSERVEZ CES INFORMATIONS)"
MSG_URL=" Accès via URL : http://"
MSG_IP=" Accès via IP : http://"
MSG_USER_LOGIN=" Utilisateur : "
MSG_USER_PASS=" Mot de passe : "
MSG_INSTALL_PATH=" Chemin d’installation : "
MSG_INSTALLED_VER=" Version : "
MSG_DB_NAME=" Nom de la base de données : "
MSG_DB_USER=" Utilisateur BD : "
MSG_DB_PASS=" Mot de passe BD : "
MSG_DB_ROOT=" Mot de passe root MariaDB : "


