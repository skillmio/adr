# =====================================
# ADR — Auto-Deploy Role (FR)
# =====================================

declare -A MESSAGES=(
  # General
  [ADR_TITLE]="ADR — Déploiement Automatique de Rôles"
  [USAGE]="Utilisation : adr <rôle>"
  [ERROR]="Erreur"
  [WARNING]="Avertissement"
  [TIP]="Astuce"

  # Help
  [HELP_HEADER]="Options :"
  [HELP_HELP]="Afficher ce message d’aide"
  [HELP_LIST]="Lister les rôles disponibles"
  [HELP_FIND]="Rechercher un rôle par nom (recherche approximative)"
  [HELP_LANG]="Définir la langue de façon permanente"
  [HELP_EXAMPLES]="Exemples :"
  [HELP_EXAMPLE_DEPLOY]="adr wordpress"
  [HELP_EXAMPLE_FIND]="adr --find stack"
  [HELP_EXAMPLE_LANG]="adr --lang fr"

  # Language
  [LANG_SET]="Langue définie sur « %s »."
  [LANG_PERSIST]="Ce paramètre sera utilisé pour toutes les futures exécutions d’ADR."

  # System detection
  [DETECTED_SYSTEM]="Système détecté : %s %s → %s"
  [UNSUPPORTED_DISTRO]="Distribution non prise en charge « %s »."
  [SUPPORTED_DISTRO_HINT]="ADR est destiné à AlmaLinux et aux distributions compatibles RHEL."

  # Update
  [CHECKING_UPDATES]="Vérification des mises à jour ADR..."
  [LOCAL_VERSION]="Version locale :"
  [REMOTE_VERSION]="Version distante :"
  [UPDATING]="Mise à jour d’ADR vers la version %s..."
  [UPDATED_SUCCESS]="ADR mis à jour avec succès."

  # Roles
  [AVAILABLE_ROLES]="Rôles ADR disponibles :"
  [FETCHING_ROLES]="Récupération des rôles ADR disponibles..."
  [MATCHING_ROLES]="Rôles correspondants :"
  [NO_MATCHING_ROLES]="Aucun rôle correspondant trouvé."
  [DEPLOYING_ROLE]="Déploiement du rôle : %s"
  [ROLE_NOT_FOUND]="Le rôle « %s » est introuvable pour ce système."

  # Input errors
  [NO_ROLE_SPECIFIED]="Aucun rôle spécifié."
  [NO_SEARCH_TERM]="Aucun terme de recherche fourni."
  [LANG_REQUIRED]="--lang nécessite un code de langue."

  # Snapshot / safety
  [FRESH_SYSTEM_REQUIRED]="Les rôles ADR doivent être exécutés sur un système vierge."
  [SNAPSHOT_RECOMMENDED]="Créez toujours un snapshot du système avant de déployer un rôle."
)
