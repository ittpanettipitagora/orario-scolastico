#!/bin/bash
# Anonimizza l'export di Orario Facile e pubblica su GitHub.
# Uso: ./pubblica.sh            (commit "Aggiornamento orario <oggi>")
#      ./pubblica.sh "messaggio" (commit con messaggio personalizzato)
set -euo pipefail
cd "$(dirname "$0")"

# 1. pagine dei docenti
rm -rf Docenti

# 2. cella DOCENTI in index.html + eventuali marker di commento orfani
python3 - <<'PY'
import re
p = 'index.html'
s = open(p, encoding='utf-8', errors='surrogateescape').read()
s = re.sub(r"<TD[^>]*>\s*(?:<!--[^>]*-->\s*)*(?:<!--\s*)?DOCENTI\b.*?</TD>\s*(?:-->\s*)?", "", s, count=1, flags=re.S)
s = re.sub(r"^\s*(<!--|-->)\s*$\n?", "", s, flags=re.M)
open(p, 'w', encoding='utf-8', errors='surrogateescape').write(s)
PY

# 3. verifica: nessun link ai docenti, nessun nome in chiaro
if grep -rq 'Docenti/' Classi Aule index.html; then
  echo "ERRORE: link a Docenti/ ancora presenti:"; grep -rl 'Docenti/' Classi Aule index.html; exit 1
fi
if [ -f ~/.orario-docenti.txt ] && grep -rqFf ~/.orario-docenti.txt Classi Aule index.html; then
  echo "ERRORE: nomi di docenti in chiaro:"; grep -rlFf ~/.orario-docenti.txt Classi Aule index.html; exit 1
fi

# 4. commit + push
git add -A
if git diff --cached --quiet; then echo "Nessuna modifica da pubblicare."; exit 0; fi
git commit -q -m "${1:-Aggiornamento orario $(date +%d/%m/%Y)}"
git push origin main
echo "Pubblicato: $(git log -1 --oneline)"
