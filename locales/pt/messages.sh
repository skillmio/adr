msg() {
  case "$1" in
    VERSION) echo "Versão:" ;;
    USAGE) echo "Uso: adr <role>" ;;
    OPTIONS) echo "Opções:" ;;
    HELP) echo "  -h, --help            Mostrar esta ajuda" ;;
    LIST) echo "  -l, --list            Listar roles disponíveis" ;;
    FIND) echo "  -f, --find <termo>    Procurar um role (pesquisa difusa)" ;;
    LANG) echo "  --lang <código>       Definir idioma permanentemente" ;;
    DOCTOR) echo "  doctor                Executar diagnóstico do ADR" ;;
    EXAMPLES) echo "Exemplos:" ;;
    EX1) echo "  adr wordpress" ;;
    EX2) echo "  adr --find stack" ;;
    EX3) echo "  adr --lang fr" ;;
    LANG_SET) echo "Idioma definido para %s" ;;
    LANG_PERSIST) echo "Idioma guardado para futuras execuções." ;;
    FETCH_ROLES) echo "A obter roles ADR..." ;;
    AVAILABLE_ROLES) echo "Roles disponíveis:" ;;
    SEARCHING) echo "A procurar roles por:" ;;
    NO_MATCH) echo "Nenhum role encontrado." ;;
    DOWNLOAD_ROLE) echo "A transferir role:" ;;
    EXEC_ROLE) echo "A executar role:" ;;
    ROLE_NOT_FOUND) echo "Erro: role não encontrado." ;;
    UPDATE_CHECK) echo "A verificar atualizações do ADR..." ;;
    UPDATE_APPLY) echo "A atualizar ADR para a versão" ;;
    UNSUPPORTED_DISTRO) echo "Aviso: distribuição não suportada." ;;
    DETECTED) echo "Sistema detetado:" ;;
    *) echo "$1" ;;
  esac
}
