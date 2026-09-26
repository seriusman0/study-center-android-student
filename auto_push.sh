#!/bin/bash
cd "$(dirname "$0")" || exit

# Periksa apakah ada perubahan
if [[ -n $(git status -s) ]]; then
  echo "Perubahan terdeteksi. Melakukan commit dan push..."
  
  # Tambahkan semua file yang berubah
  git add .
  
  # Lakukan commit dengan pesan otomatis berdasarkan waktu
  git commit -m "Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"
  
  # Push ke Github
  git push -u origin main --force
  
  echo "Berhasil di-push ke Github!"
else
  echo "Tidak ada perubahan baru untuk di-commit."
fi
