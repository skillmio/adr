case "$1" in VERSION) echo "Versão:" ;; LANG_SET) echo "Idioma definido para %s" ;; FETCH_ROLES) echo "A obter roles disponíveis do ADR..." ;;
USAGE() { echo "Uso: adr <role>"; }
OPTIONS() { echo "Opções:"; }

OPT_HELP() { echo "  -h, --help          Mostrar ajuda"; }
OPT_LIST() { echo "  -l, --list          Listar roles disponíveis"; }
OPT_FIND() { echo "  -f, --find <nome>   Procurar um role"; }
OPT_LANG() { echo "  -lg, --lang <código> Definir idioma (en, pt, fr)"; }
OPT_DIAG() { echo "  -d, --diag          Diagnóstico do ADR"; }
OPT_DIAG_FIX() { echo "  -df, --diag-fix     Reparar instalação do ADR"; }

EXAMPLES() { echo "Exemplos:"; }
EX1() { echo "  adr wordpress        Instalar WordPress"; }
EX2() { echo "  adr --find stack     Procurar roles com 'stack'"; }
EX3() { echo "  adr --lang pt        Definir idioma para Português"; }
EX4() { echo "  adr -d               Executar diagnóstico"; }
EX5() { echo "  adr -df              Reparar instalação do ADR"; }

UPDATE_CHECK() { echo "A verificar atualizações do ADR..."; }
UPDATE_APPLY() { echo "A atualizar ADR para a versão $1"; }

LANG_SET() { echo "Idioma definido para $1"; }
LANG_SAVED() { echo "Idioma guardado para futuras execuções."; }
LANG_MISSING() { echo "Erro: código de idioma em falta."; }

ROLES_AVAILABLE() { echo "Roles disponíveis:"; }
FIND_MISSING() { echo "Erro: termo de pesquisa em falta."; }
FIND_SEARCH() { echo "A procurar roles por: $1"; }

ROLE_DOWNLOAD() { echo "A transferir role: $1"; }
ROLE_NOT_FOUND() { echo "Erro: role não encontrado."; }

DIAG_HEADER() { echo "Diagnóstico do ADR"; }
DIAG_FIX_INFO() { echo "A reparar a instalação do ADR (necessita internet)..."; }

MSG_MISSING() { echo "Mensagem em falta: $1"; }
