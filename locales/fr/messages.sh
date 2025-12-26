msg() {
  case "$1" in
    VERSION) echo "Version :" ;;
    USAGE) echo "Utilisation : adr <role>" ;;
    OPTIONS) echo "Options :" ;;
    HELP) echo "  -h, --help            Afficher l’aide" ;;
    LIST) echo "  -l, --list            Lister les rôles disponibles" ;;
    FIND) echo "  -f, --find <mot>      Rechercher un rôle (recherche floue)" ;;
    LANG) echo "  --lang <code>         Définir la langue de façon permanente" ;;
    DOCTOR) echo "  doctor                Exécuter le diagnostic ADR" ;;
    EXAMPLES) echo "Exemples :" ;;
    EX1) echo "  adr wordpress" ;;
    EX2) echo "  adr --find stack" ;;
    EX3) echo "  adr --lang fr" ;;
    LANG_SET) echo "Langue définie sur %s" ;;
    LANG_PERSIST) echo "Langue enregistrée pour les prochaines exécutions." ;;
    FETCH_ROLES) echo "Récupération des rôles ADR..." ;;
    AVAILABLE_ROLES) echo "Rôles disponibles :" ;;
    SEARCHING) echo "Recherche de rôles pour :" ;;
    NO_MATCH) echo "Aucun rôle correspondant trouvé." ;;
    DOWNLOAD_ROLE) echo "Téléchargement du rôle :" ;;
    EXEC_ROLE) echo "Exécution du rôle :" ;;
    ROLE_NOT_FOUND) echo "Erreur : rôle introuvable." ;;
    UPDATE_CHECK) echo "Vérification des mises à jour ADR..." ;;
    UPDATE_APPLY) echo "Mise à jour de ADR vers la version" ;;
    UNSUPPORTED_DISTRO) echo "Avertissement : distribution non prise en charge." ;;
    DETECTED) echo "Système détecté :" ;;
    *) echo "$1" ;;
  esac
}
