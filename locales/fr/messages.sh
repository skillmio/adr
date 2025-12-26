HEADER() { echo "ADR — Auto-Deploy Role v$1"; }
USAGE() { echo "Utilisation : adr <role>"; }
OPTIONS() { echo "Options :" ; }

OPT_HELP() { echo "  -h, --help          Afficher l'aide"; }
OPT_LIST() { echo "  -l, --list          Lister les rôles disponibles"; }
OPT_FIND() { echo "  -f, --find <nom>    Rechercher un rôle"; }
OPT_LANG() { echo "  -lg, --lang <code>  Définir la langue (en, pt, fr)"; }
OPT_DIAG() { echo "  -d, --diag          Diagnostic ADR"; }
OPT_DIAG_FIX() { echo "  -df, --diag-fix     Réparer l'installation ADR"; }

EXAMPLES() { echo "Exemples :" ; }
EX1() { echo "  adr wordpress        Installer WordPress"; }
EX2() { echo "  adr --find stack     Trouver les rôles contenant 'stack'"; }
EX3() { echo "  adr --lang fr        Définir la langue en français"; }
EX4() { echo "  adr -d               Lancer le diagnostic"; }
EX5() { echo "  adr -df              Réparer l'installation ADR"; }

UPDATE_CHECK() { echo "Vérification des mises à jour ADR..."; }
UPDATE_APPLY() { echo "Mise à jour ADR vers la version $1"; }

LANG_SET() { echo "Langue définie sur $1"; }
LANG_SAVED() { echo "Langue enregistrée pour les prochaines exécutions."; }
LANG_MISSING() { echo "Erreur : code de langue manquant."; }

ROLES_AVAILABLE() { echo "Rôles disponibles :"; }
FIND_MISSING() { echo "Erreur : terme de recherche manquant."; }
FIND_SEARCH() { echo "Recherche des rôles pour : $1"; }

ROLE_DOWNLOAD() { echo "Téléchargement du rôle : $1"; }
ROLE_NOT_FOUND() { echo "Erreur : rôle introuvable."; }

DIAG_HEADER() { echo "Diagnostic ADR"; }
DIAG_FIX_INFO() { echo "Réparation de l'installation ADR (connexion internet requise)..."; }

MSG_MISSING() { echo "Message manquant : $1"; }
