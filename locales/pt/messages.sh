msg() {
  case "$1" in
    VERSION) echo "Versão:" ;;
    USAGE) echo "Uso: adr <role>" ;;
    OPTIONS) echo "Opções:" ;;
    HELP) echo "  -h, --help            Mostrar esta ajuda" ;;
    LIST) echo "  -l, --list            Listar roles disponíveis" ;;
    FIND) echo "  -f, --find <palavra>  Procurar um role (pesquisa fuzzy)" ;;
    LANG) echo "  --lang <código>       Definir idioma permanentemente" ;;
    DIAG) echo "  diag                  Executar diagnóstico do ADR" ;;
    EXAMPLES) echo "Exemplos:" ;;
    EX1) echo "  adr wordpress" ;;
    EX2) echo "  adr --find stack" ;;
    EX3) echo "  adr --lang pt" ;;
    LANG_SET) echo "Idioma definido para %s" ;;
    LANG_PERSIST) echo "Idioma guardado para futuras execuções." ;;
    FETCH_ROLES) echo "A obter roles disponíveis do ADR..." ;;
    AVAILABLE_ROLES) echo "Roles disponíveis:" ;;
    SEARCHING) echo "A procurar roles por:" ;;
    NO_MATCH) echo "Nenhum role correspondente encontrado." ;;
    DOWNLOAD_ROLE) echo "A descarregar role:" ;;
    EXEC_ROLE) echo "A executar role:" ;;
    ROLE_NOT_FOUND) echo "Erro: role não encontrado." ;;
    UPDATE_CHECK) echo "A verificar atualizações do ADR..." ;;
    UPDATE_APPLY) echo "A atualizar ADR para a versão" ;;
    UNSUPPORTED_DISTRO) echo "Aviso: distribuição não suportada." ;;
    DIAG_TITLE) echo "Diagnóstico do ADR" ;;
    DIAG_FIX_TITLE) echo "Diagnóstico do ADR — Modo de correção" ;;
    DIAG_INTERNET) echo "É necessária ligação à internet." ;;
    DIAG_DONE) echo "Correção concluída." ;;
    *) echo "$1" ;;
  esac
}
