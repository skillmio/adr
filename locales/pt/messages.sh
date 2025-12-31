# === ADR MSGs === 
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "A verificar atualizações do ADR..."; }
UPDATE_APPLY() { echo "A atualizar o ADR..."; }

USAGE() { echo "Uso: adr <role>"; }

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
  echo "  adr -f stack      Procurar role"
  echo "  adr -lg pt        Definir idioma"
  echo "  adr -d            Diagnóstico"
  echo "  adr -r            Reparar ADR"
}

ROLE_DOWNLOAD() { echo "A transferir role..."; }
ROLE_NOT_FOUND() { echo "Erro: role não encontrado."; }
LANG_SET() { echo "Idioma guardado."; }
DIAG_HEADER() { echo "Diagnóstico ADR"; }
REPAIR_START() { echo "A reparar o ADR (internet necessário)..."; }



# === ROLE MSGs === 
MSG_PROMPT_IP="Enter the IP address to use for accessing $SOLUTION"
MSG_PROMPT_URL="Enter the URL or hostname to use for accessing $SOLUTION"
MSG_USING_IP="IP has been set to"
MSG_USING_URL="URL has been set to"
MSG_INSTALL_MARIADB="Installing and Configure MariaDB"
MSG_INSTALL_APACHE="Installing and Configure Apache"
MSG_INSTALL_PHP="Installing and Configure PHP"
MSG_INSTALL_SOLUTION="Installing and Configure "
