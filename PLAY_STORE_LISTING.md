# Play Store Listing — Study Center Nias Student

Metadata siap-pakai untuk Google Play Console. Isi manual di form
**Store presence > Main store listing** saat submit.

## App details

**App name** (30 char max):
```
Study Center Nias
```

**Short description** (80 char max):
```
Jurnal harian, laporan progres, dan komunitas belajar Study Center Nias
```

**Full description** (4000 char max):
```
Study Center Nias adalah aplikasi resmi untuk siswa binaan program Study
Center Nias — mendukung kegiatan akademik dan kerohanian sehari-hari.

FITUR UTAMA

📖 Jurnal Harian
Catat progres baca Alkitab (Perjanjian Lama & Perjanjian Baru), hafalan
ayat, dan aktivitas kerohanian/karakter harian Anda. Unggah foto bukti
belajar langsung dari galeri.

📊 Laporan & Progres
Pantau streak harian, ringkasan aktivitas, dan matriks progres belajar
Anda dari waktu ke waktu.

📷 QR Absensi
Tunjukkan QR code pribadi Anda untuk absensi kegiatan di cabang.

📰 Blog & Komunitas
Baca artikel terbaru dari komunitas Study Center Nias, tulis artikel Anda
sendiri, dan berdiskusi lewat komentar.

🖼️ Galeri Kegiatan
Lihat dokumentasi kegiatan cabang Anda.

👤 Profil
Kelola data profil dan lihat informasi cabang Anda.

Aplikasi ini eksklusif untuk siswa terdaftar di cabang Study Center Nias.
Untuk mendaftar sebagai siswa baru, kunjungi cabang Study Center Nias
terdekat atau website resmi kami.
```

**App category:** Education (Pendidikan)

**Tags/keywords (opsional):** study center, nias, jurnal, alkitab,
pendidikan kristen, siswa binaan

## Contact details

- **Website:** https://studycenter.nanoprojectdevindonesia.com
- **Email:** (isi email kontak resmi Study Center Nias)
- **Privacy Policy URL:** https://studycenter.nanoprojectdevindonesia.com/privacy-policy

## Graphic assets needed (belum dibuat — perlu desain terpisah)

Play Console mewajibkan aset berikut, TIDAK bisa di-generate otomatis dari
logo yang ada (perlu desain khusus per ukuran):

| Aset | Ukuran | Status |
|---|---|---|
| App icon (hi-res) | 512×512 PNG, 32-bit dengan alpha | ✅ bisa pakai `assets/branding/icon-flat.png` (crop ke 512×512) |
| Feature graphic | 1024×500 PNG/JPG | ❌ belum dibuat — perlu desain banner promosi |
| Screenshots (phone) | Min. 2, JPG/PNG, rasio 16:9 atau 9:16, sisi terpanjang 320–3840px | ❌ belum diambil — bisa ambil dari `.maestro/tests/*/screenshots/` hasil test terbaru sebagai starting point, tapi idealnya screenshot bersih tanpa status bar test/tanggal test data |
| Screenshots (7" & 10" tablet) | Opsional tapi disarankan | ❌ belum ada, app belum dites di tablet |

## Content rating

Perlu isi kuesioner IARC di Play Console (kategori: Pendidikan, tidak ada
konten kekerasan/dewasa/perjudian → kemungkinan rating "Everyone"/Semua
Umur). Tidak bisa diisi otomatis, perlu dikerjakan langsung oleh pemilik
akun Play Console.

## Data safety section

Isi berdasarkan `PRIVACY_POLICY.md` — ringkasan untuk form Data Safety:

| Data type | Collected? | Shared? | Purpose |
|---|---|---|---|
| Name | Yes | No | Account management |
| Email address | Yes | No | Account management, App functionality |
| User IDs (username) | Yes | No | Account management |
| Photos | Yes (user-uploaded, optional) | No | App functionality (journal evidence) |
| App activity (in-app actions) | Yes | No | App functionality (journal/progress tracking) |

Data **tidak** dienkripsi in-transit? → SALAH, jawab "Yes, data is
encrypted in transit" (HTTPS/TLS). User **bisa** minta hapus data → "Yes".

## Yang masih perlu manual dari pemilik akun Google Play Console

1. Buat/pakai akun Google Play Console (biaya pendaftaran developer $25
   one-time, jika belum ada)
2. Upload `app-release.aab` (bukan `.apk`) sebagai release production/internal
3. Isi kuesioner Content Rating (IARC)
4. Isi Data Safety form (tabel di atas sebagai referensi)
5. Buat Feature Graphic 1024×500 (desain terpisah, bukan otomatis)
6. Ambil screenshot bersih dari app (lihat langkah "Screenshot bersih" di
   bawah)
7. Tunggu review Google (biasanya 1-7 hari untuk app baru)
