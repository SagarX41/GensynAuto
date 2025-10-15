#!/bin/bash
set -e

echo "🚀 Applying All Fixes and Patches"
echo "--------------------------------------------------"
# -------------------------------------
# 1️⃣ Replace page.tsx with Latest
# -------------------------------------
echo ""
echo "📥 Updating page.tsx with local version..."

PAGE_DEST="$HOME/rl-swarm/modal-login/app/page.tsx"
cp "$HOME/MyGensynNodeSetup/page.tsx" "$PAGE_DEST"

if [ $? -eq 0 ]; then
  echo "✅ Successfully updated: page.tsx"
else
  echo "❌ Failed to update page.tsx."
fi
# -------------------------------------
# ✅ Completion Message
# -------------------------------------
echo ""
echo "🎉 All patches and fixes have been successfully applied!"
echo "💡 Your setup is now ready to roll! 🚀"
