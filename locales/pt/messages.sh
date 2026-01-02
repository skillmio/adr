# === ADR MSGs === 
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "A verificar atualizações do ADR..."; }
UPDATE_APPLY() { echo "A atualizar o ADR..."; }

USAGE() { echo "Utilização: adr <função>"; }

OPTIONS() {
  echo
  echo "Opções:"
  echo "  -h, --help        Mostrar ajuda"
  echo "  -l, --list        Listar funções"
  echo "  -f, --find        Procurar função"
  echo "  -lg, --lang       Definir idioma"
  echo "  -d, --diag        Diagnósticos"
  echo "  -r, --repair     Reparar ADR"
}

EXAMPLES() {
  echo
  echo "Exemplos:"
  echo "  adr wordpress     Instalar WordPress"
  echo "  adr -f stack      Procurar uma função"
  echo "  adr -lg pt        Definir idioma"
  echo "  adr -d            Diagnósticos"
  echo "  adr -r            Reparar ADR"
}

ROLE_DOWNLOAD() { echo "A transferir função..."; }
ROLE_NOT_FOUND() { echo "Erro: função não encontrada."; }
LANG_SET() { echo "Idioma guardado."; }
DIAG_HEADER() { echo "Diagnósticos ADR"; }
REPAIR_START() { echo "A reparar o ADR (ligação à internet necessária)..."; }



# === ROLE MSGs === 
MSG_START="=== A iniciar a instalação de $SOLUTION ==="
MSG_LOGPATH="Sensitive log file (delete after use): $LOGPATH"
MSG_PROMPT_IP="Introduza o endereço IP que será utilizado para aceder a $SOLUTION"
MSG_PROMPT_URL="Introduza o URL ou nome de host que será utilizado para aceder a $SOLUTION"
MSG_USING_IP="O IP foi definido como"
MSG_USING_URL="O URL foi definido como"
MSG_INSTALL_PREREQUISITES="A instalar pacotes necessários"
MSG_INSTALL_MARIADB="A instalar e configurar o MariaDB"
MSG_INSTALL_POSTGSQL="A instalar e configurar o PostgreSQL"
MSG_INSTALL_APACHE="A instalar e configurar o Apache"
MSG_INSTALL_NGINX="A instalar e configurar o Nginx"
MSG_INSTALL_PHP="A instalar e configurar o PHP"
MSG_INSTALL_PHPMYADMIN="A instalar e configurar o phpMyAdmin"
MSG_INSTALL_PGADMIN="Installing and Configuring pgAdmin"
MSG_INSTALL_SOLUTION="A instalar e configurar $SOLUTION"
MSG_FIREWALL="A criar regras de permissão na firewall"
MSG_INSTALL_COMPLETE="Instalação de $SOLUTION concluída (GUARDE ESTA INFORMAÇÃO)"
MSG_URL=" Access via URL: http://"
MSG_IP=" Access via IP: http://"
MSG_USER_LOGIN=" User: "
MSG_USER_PASS=" Pass: "
MSG_INSTALL_PATH=" Caminho de instalação: "
MSG_INSTALLED_VER=" Version: "
MSG_DB_NAME=" Nome da base de dados: "
MSG_DB_USER=" Utilizador da BD: "
MSG_DB_PASS=" Palavra-passe da BD: "
MSG_DB_ROOT=" MariaDB root password: "


