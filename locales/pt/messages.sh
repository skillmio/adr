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

#===BESZEL=====
MSG_STEP_COLLECT="A recolher configuração necessária"
MSG_STEP_VERSION="A detetar a versão mais recente do $SOLUTION"
MSG_STEP_PACKAGES="A instalar pacotes necessários"
MSG_STEP_USER="A garantir que o utilizador $SOLUTION existe"
MSG_STEP_ARCH="A detetar a arquitetura do sistema"
MSG_STEP_DOWNLOAD="A descarregar o $SOLUTION"
MSG_STEP_INSTALL="A instalar o $SOLUTION"
MSG_STEP_SERVICES="A configurar serviços"
MSG_STEP_FIREWALL="A configurar firewall"

MSG_PROMPT_IP="Introduza o IP para aceder ao $SOLUTION"
MSG_PROMPT_URL="Introduza o URL/nome do host do $SOLUTION"

MSG_USING_IP="IP utilizado"
MSG_USING_URL="URL utilizado"

MSG_TAIL_HINT="Pode acompanhar o progresso da instalação com:"
MSG_TAIL_CMD="tail -f"

MSG_VERSION_DETECTED="Versão mais recente detetada"
MSG_PROXY_FAIL="Falha no proxy, a usar GitHub"
MSG_ERR_VERSION="Não foi possível determinar a versão"
MSG_ERR_ARCH="Arquitetura não suportada"

MSG_SAVE_HEADER="Guarde esta informação"
MSG_SAVE_VERSION="Versão instalada"
MSG_SAVE_PATH="Diretório de instalação"
MSG_SAVE_SERVICE="Serviço systemd"
MSG_SAVE_URL="URL de acesso"
MSG_SAVE_LOG="Ficheiro de log"

