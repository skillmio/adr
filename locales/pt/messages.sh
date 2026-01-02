# === ADR MSGs === 
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "Vérification des mises à jour d’ADR..."; }
UPDATE_APPLY() { echo "Mise à jour d’ADR..."; }

USAGE() { echo "Utilização: adr <role>"; }

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
  echo "  adr -f stack      Procurar um role"
  echo "  adr -lg pt        Définir la langue"
  echo "  adr -d            Diagnósticos"
  echo "  adr -r            Réparer ADR"
}

ROLE_DOWNLOAD() { echo "A descarregar role..."; }
ROLE_NOT_FOUND() { echo "Erreur : rôle introuvable."; }
LANG_SET() { echo "Langue enregistrée."; }
DIAG_HEADER() { echo "Diagnóstico do ADR"; }
REPAIR_START() { echo "A reparar o ADR (ligação à Internet necessária)..."; }



# === ROLE MSGs === 
MSG_START="=== Démarrage de l’installation de $SOLUTION ==="
MSG_LOGPATH="Ficheiro de log sensível (apagar após utilização): $LOGPATH"
MSG_PROMPT_IP="Introduza o endereço IP que será usado para aceder ao $SOLUTION"
MSG_PROMPT_URL="Introduza o URL ou hostname que será usado para aceder ao $SOLUTION"
MSG_USING_IP="O IP foi definido para"
MSG_USING_URL="O URL foi definido para"
MSG_INSTALL_PREREQUISITES="Installation des paquets requis"
MSG_INSTALL_MARIADB="A instalar e configurar MariaDB"
MSG_INSTALL_POSTGSQL="A instalar e configurar PostgreSQL"
MSG_INSTALL_APACHE="A instalar e configurar Apache"
MSG_INSTALL_NGINX="A instalar e configurar Nginx"
MSG_INSTALL_PHP="A instalar e configurar PHP"
MSG_INSTALL_PHPMYADMIN="A instalar e configurar phpMyAdmin"
MSG_INSTALL_PGADMIN="A instalar e configurar pgAdmin"
MSG_INSTALL_SOLUTION="Installation et configuration de $SOLUTION"
MSG_FIREWALL="Création des règles d’autorisation sur le pare-feu"
MSG_INSTALL_COMPLETE="Instalação do $SOLUTION concluída (GUARDE ESTA INFORMAÇÃO)"
MSG_URL=" Acesso via URL: http://"
MSG_IP=" Acesso via IP: http://"
MSG_USER_LOGIN=" Utilizador: "
MSG_USER_PASS=" Palavra-passe: "
MSG_INSTALL_PATH=" Chemin d’installation : "
MSG_INSTALLED_VER=" Versão: "
MSG_DB_NAME=" Nom de la base de données : "
MSG_DB_USER=" Utilisateur BD : "
MSG_DB_PASS=" Mot de passe BD : "
MSG_DB_ROOT=" Palavra-passe root do MariaDB: "


