# === ADR MSGs ===
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "A verificar atualizações do ADR..."; }
UPDATE_APPLY() { echo "A atualizar o ADR..."; }

USAGE() { echo "Utilização: adr <role>"; }

OPTIONS() {
  echo
  echo "Opções:"
  echo "  -h, --help        Mostrar ajuda"
  echo "  -l, --list        Listar roles"
  echo "  -f, --find        Procurar role"
  echo "  -lg, --lang       Definir idioma"
  echo "  -d, --diag        Diagnóstico"
  echo "  -r, --repair     Reparar ADR"
}

EXAMPLES() {
  echo
  echo "Exemplos:"
  echo "  adr wordpress     Instalar WordPress"
  echo "  adr -f stack      Procurar um role"
  echo "  adr -lg pt        Definir idioma"
  echo "  adr -d            Diagnóstico"
  echo "  adr -r            Reparar ADR"
}

ROLE_DOWNLOAD() { echo "A descarregar role..."; }
ROLE_NOT_FOUND() { echo "Erro: role não encontrado."; }
LANG_SET() { echo "Idioma guardado."; }
DIAG_HEADER() { echo "Diagnóstico do ADR"; }
REPAIR_START() { echo "A reparar o ADR (ligação à Internet necessária)..."; }



# === ROLE MSGs ===
MSG_B_ROOT="Este script deve ser executado como root"
MSG_START="=== A iniciar o provisionamento de $SOLUTION ==="
MSG_LOGPATH="Ficheiro de log sensível (eliminar após a utilização): $LOGPATH"
MSG_PROMPT_IP="Introduza o endereço IP que será utilizado para aceder ao $SOLUTION"
MSG_PROMPT_URL="Introduza o URL ou o nome do host que será utilizado para aceder ao $SOLUTION"
MSG_USING_IP="O IP foi definido como"
MSG_USING_URL="O URL foi definido como"
MSG_INSTALL_PREREQUISITES="A instalar pacotes necessários"
MSG_VERSION_DETECTED="Versão encontrada"
MSG_ERR_VERSION="Versão não encontrada"
MSG_INSTALL_MARIADB="A instalar e configurar o MariaDB"
MSG_INSTALL_POSTGSQL="A instalar e configurar o PostgreSQL"
MSG_INSTALL_APACHE="A instalar e configurar o Apache"
MSG_INSTALL_NGINX="A instalar e configurar o Nginx"
MSG_INSTALL_PHP="A instalar e configurar o PHP"
MSG_INSTALL_PHPMYADMIN="A instalar e configurar o phpMyAdmin"
MSG_INSTALL_PGADMIN="A instalar e configurar o pgAdmin"
MSG_INSTALL_SOLUTION="A instalar e configurar o $SOLUTION"
MSG_FIREWALL="A criar regras de permissão no firewall"
MSG_INSTALL_COMPLETE="Instalação do $SOLUTION concluída (GUARDE ESTA INFORMAÇÃO)"
MSG_URL=" Acesso via URL: http://"
MSG_IP=" Acesso via IP: http://"
MSG_USER_LOGIN=" Utilizador: "
MSG_USER_PASS=" Palavra-passe: "
MSG_INSTALL_PATH=" Caminho de instalação: "
MSG_INSTALLED_VER=" Versão: "
MSG_DB_NAME=" Nome da base de dados: "
MSG_DB_USER=" Utilizador da BD: "
MSG_DB_PASS=" Palavra-passe da BD: "
MSG_DB_ROOT=" Palavra-passe root do MariaDB: "
MSG_SELECT_CONTAINER="Insira o modo do contentor: 1=normal, 2=template"
MSG_SELECTED_CONTAINER="Modo do contentor selecionado: "
