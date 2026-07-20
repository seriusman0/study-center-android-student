
# Product Requirements Document (PRD): SC Student App

## 1. Ikhtisar Produk

**SC Student** adalah aplikasi mobile berbasis Flutter yang berfungsi sebagai *frontend* untuk platform LMS/Manajemen Akademik yang sudah ada. Aplikasi ini dirancang khusus untuk mahasiswa, mengutamakan kemudahan akses, performa cepat, dan desain minimalis.

* **Platform:** Android
* **Arsitektur:** *Native Frontend* (Flutter) terhubung langsung ke API Backend yang ada.
* **Konektivitas:** Internal via Tailscale (`100.67.79.94`).
Backend aplikasi secara resmi di deploy di studycenter.overcomer.my.id, tetapi selama masa development, backendnya mengunakan  /var/www/study-center-nias. Untuk keperluan logo dan asset-asset lain bisa ambil di backend, silakan cari di public/asset/

## 2. Target Pengguna

* **Student:** Pengguna tunggal yang dapat mengakses fitur akademik.
* **Otoritas:** Hanya user dengan role `Student` yang diizinkan mengakses aplikasi.

## 3. Fitur Utama & Navigasi

Aplikasi menggunakan *Bottom Navigation Bar* untuk akses cepat ke empat modul utama:

1. **Beranda:** *Dashboard* ringkas yang menampilkan informasi penting (pengumuman, jadwal hari ini, atau ringkasan status akademik).
2. **Jurnal:** Halaman untuk mencatat atau melihat log aktivitas/jurnal harian mahasiswa.
3. **Laporan:** Halaman untuk melihat akumulasi data akademik, nilai, atau laporan progres.
4. **Profile:** Halaman informasi data diri mahasiswa dan opsi *Logout*.

## 4. Persyaratan Teknis

### A. Autentikasi & Keamanan

* **Login Gateway:** Integrasi API Login.
* **Role Validation:** Aplikasi wajib melakukan validasi terhadap *response* API. Jika `role != 'Student'`, sistem wajib menolak akses dan menampilkan pesan *error* ("Akses ditolak: Anda bukan mahasiswa").
* **Session Management:** Menggunakan *secure storage* untuk menyimpan token sesi (JWT atau *session id*).

### B. Infrastruktur & Koneksi

* **Endpoint:** Aplikasi akan memanggil API melalui IP Tailscale: `100.67.79.94`.
* **Networking:** Menggunakan *package* `dio` atau `http` dengan *base URL* yang dikonfigurasi statis ke alamat IP tersebut.
* **Konektivitas:** Aplikasi hanya akan berfungsi jika perangkat terhubung ke *node* Tailscale yang sama.

### C. Desain & UX

* **Tema:** **Minimalism**. Gunakan *white space* yang luas, tipografi yang bersih, dan navigasi yang intuitif.
* **Warna:** Palet warna harus diturunkan dari *branding* logo yang sudah Anda sediakan.
* *Primary Color:* (Ambil dari warna dominan logo).
* *Accent Color:* (Ambil dari warna sekunder logo).


* **Komponen UI:** Menggunakan *Material Design* standar Flutter dengan modifikasi *custom* untuk mempertahankan gaya minimalis.

---

## 5. Roadmap Pengembangan (Tahap Siap Build)

| Fase | Deskripsi Tugas | Output |
| --- | --- | --- |
| **Fase 1: Setup** | Inisialisasi proyek Flutter, konfigurasi `pubspec.yaml`, dan *asset* logo. | *Scaffold* aplikasi. |
| **Fase 2: Auth** | Integrasi API Login & validasi *role* `Student`. | Sistem Login berfungsi. |
| **Fase 3: Shell UI** | Implementasi *Bottom Navigation Bar* dan 4 halaman utama. | *Frame* aplikasi. |
| **Fase 4: Integration** | Menghubungkan *endpoint* API (IP `100.67.79.94`) ke setiap modul. | Data dari Web muncul. |
| **Fase 5: Polish** | *Styling* tema minimalis & testing koneksi via Tailscale. | APK Siap Build. |

---

## 6. Checklist Kesiapan (Ready for Build)

* [ ] API Endpoints (Login, User Profile, Journal, Report) sudah tersedia dan dapat diakses dari IP `100.67.79.94`.
* [ ] Logo aplikasi sudah dalam format vector atau resolusi tinggi untuk *assets* Android.
* [ ] *Role check* di sisi *client* sudah diuji untuk menolak non-student.
* [ ] Tailscale sudah terinstal dan aktif di perangkat pengujian (Android).


---

