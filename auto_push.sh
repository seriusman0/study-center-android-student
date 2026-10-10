#!/bin/bash
# Auto-commit helper — commits tracked changes and pushes to origin/main.
#
# SAFETY NOTES (do not weaken these):
#   * NO --force / --force-with-lease on 'main'. Forcing main can silently
#     destroy commits pushed from another machine (see the 2026-09-27
#     "Merge remote branch (accepting theirs)" incident). If the push is
#     rejected, resolve the divergence by hand.
#   * 'git add -u' only stages files git ALREADY tracks. Never 'git add .' —
#     that is how build artifacts, logcat dumps, keystores and
#     node_modules/ end up in the repo.
#   * Untracked files are reported, not staged. Add them explicitly when
#     you actually want them versioned.
cd "$(dirname "$0")" || exit 1

if [[ -z $(git status --porcelain) ]]; then
  echo "Tidak ada perubahan baru untuk di-commit."
  exit 0
fi

echo "Perubahan terdeteksi. Melakukan commit dan push..."

# Stage modifications/deletions to already-tracked files only.
git add -u

if [[ -z $(git diff --cached --name-only) ]]; then
  echo "Tidak ada perubahan pada file yang sudah dilacak."
  echo "File baru (untracked) berikut TIDAK ikut di-commit — tambahkan manual bila perlu:"
  git status --porcelain | grep '^??' || true
  exit 0
fi

echo "File yang akan di-commit:"
git diff --cached --name-only

git commit -m "Auto commit: $(date +'%Y-%m-%d %H:%M:%S')" || exit 1

# No --force. A rejected push means someone else pushed first — merge by hand.
if git push origin main; then
  echo "Berhasil di-push ke origin/main!"
else
  echo "PUSH DITOLAK — kemungkinan origin/main sudah bergerak lebih dulu."
  echo "Jalankan 'git pull --rebase origin main', selesaikan konflik, lalu push lagi."
  exit 1
fi
