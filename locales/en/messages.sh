# =====================================
# ADR — Auto-Deploy Role (EN)
# =====================================

declare -A MESSAGES=(
  # General
  [ADR_TITLE]="ADR — Auto-Deploy Role"
  [USAGE]="Usage: adr <role>"
  [ERROR]="Error"
  [WARNING]="Warning"
  [TIP]="Tip"

  # Help
  [HELP_HEADER]="Options:"
  [HELP_HELP]="Show this help message"
  [HELP_LIST]="List available roles"
  [HELP_FIND]="Find a role by name (fuzzy search)"
  [HELP_LANG]="Set language permanently"
  [HELP_EXAMPLES]="Examples:"
  [HELP_EXAMPLE_DEPLOY]="adr wordpress"
  [HELP_EXAMPLE_FIND]="adr --find stack"
  [HELP_EXAMPLE_LANG]="adr --lang pt"

  # Language
  [LANG_SET]="Language set to '%s'."
  [LANG_PERSIST]="This setting will be used for all future ADR runs."

  # System detection
  [DETECTED_SYSTEM]="Detected system: %s %s → %s"
  [UNSUPPORTED_DISTRO]="Unsupported distribution '%s'."
  [SUPPORTED_DISTRO_HINT]="ADR targets AlmaLinux and RHEL-compatible systems."

  # Update
  [CHECKING_UPDATES]="Checking for ADR updates..."
  [LOCAL_VERSION]="Local version:"
  [REMOTE_VERSION]="Remote version:"
  [UPDATING]="Updating ADR to version %s..."
  [UPDATED_SUCCESS]="ADR updated successfully."

  # Roles
  [AVAILABLE_ROLES]="Available ADR roles:"
  [FETCHING_ROLES]="Fetching available ADR roles..."
  [MATCHING_ROLES]="Matching roles:"
  [NO_MATCHING_ROLES]="No matching roles found."
  [DEPLOYING_ROLE]="Deploying role: %s"
  [ROLE_NOT_FOUND]="Role '%s' not found for this system."

  # Input errors
  [NO_ROLE_SPECIFIED]="No role specified."
  [NO_SEARCH_TERM]="No search term provided."
  [LANG_REQUIRED]="--lang requires a language code."

  # Snapshot / safety
  [FRESH_SYSTEM_REQUIRED]="ADR roles are intended to be executed on a fresh system."
  [SNAPSHOT_RECOMMENDED]="Always create a system snapshot before deploying a role."
)
