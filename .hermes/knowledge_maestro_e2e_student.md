# Pengetahuan Hermes: Maestro E2E Audit (Jurnal Student)

Dokumen ini berisi rangkuman pembelajaran, best practices, dan penyelesaian error (troubleshooting) saat melakukan audit E2E menggunakan **Maestro** pada fitur Jurnal Student di aplikasi Flutter Study Center. Pengetahuan ini sangat berguna untuk referensi tugas-tugas E2E testing dan perbaikan bug Flutter di masa mendatang.

## 1. Konteks Pengujian
- **Target Uji**: Fitur Login, Navigasi (Bottom Nav Bar & Top Tabs), Jurnal Student (Kerohanian, Life Items), Laporan, Profil, dan Logout.
- **Kondisi Khusus (`testuser`)**: Akun ini memiliki peran ganda (Student dan Scholarship). Karena peran ganda tersebut, aplikasi memunculkan **TabBar** dinamis (contoh: "Jurnal Beasiswa" dan "Jurnal Student") yang mungkin tidak ada pada akun reguler. Hal ini dapat mengubah flow UI standar.

## 2. Best Practices Maestro pada Aplikasi Flutter
Flutter memiliki cara yang unik dalam membangun *Accessibility Tree* (Semantics), yang dapat menyulitkan Maestro saat melakukan *text-matching* (pencarian teks):
- **Grouping Teks di Semantics**: Flutter sering menggabungkan beberapa teks di dalam sebuah `Card` atau `Tab` menjadi satu *content-description* multiline (contoh: `Jurnal\nTab 2 of 4`). Akibatnya, instruksi seperti `- tapOn: "Jurnal"` bisa gagal karena Maestro menganggapnya tidak *exact match*, atau karena substring matching gagal akibat newline/struktur nesting.
- **Solusi Tapping Navigasi**: Alih-alih melakukan *text-matching* untuk bottom navigation atau tab bar yang rentan gagal, gunakan **koordinat exact (point)**. 
  Contoh:
  ```yaml
  # Jurnal (Tengah Bawah)
  - tapOn:
      point: "270,1433"
  # Jurnal Student (Tab Kanan Atas)
  - tapOn:
      point: "540,90"
  ```
  *(Catatan: Pastikan dump UI / `adb shell uiautomator dump` untuk melihat struktur `bounds` secara pasti).*

- **Solusi Assertion (Mencari Elemen)**: Hindari mencocokkan teks yang panjang atau berada dalam `ScrollView` yang bisa terpotong. 
  - Gunakan `- assertVisible` pada elemen spesifik yang mandiri dan tidak panjang.
  - Untuk teks panjang seperti dalam dialog (`Anda akan keluar dari akun ini. Lanjutkan?`), hindari mencocokkan teks tersebut secara utuh. Cari tombol statis dan tunggal seperti `"Batal"` atau `"Keluar"`.
  - Hati-hati dengan elemen yang letaknya di bawah layar (*below the fold*). `extendedWaitUntil: visible` di Maestro **tidak akan otomatis men-scroll**. Pastikan mencari elemen yang selalu berada di atas (contoh: `"QR Absensi"` atau `"Mulai Isi Jurnal Remaja SC"`).

## 3. Resolusi Error Flutter: `Null check operator used on a null value` (RenderViewportBase.visitChildrenForSemantics)
Saat E2E test membuka halaman "Jurnal Student", aplikasi *crash* (Red Screen of Death). 
- **Gejala / Error Trace**: 
  ```text
  Null check operator used on a null value
  Context: during a scheduler callback
  #0 RenderViewportBase.visitChildrenForSemantics
  ```
- **Penyebab Utama**: Ini adalah *bug bawaan framework Flutter* (khususnya versi 3.x) yang terjadi saat layouting *Accessibility/Semantics Tree*. Error ini ter-trigger ketika sebuah `TextField` secara eksplisit dibungkus lagi dengan `Semantics(textField: true)`. Karena `TextField` secara internal sudah menyediakan semantics `textField: true`, *duplicate property* ini mengacaukan kalkulasi sibling rendering pada `ScrollView` (termasuk ketika `DropdownButtonFormField` berada di sekitarnya).
- **Cara Mengatasi**: Hapus atribut `textField: true` dari pembungkus `Semantics`. Cukup gunakan atribut `identifier`, atau hapus pembungkus `Semantics` sepenuhnya jika tidak dibutuhkan oleh automation.
  ```dart
  // SEBELUMNYA (MEMICU CRASH)
  Semantics(
    identifier: 'pasalInput',
    textField: true, // INI PENYEBABNYA!
    child: TextField(...),
  )

  // SESUDAH (FIXED)
  Semantics(
    identifier: 'pasalInput',
    child: TextField(...),
  )
  ```

## 4. Langkah Troubleshooting Tambahan
Jika E2E stuck, selalu lakukan:
1. Pastikan Maestro tidak nyangkut oleh prompt Telemetry Windows: Jalankan `$env:MAESTRO_TELEMETRY_OPT_OUT="true"` sebelum mengeksekusi `maestro test`.
2. Jika Maestro tidak mendeteksi error dengan spesifik, dump UI dari perangkat: `adb shell uiautomator dump /sdcard/window_dump.xml` lalu `adb pull` dan inspeksi file `.xml` tersebut.
3. Perhatikan bila *Maestro Driver Server* di perangkat Android crash mendadak (`Device server died`). Jalankan ulang instruksi *test*, Maestro akan mencoba me-reinstall servernya secara otomatis.
