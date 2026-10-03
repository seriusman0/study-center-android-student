<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download Aplikasi Android - Study Center Nias</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; max-width: 760px; margin: 0 auto; padding: 24px 20px 60px; color: #1f2937; background: #f8fafc; }
        .card { background: #fff; border-radius: 16px; padding: 28px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
        .brand { display: flex; align-items: center; gap: 14px; margin-bottom: 8px; }
        .brand-logo { width: 72px; height: 72px; object-fit: contain; border-radius: 14px; background: #fff; padding: 4px; box-shadow: 0 1px 4px rgba(0,0,0,0.10); }
        h1 { color: #0F766E; font-size: 1.5rem; margin: 0 0 4px; }
        .subtitle { color: #64748b; margin: 0; }
        .version-badge { display: inline-block; background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 3px 12px; border-radius: 999px; font-size: 0.85rem; font-weight: 600; margin: 16px 0; }
        .download-btn { display: inline-flex; align-items: center; gap: 10px; background: #0F766E; color: #fff; text-decoration: none; padding: 14px 28px; border-radius: 12px; font-weight: 700; font-size: 1.05rem; margin: 8px 0 20px; }
        .download-btn:hover { background: #0d6a63; }
        .meta { color: #64748b; font-size: 0.9rem; margin-bottom: 24px; }
        h2 { color: #0F766E; font-size: 1.1rem; margin-top: 28px; }
        ol, ul { padding-left: 22px; }
        li { margin-bottom: 8px; }
        .warn { background: #fffbeb; border: 1px solid #fde68a; border-radius: 10px; padding: 14px 16px; color: #92400e; font-size: 0.92rem; margin: 16px 0; }
        .note { background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 10px; padding: 14px 16px; color: #1e40af; font-size: 0.92rem; margin: 16px 0; }
        code { background: #f1f5f9; padding: 2px 6px; border-radius: 4px; font-size: 0.85em; }
        footer { text-align: center; color: #94a3b8; font-size: 0.85rem; margin-top: 32px; }
        a.link { color: #0F766E; }
    </style>
</head>
<body>
    <div class="card">
        <div class="brand">
            <img src="/assets/img/logo.png" alt="Study Center Nias" class="brand-logo">
            <div>
                <h1>Study Center Nias — Aplikasi Android</h1>
                <p class="subtitle">Aplikasi resmi untuk anggota Study Center Nias</p>
            </div>
        </div>

        <span class="version-badge">Versi {{ $version }}</span>

        <div>
            <a class="download-btn" href="/download/apk" download>
                ⬇ Download APK ({{ $size }} MB)
            </a>
        </div>
        <p class="meta">Terakhir diperbarui: {{ $date }} &middot; Android 7.0 (Nougat) ke atas</p>

        <div class="note">
            <strong>Belum tersedia di Google Play Store.</strong> Untuk saat ini, instal
            aplikasi langsung dari file APK di halaman ini (di luar Play Store / "sideload").
            Ini aman selama Anda mengunduh dari domain resmi
            <code>studycenter.nanoprojectdevindonesia.com</code> ini.
        </div>

        @if(!empty($releaseNotes))
        <div class="release-notes" style="background: #f8fafc; border: 1px solid #e2e8f0; padding: 16px 20px; border-radius: 12px; margin-bottom: 24px;">
            {!! $releaseNotes !!}
        </div>
        <style>
            .release-notes h1 { font-size: 1.25rem; margin-top: 0; color: #1e293b; }
            .release-notes h2 { font-size: 1.1rem; margin-top: 16px; color: #334155; }
            .release-notes p { margin: 8px 0; }
            .release-notes ul { margin: 8px 0; padding-left: 20px; }
            .release-notes li { margin-bottom: 4px; }
        </style>
        @endif

        <h2>Cara Instalasi</h2>
        <ol>
            <li>Ketuk tombol <strong>Download APK</strong> di atas menggunakan browser HP Anda (Chrome, dsb).</li>
            <li>Setelah unduhan selesai, buka file <code>{{ $filename }}</code> dari notifikasi
                unduhan atau folder <em>Downloads</em>.</li>
            <li>Android akan menampilkan peringatan "sumber tidak dikenal" — ini normal untuk aplikasi
                di luar Play Store. Ketuk <strong>Setelan</strong>, lalu aktifkan
                <strong>"Izinkan dari sumber ini"</strong> khusus untuk browser yang Anda pakai.</li>
            <li>Kembali dan ketuk <strong>Instal</strong>.</li>
            <li>Buka aplikasi, lalu login menggunakan akun Study Center Nias Anda.</li>
        </ol>

        <div class="warn">
            <strong>Catatan keamanan:</strong> Hanya unduh aplikasi ini dari domain resmi
            <code>studycenter.nanoprojectdevindonesia.com</code>. Jangan instal file APK
            "Study Center Nias" yang dikirim dari sumber tidak dikenal (WhatsApp grup asing,
            dsb) tanpa memverifikasi terlebih dahulu ke pengelola cabang Anda.
        </div>

        <h2>Pertanyaan?</h2>
        <p>Jika mengalami kendala saat instalasi atau penggunaan aplikasi, hubungi pengelola
        cabang Study Center Nias Anda. Kebijakan privasi aplikasi dapat dilihat di
        <a class="link" href="/privacy-policy">halaman Kebijakan Privasi</a>.</p>
    </div>
    <footer>&copy; 2026 Study Center Nias</footer>
</body>
</html>
