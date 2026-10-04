# Panduan Update Aplikasi Android (Jurnal API)

Dokumen ini berisi panduan bagi pengembang aplikasi Android (APK) untuk mengimplementasikan perubahan terbaru pada sistem Jurnal Harian. Perubahan ini menyesuaikan agar setiap peran (Student, Scholarship Teenager, dsb.) mendapatkan item checklist jurnal yang sesuai dengan porsinya.

## Perubahan Utama pada Backend (API)

1. **Kategori Dinamis (Tidak lagi di-hardcode ke 'kerohanian')**
   Sebelumnya, API `/api/jurnal/today` memetakan *(mapping)* kategori `pembacaan`, `sidang`, dan `rohani` menjadi `kerohanian`. 
   Saat ini, pemetaan paksa tersebut telah **dihapus**. API sekarang akan mengembalikan `kategori` asli secara langsung dari database (contoh: `pembacaan`, `sidang`, `rohani`, `pendidikan`, `karakter`, `kerohanian`, `prajurit`).

2. **Perubahan Item Checklist**
   - **Student**: Mendapatkan tambahan poin "Belajar Pribadi di Rumah" di kategori `pendidikan`. Label untuk kehadiran sidang juga telah diperbarui menjadi lebih detail.
   - **Scholarship Teenager**: Kini juga mendapatkan item dari kategori `kerohanian` (yaitu "Mengawali Hari Dengan Berdoa"), selain kategori mereka yang biasa (`pembacaan`, `sidang`, `rohani`).
   - Beberapa redundansi item "Baca Alkitab" dan "Hafal Ayat" (sebagai check list) telah dinonaktifkan karena UI Android sudah menanganinya secara native *(hardcoded sections 1 & 2)*.

## Langkah Implementasi di Aplikasi Android

Pada file antarmuka utama (misalnya `JurnalScreen.kt`), bagian **Jadwal Kehidupan (Section 3)** yang melakukan render list *kategori* perlu disesuaikan agar mendukung semua jenis kategori secara dinamis.

### 1. Update List Kategori (kategoriList)
Ubah daftar kategori yang di-hardcode sebelumnya (hanya 3 kategori) menjadi daftar lengkap.

**Sebelumnya:**
```kotlin
val kategoriList = listOf(
    "kerohanian" to "Kerohanian", 
    "pendidikan" to "Pendidikan", 
    "karakter" to "Karakter"
)
```

**Ubah menjadi:**
```kotlin
val allKategoriList = listOf(
    "kerohanian" to "Kerohanian",
    "pendidikan" to "Pendidikan",
    "karakter" to "Karakter",
    "pembacaan" to "Pembacaan",
    "sidang" to "Sidang-Sidang Gereja",
    "rohani" to "Kegiatan Rohani dan Pelayanan",
    "prajurit" to "Karakter Prajurit"
)
```

### 2. Update Logika Render List
Pastikan Anda hanya me-render kategori yang **memiliki item** yang dikembalikan oleh JSON, agar kategori yang kosong tidak muncul.

```kotlin
val grouped = s.lifeItems?.groupBy { it.kategori.lowercase() } ?: emptyMap()

PhoneSection(number = "3", title = "Jadwal Kehidupan") {
    // Hanya filter kategori yang datanya benar-benar ada di `grouped`
    allKategoriList.filter { grouped.containsKey(it.first) }.forEach { (key, label) ->
        SubHead(label)
        val items = grouped[key]!!
        items.forEach { item ->
            PhoneCheckRow(
                title = item.label,
                checked = item.checked,
                saving = saving["life:${item.id}"] == true,
                compact = true,
            ) { optimisticCheck("life", item.id, it) }
        }
    }
}
```

## Uji Coba Endpoint (cURL)

Anda dapat melakukan testing ke endpoint yang telah disediakan menggunakan perintah `curl` dengan menyertakan Bearer token pengguna. Contoh pengujian (`GET /api/jurnal/today`):

```bash
curl -X GET "https://[DOMAIN-API-ANDA]/api/jurnal/today" \
     -H "Authorization: Bearer [TOKEN_PENGGUNA]" \
     -H "Accept: application/json"
```

**Hasil Ekspektasi `life_items`:**
JSON array akan memuat atribut `kategori` dengan *string* asli (seperti `pendidikan`, `sidang`, dll.).

```json
{
    "date": "2026-10-04",
    "...": "...",
    "life_items": [
        {
            "id": 1,
            "kategori": "kerohanian",
            "label": "Mengawali hari dengan berdoa",
            "response_type": "check",
            "checked": false
        },
        {
            "id": 4,
            "kategori": "pendidikan",
            "label": "Hadir di kelas SC",
            "response_type": "check",
            "checked": false
        },
        {
            "id": 20,
            "kategori": "sidang",
            "label": "Sharing di SPR",
            "response_type": "check",
            "checked": false
        }
    ]
}
``` 
*(Catatan: Endpoint telah berhasil lolos uji coba simulasi request dengan response JSON 200 OK).*
