#!/bin/bash

echo "Memulai mode pemantauan otomatis (Auto-sync) setiap 60 detik..."
echo "Tekan Ctrl+C untuk menghentikan."

while true; do
  ./auto_push.sh
  sleep 60
done
