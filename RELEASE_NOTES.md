# Release Notes (v3.2.0)

## UI & UX Enhancements
- **Redesain Halaman Jurnal:** Merombak total tampilan antarmuka form pengisian jurnal harian untuk profil Student dan Scholarship Teenager (Remaja Beasiswa).
- **Komponen UI Baru:** Mengimplementasikan kartu-kartu yang lebih modern dengan batas kotak yang jelas untuk setiap item centang/ceklis, menyingkirkan garis-garis pembatas (*divider*) biasa agar interaksi lebih intuitif.
- **Pembaruan Header:** Mengganti *progress bar* hijau lama dengan desain kartu header putih yang bersih dan menyertakan nama pengguna, tanggal saat ini, ikon navigasi tanggal, dan ikon ilustrasi akademis (topi toga).
- **Tombol Konfirmasi:** Menambahkan bagian akhir form yang sangat mencolok ("Submit Jurnal Hari Ini") dengan indikator sukses dan tombol yang besar agar tidak ada lagi mahasiswa yang lupa mengirimkan data jurnalnya.
- **Penyesuaian Skema Warna:** Mengaplikasikan warna dari *semantic design token* (seperti `AppColors.borderStrong`, `AppColors.primary`) guna menjaga konsistensi kontras sesuai *HIG (Human Interface Guidelines)* untuk aksesibilitas dan kemudahan sentuh (*touch target*).

## Perbaikan Stabilitas (Stable Version)
- Semua rute (navigasi), penyajian data Riverpod, dan fungsi pemanggilan API ke *backend* divalidasi tidak mengalami regresi. 
- Diuji secara menyeluruh (*end-to-end automation test* via Maestro) untuk alur *login* dan akses *form* jurnal pada profil `testuser` maupun `teststudent`.
