msg() {
  case "$1" in
    VERSION) echo "Versão:" ;;
    USAGE) echo "Uso: adr <role>" ;;
    OPTIONS) echo "Opções:" ;;
    HELP) echo "  -h, --help            Mostrar esta ajuda" ;;
    LIST) echo "  -l, --list            Listar roles disponíveis" ;;
    FIND) echo "  -f, --find <palavra>  Procurar um role (pesquisa fuzzy)" ;;
    LANG) echo "  -lg, --lang <código>  Definir idioma permanentemente" ;;
    DIAG) echo "  -d, --diag            Executar diagnóstico do ADR" ;;
    DIAG_FIX) echo "  -d-f, --diag-fix      Reparar a instalação do ADR" ;;
    EXAMPLES) echo "Exemplos:" ;;
    EX1) echo "  adr wordpress        Instalar o WordPress" ;;
    EX2) echo "  adr -f stack         Procurar roles com 'stack' no nome" ;;
    EX3) echo "  adr -lg pt           Definir idioma para Português (en, fr disponíveis)" ;;
    EX4) echo "  adr -d               Executar diagnóstico do ADR" ;;
    EX5) echo "  adr -d-f             Reparar a instalação do ADR" ;;
    LANG_SET) echo "Idioma definido para %s" ;;
    LANG_PERSIST) echo "Idioma guardado para futuras execuções." ;;
    FETCH_ROLES) echo "A obter roles disponíveis do ADR..." ;;
    SEARCHING) echo "A procurar roles por:" ;;
    NO_MATCH) echo "Nenhum role correspondente encontrado." ;;
    DOWNLOAD_ROLE) echo "A descarregar role:" ;;
    EXEC_ROLE) echo "A executar role:" ;;
    ROLE_NOT_FOUND) echo "Erro: role não encontrado." ;;
    UPDATE_CHECK) echo "A verificar atualizações do ADR..." ;;
    UPDATE_APPLY) echo "A atualizar ADR para a versão" ;;
    DIAG_TITLE) echo "Diagnóstico do ADR" ;;
    DIAG_FIX_TITLE) echo "Diagnóstico do ADR — Modo de correção" ;;
    DIAG_INTERNET) echo "É necessária ligação à internet." ;;
    DIAG_DONE) echo "Correção concluída." ;;
    *) echo "$1" ;;
  esac
}
