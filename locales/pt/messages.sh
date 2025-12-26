# =====================================
# ADR — Auto-Deploy Role (PT)
# =====================================

declare -A MESSAGES=(
  # General
  [ADR_TITLE]="ADR — Função de Implementação Automática"
  [USAGE]="Uso: adr <função>"
  [ERROR]="Erro"
  [WARNING]="Aviso"
  [TIP]="Dica"

  # Help
  [HELP_HEADER]="Opções:"
  [HELP_HELP]="Mostrar esta mensagem de ajuda"
  [HELP_LIST]="Listar funções disponíveis"
  [HELP_FIND]="Procurar uma função pelo nome (pesquisa aproximada)"
  [HELP_LANG]="Definir idioma permanentemente"
  [HELP_EXAMPLES]="Exemplos:"
  [HELP_EXAMPLE_DEPLOY]="adr wordpress"
  [HELP_EXAMPLE_FIND]="adr --find stack"
  [HELP_EXAMPLE_LANG]="adr --lang pt"

  # Language
  [LANG_SET]="Idioma definido para '%s'."
  [LANG_PERSIST]="Esta definição será utilizada em todas as execuções futuras do ADR."

  # System detection
  [DETECTED_SYSTEM]="Sistema detetado: %s %s → %s"
  [UNSUPPORTED_DISTRO]="Distribuição não suportada '%s'."
  [SUPPORTED_DISTRO_HINT]="O ADR é destinado ao AlmaLinux e distribuições compatíveis com RHEL."

  # Update
  [CHECKING_UPDATES]="A verificar atualizações do ADR..."
  [LOCAL_VERSION]="Versão local:"
  [REMOTE_VERSION]="Versão remota:"
  [UPDATING]="A atualizar o ADR para a versão %s..."
  [UPDATED_SUCCESS]="ADR atualizado com sucesso."

  # Roles
  [AVAILABLE_ROLES]="Funções ADR disponíveis:"
  [FETCHING_ROLES]="A obter funções ADR disponíveis..."
  [MATCHING_ROLES]="Funções correspondentes:"
  [NO_MATCHING_ROLES]="Nenhuma função correspondente encontrada."
  [DEPLOYING_ROLE]="A implementar a função: %s"
  [ROLE_NOT_FOUND]="A função '%s' não foi encontrada para este sistema."

  # Input errors
  [NO_ROLE_SPECIFIED]="Nenhuma função especificada."
  [NO_SEARCH_TERM]="Nenhum termo de pesquisa fornecido."
  [LANG_REQUIRED]="--lang requer um código de idioma."

  # Snapshot / safety
  [FRESH_SYSTEM_REQUIRED]="As funções ADR destinam-se a ser executadas num sistema novo."
  [SNAPSHOT_RECOMMENDED]="Crie sempre um snapshot do sistema antes de implementar uma função."
)
