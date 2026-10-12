# 🎵 YouTube Audio Downloader

Aplikasi desktop untuk mengunduh audio dari YouTube dan mengkonversinya ke MP3 dengan kualitas tinggi.

## ✨ Fitur

- 🔗 **Multi-Format URL** — Mendukung URL standar, pendek (youtu.be), dan playlist YouTube
- 📊 **Progress Real-time** — Menampilkan persentase, kecepatan unduh, dan estimasi waktu
- 🎨 **UI Modern** — Tampilan dark mode yang bersih menggunakan PyQt5
- 🔄 **Multi-Format Audio** — MP3, AAC, OPUS, M4A, FLAC
- ⚡ **Thread-safe** — Download berjalan di background, UI tetap responsif
- 🛡️ **Error Handling** — Pesan error yang informatif dan mudah dipahami
- 📂 **Custom Output** — Pilih folder penyimpanan sesuai kebutuhan

## 📋 Persyaratan Sistem

- Python 3.8 atau lebih baru
- FFmpeg (untuk konversi audio)
- Koneksi internet

## 🚀 Instalasi

### 1. Clone repository
```bash
git clone <url-repo>
cd yt-audio-downloader
```

### 2. Install dependensi Python
```bash
pip install -r requirements.txt
```

### 3. Install FFmpeg

**Ubuntu/Debian:**
```bash
sudo apt update && sudo apt install ffmpeg
```

**macOS (Homebrew):**
```bash
brew install ffmpeg
```

**Windows:**
Download dari [ffmpeg.org](https://ffmpeg.org/download.html) dan tambahkan ke PATH sistem.

## ▶️ Cara Menjalankan

```bash
python main.py
```

## 📖 Panduan Penggunaan

1. **Paste URL** — Salin URL YouTube dan paste ke kolom input (atau klik tombol 📋 Paste)
2. **Pilih Folder** — Klik 📁 Browse untuk memilih folder penyimpanan
3. **Pilih Format** — Pilih format audio dari dropdown (default: MP3)
4. **Download** — Klik tombol ⬇️ Download MP3
5. **Buka Folder** — Setelah selesai, klik 📂 Buka Folder untuk melihat file hasil

## 🗂️ Struktur Project

```
yt-audio-downloader/
├── main.py              # Entry point aplikasi
├── requirements.txt     # Dependensi Python
├── README.md            # Dokumentasi ini
├── src/
│   ├── downloader.py    # Logic download (yt-dlp)
│   └── utils.py         # Fungsi utilitas
├── ui/
│   ├── main_window.py   # UI PyQt5
│   └── styles.qss       # Dark theme stylesheet
└── downloads/           # Folder output default
```

## ⚠️ Troubleshooting

| Problem | Solusi |
|---------|--------|
| `FFmpeg tidak ditemukan` | Install FFmpeg sesuai panduan di atas |
| `URL tidak valid` | Pastikan URL dari YouTube (youtube.com atau youtu.be) |
| `Video tidak tersedia` | Video mungkin dihapus, privat, atau dibatasi wilayah |
| `Gagal terhubung` | Periksa koneksi internet Anda |
| `ModuleNotFoundError` | Jalankan `pip install -r requirements.txt` |

## 📦 Teknologi

| Komponen | Library | Versi |
|----------|---------|-------|
| UI Framework | PyQt5 | ≥5.15 |
| YouTube Downloader | yt-dlp | ≥2024.1 |
| Audio Converter | FFmpeg | Sistem |
| Bahasa | Python | ≥3.8 |

## 📄 Lisensi

MIT License — Bebas digunakan dan dimodifikasi.
