#!/usr/bin/env bash
# Deploy Firestore + Storage rules for TaskFlow (project: taskflow-4fd64).
# Requires: firebase login (once per machine)

set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="$PATH:/c/Users/ADMIN/AppData/Roaming/npm:$HOME/AppData/Roaming/npm"

echo "Deploying rules to taskflow-4fd64..."
npx -y firebase-tools@latest deploy --only firestore:rules,storage

echo "Done. Check Firestore/Storage → Rules on Firebase Console."
