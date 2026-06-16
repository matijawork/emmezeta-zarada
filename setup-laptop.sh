#!/bin/bash
# Automatski spaja ovaj laptop s app-om
TOKEN=$(gh auth token 2>/dev/null)
OWNER=$(gh api user --jq .login 2>/dev/null)

if [ -z "$TOKEN" ] || [ -z "$OWNER" ]; then
  echo "gh CLI nije autentificiran. Pokreni: gh auth login"
  exit 1
fi

B64_OWNER=$(echo -n "$OWNER" | base64 | tr '+/' '-_' | tr -d '=')
B64_TOKEN=$(echo -n "$TOKEN" | base64 | tr '+/' '-_' | tr -d '=')

URL="https://matijawork.github.io/emmezeta-zarada/#setup-${B64_OWNER}-${B64_TOKEN}"

echo "Otvaranje app-a za $OWNER..."
open "$URL"
