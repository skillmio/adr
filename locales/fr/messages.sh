msg() {
  case "$1" in
    VERSION) echo "Version :" ;;
    USAGE) echo "Utilisation : adr <role>" ;;
    OPTIONS) echo "Options :" ;;
    HELP) echo "  -h, --help            Afficher l'aide" ;;
    LIST) echo "  -l, --list            Lister les rôles disponibles" ;;
    FIND) echo "  -f, --find <mot>      Rechercher un rôle (recherche floue)" ;;
    LANG) echo "  -lg, --lang <code>    Définir la langue de façon permanente" ;;
    DIAG) echo "  -d, --diag            Exécuter le diagnostic ADR" ;;
    DIAG_FIX) echo "  -d-f, --diag-fix      Réparer l'installation ADR" ;;
    EXAMPLES) echo "Exemples :" ;;
    EX1) echo "  adr wordpress        Installer WordPress" ;;
    EX2) echo "  adr -f stack         Rechercher des rôles contenant « stack »" ;;
    EX3) echo "  adr -lg pt           Définir la langue en portugais (en, fr disponibles)" ;;
    EX4) echo "  adr -d               Exécuter le diagnostic ADR" ;;
    EX5) echo "  adr -d-f             Réparer l'installation ADR" ;;
    LANG_SET) echo "Langue définie sur %s" ;;
    LANG_PERSIST) echo "Langue enregistrée pour les prochaines exécutions." ;;
    FETCH_ROLES) echo "Récupération des rôles ADR disponibles..." ;;
    SEARCHING) echo "Recherche de rôles pour :" ;;
    NO_MATCH) echo "Aucun rôle correspondant trouvé." ;;
    DOWNLOAD_ROLE) echo "Téléchargement du rôle :" ;;
    EXEC_ROLE) echo "Exécution du rôle :" ;;
    ROLE_NOT_FOUND) echo "Erreur : rôle introuvable." ;;
    UPDATE_CHECK) echo "Vérification des mises à jour ADR..." ;;
    UPDATE_APPLY) echo "Mise à jour d'ADR vers la version" ;;
    DIAG_TITLE) echo "Diagnostic ADR" ;;
    DIAG_FIX_TITLE) echo "Diagnostic ADR — Mode réparation" ;;
    DIAG_INTERNET) echo "Une connexion Internet est requise." ;;
    DIAG_DONE) echo "Réparation terminée." ;;
    *) echo "$1" ;;
  esac
}
