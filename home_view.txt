@extends('layouts.app')

@section('title', 'Study Center Nias')

@section('content')
{{-- Hero --}}
<section class="bg-gradient-to-br from-sc-teal-700 to-sc-teal-600 text-white py-20 px-4 relative overflow-hidden">
    <svg viewBox="0 0 200 200" class="absolute -right-10 -top-10 w-72 opacity-10 pointer-events-none" aria-hidden="true">
        <path d="M60,110 L100,20 L140,110 Z" fill="#e0c020" />
        <rect x="50" y="120" width="100" height="20" fill="#e0c020" />
        <rect x="50" y="144" width="100" height="20" fill="#f19121" />
    </svg>
    <div class="max-w-4xl mx-auto text-center relative">
        <p class="text-white font-extrabold tracking-[0.2em] text-sm mb-3 drop-shadow-md">KOMUNITAS BELAJAR NIAS</p>
        <h1 class="font-display text-4xl md:text-6xl mb-4 leading-tight">
            Study Center <span class="text-sc-yellow-300">Nias</span>
        </h1>
        <p class="text-white/85 text-lg mb-8 max-w-2xl mx-auto leading-relaxed">
            Rumah kedua remaja Nias. Tempat belajar, bertumbuh.
        </p>
        <div class="flex flex-col sm:flex-row gap-3 justify-center items-center flex-wrap">
            <button type="button" onclick="openPublicScanner()" 
               class="px-6 py-3 bg-white text-sc-teal-700 font-semibold rounded-lg hover:bg-gray-100 transition shadow-lg flex items-center gap-2 w-full sm:w-auto justify-center">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                Scan Jurnal
            </button>
            <a href="{{ route('blog.index') }}"
               class="px-6 py-3 bg-sc-orange-500 text-white font-semibold rounded-lg hover:bg-sc-orange-600 transition shadow-sc-2 w-full sm:w-auto text-center">
                Baca Blog
            </a>
            <a href="{{ route('download.android') }}"
               class="px-6 py-3 bg-white/20 border border-white/40 text-white font-semibold rounded-lg hover:bg-white/30 transition shadow-sc-2 w-full sm:w-auto text-center flex items-center justify-center gap-2">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Download App
            </a>
            @guest
            <a href="{{ route('register') }}"
               class="px-6 py-3 border border-white/40 text-white rounded-lg hover:bg-white/10 transition font-medium w-full sm:w-auto text-center">
                Bergabung
            </a>
            @endguest
        </div>
        </div>
        
</section>

{{-- Aplikasi Mobile & Beta Tester --}}
<section class="max-w-6xl mx-auto px-4 py-12">
    @if(session('success'))
    <div class="bg-green-50 border border-green-200 text-green-800 rounded-xl p-4 mb-8 text-center font-medium">
        {{ session('success') }}
    </div>
    @endif
    <div class="rounded-2xl p-8 md:p-12 shadow-sm border border-gray-200" style="background: linear-gradient(to bottom right, #f0f9ff, #e0e7ff);">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-10 items-center">
            <div>
                <span class="inline-block text-xs font-bold px-3 py-1 rounded-full mb-4" style="background-color: #bfdbfe; color: #1e3a8a;">BARU!</span>
                <h2 class="text-3xl font-bold text-gray-900 mb-4">Aplikasi Android SCN</h2>
                <p class="text-gray-700 mb-6 leading-relaxed">
                    Lebih mudah scan jurnal, cek laporan, dan membaca blog langsung dari HP Anda. 
                    Unduh aplikasi versi terbarunya sekarang juga.
                </p>
                <div class="flex flex-col sm:flex-row gap-4 mb-8">
                    <a href="{{ route('download.android') }}" class="inline-flex items-center justify-center gap-2 font-semibold py-3 px-6 rounded-lg transition-colors shadow-md" style="background-color: #2563eb; color: #ffffff;">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                        </svg>
                        Download APK Terkini
                    </a>
                </div>
            </div>
            
            <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-md relative overflow-hidden">
                <div class="absolute top-0 right-0 text-[10px] font-bold px-3 py-1 rounded-bl-lg" style="background-color: #facc15; color: #713f12;">BETA PROGRAM</div>
                <h3 class="text-xl font-bold text-gray-800 mb-2 mt-2">Dapatkan Akses Play Store</h3>
                <p class="text-sm text-gray-600 mb-5">
                    Aplikasi belum rilis publik. Daftarkan diri Anda sebagai <strong>Beta Tester</strong> untuk mendownload langsung dari Google Play Store secara resmi.
                </p>
                
                <form action="{{ route('beta.register') }}" method="POST" class="space-y-4">
                    @csrf
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Alamat Email (Google Akun)</label>
                        <input type="email" name="email" maxlength="100" required placeholder="email.anda@gmail.com" class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500 text-sm">
                        @error('email') <span class="text-red-500 text-xs mt-1 block">{{ $message }}</span> @enderror
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nomor WhatsApp</label>
                        <input type="text" name="whatsapp" maxlength="20" required placeholder="08123456789" class="w-full rounded-lg border-gray-300 focus:border-blue-500 focus:ring-blue-500 text-sm">
                        @error('whatsapp') <span class="text-red-500 text-xs mt-1 block">{{ $message }}</span> @enderror
                    </div>
                    <button type="submit" class="w-full font-semibold py-2.5 px-4 rounded-lg transition-colors text-sm shadow-md hover:opacity-90" style="background-color: #2563eb; color: #ffffff;">
                        Kirim Permintaan Akses
                    </button>
                    <p class="text-xs text-center text-gray-400 mt-3">Link Play Store akan dikirimkan ke WhatsApp Anda setelah disetujui.</p>
                </form>
            </div>
        </div>
    </div>
</section>

{{-- Cabang --}}
<section class="max-w-6xl mx-auto px-4 py-8">
    <p class="sc-eyebrow mb-2">EMPAT CABANG</p>
    <h2 class="text-2xl md:text-3xl font-bold text-sc-ink-900 mb-6">Cabang Kami</h2>
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        @foreach($cabangs as $cabang)
        <a href="{{ route('cabang.show', $cabang->slug) }}"
           class="bg-white border border-sc-line rounded-xl p-5 text-center hover:shadow-sc-3 hover:border-sc-teal-300 transition group">
            <div class="w-10 h-10 mx-auto mb-3 rounded-lg bg-sc-teal-100 text-sc-teal-700 flex items-center justify-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 7-8 13-8 13s-8-6-8-13a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
            </div>
            <p class="font-semibold text-sc-ink-900 group-hover:text-sc-teal-700 transition text-sm">{{ $cabang->nama }}</p>
        </a>
        @endforeach
    </div>
</section>

{{-- Blog Terbaru --}}
<section class="max-w-6xl mx-auto px-4 pb-16">
    <div class="flex items-center justify-between mb-6">
        <div>
            <p class="sc-eyebrow mb-1">CERITA TERBARU</p>
            <h2 class="text-2xl md:text-3xl font-bold text-sc-ink-900">Blog Terbaru</h2>
        </div>
        <a href="{{ route('blog.index') }}" class="text-sc-teal-700 hover:text-sc-teal-800 text-sm font-semibold">
            Lihat semua →
        </a>
    </div>
    @if($blogs->isEmpty())
    <p class="text-center text-sc-ink-500 py-12">Belum ada blog. Jadilah yang pertama menulis!</p>
    @else
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        @foreach($blogs as $blog)
            @include('blog._card', ['blog' => $blog])
        @endforeach
    </div>
    @endif
</section>

{{-- Public Scanner Modal --}}
<div id="publicScannerModal" class="fixed inset-0 z-50 hidden bg-black/60 backdrop-blur-sm overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
    <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0">
        <div class="relative bg-white rounded-2xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:max-w-3xl w-full border border-sc-line">
            <div class="bg-sc-teal-600 px-4 py-4 flex justify-between items-center text-white">
                <h3 class="text-xl font-bold flex items-center gap-2">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><rect x="7" y="7" width="3" height="3"/><rect x="14" y="7" width="3" height="3"/><rect x="7" y="14" width="3" height="3"/><rect x="14" y="14" width="3" height="3"/></svg>
                    Scanner & Jurnal
                </h3>
                <button type="button" onclick="closePublicScanner()" class="text-white hover:text-gray-200 focus:outline-none">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>
            
                        <div class="p-4 sm:p-6">
                                <div id="scannerCameraSection" class="flex flex-col items-center max-w-md mx-auto w-full">
                    <label class="block text-sm font-medium text-sc-ink-900 mb-2 w-full text-center">Pilih Kamera</label>
                    <select id="cameraSelect" class="w-full max-w-xs border-sc-line rounded-lg shadow-sm focus:border-sc-teal-500 py-2 px-3 text-sm mb-4 bg-white text-center"></select>
                    
                    <div id="qr-reader" class="w-full rounded-xl overflow-hidden shadow-sm border-2 border-sc-line bg-black"></div>
                    
                    <div id="scan-status" class="mt-4 text-center font-mono text-sm px-4 py-2 bg-gray-100 rounded-lg text-gray-600 w-full max-w-xs">
                        Arahkan QR Code ke kamera.
                    </div>
                </div>

                </div>
            </div>
            <div class="bg-gray-50 px-4 py-3 sm:px-6 flex justify-end gap-3 rounded-b-2xl border-t border-sc-line">
                <button type="button" onclick="closePublicScanner()" class="px-5 py-2.5 bg-white border border-sc-line rounded-lg text-sc-ink-900 hover:bg-gray-50 font-medium transition shadow-sm">
                    Tutup
                </button>
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
<script>

let html5Qrcode = null;
let scanning    = false;
let currentUser = null;
let currentItems = [];
let currentDate = null;

const PUBLIC_SCAN_URL  = "/public-jurnal/scan";
const PUBLIC_SAVE_URL  = "/public-jurnal/save";
const CSRF             = "{{ csrf_token() }}";

function openPublicScanner() {
    try {
        document.getElementById('publicScannerModal').classList.remove('hidden');
        document.getElementById('scan-status').innerHTML = '<span class="text-blue-500">Meminta akses kamera...</span>';
        
        Html5Qrcode.getCameras().then(devices => {
            let select = document.getElementById('cameraSelect');
            select.innerHTML = '';
            if (devices && devices.length > 0) {
                let backCam = devices.find(c => c.label.toLowerCase().includes('back') || c.label.toLowerCase().includes('belakang'));
                let defaultId = backCam ? backCam.id : devices[0].id;
                
                devices.forEach(cam => {
                    let opt = document.createElement('option');
                    opt.value = cam.id;
                    opt.text = cam.label || 'Kamera ' + cam.id;
                    select.appendChild(opt);
                });
                
                select.value = defaultId;

                setTimeout(() => {
                    if (document.getElementById('publicScannerModal').classList.contains('hidden')) return;
                    startScanner(defaultId);
                }, 400); 
            } else {
                select.innerHTML = '<option value="environment">Kamera Belakang</option><option value="user">Kamera Depan</option>';
                setTimeout(() => {
                    if (document.getElementById('publicScannerModal').classList.contains('hidden')) return;
                    startScanner({ facingMode: "environment" });
                }, 400); 
            }
        }).catch(err => {
            document.getElementById('scan-status').innerHTML = '<span class="text-red-500">Izin kamera ditolak/gagal. Pastikan browser mengizinkan akses kamera. (' + err + ')</span>';
        });
    } catch(e) {
        document.getElementById('scan-status').innerHTML = '<span class="text-red-500">Error sistem: ' + e.message + '</span>';
    }
}

document.getElementById('cameraSelect').addEventListener('change', function() {
    let val = this.value;
    if (val === 'environment' || val === 'user') {
        startScanner({ facingMode: val });
    } else {
        startScanner(val);
    }
});

function initScanner(cameraIdOrConfig, isFallback = false) {
    html5Qrcode = new Html5Qrcode("qr-reader");
    html5Qrcode.start(
        cameraIdOrConfig,
        {
            fps: 10,
            qrbox: function(viewfinderWidth, viewfinderHeight) {
                let minEdgePercentage = 0.7;
                let minEdgeSize = Math.min(viewfinderWidth, viewfinderHeight);
                let qrboxSize = Math.floor(minEdgeSize * minEdgePercentage);
                return { width: qrboxSize, height: qrboxSize };
            }
        },
        onScanSuccess,
        (errorMessage) => { /* ignore */ }
    ).then(() => {
        let msg = document.getElementById('scan-status');
        if(msg) msg.innerHTML = 'Arahkan QR Code ke kamera.';
    }).catch(err => {
        if (!isFallback && err.toString().includes('OverconstrainedError')) {
            if (html5Qrcode) { try { html5Qrcode.clear(); } catch(e){} }
            let select = document.getElementById('cameraSelect');
            if (select) select.value = 'user';
            initScanner({ facingMode: "user" }, true);
        } else {
            let msg = document.getElementById('scan-status');
            if(msg) msg.innerHTML = '<span class="text-danger text-red-500">Gagal memulai kamera: ' + err + '</span>';
        }
    });
}

function startScanner(cameraIdOrConfig) {
    try {
        if (html5Qrcode) {
            let state = 0;
            try { state = html5Qrcode.getState(); } catch(e) {}
            if (state === 2) {
                html5Qrcode.stop().then(() => {
                    try { html5Qrcode.clear(); } catch(e) {}
                    initScanner(cameraIdOrConfig);
                }).catch(() => {
                    initScanner(cameraIdOrConfig);
                });
            } else {
                try { html5Qrcode.clear(); } catch(e) {}
                initScanner(cameraIdOrConfig);
            }
        } else {
            initScanner(cameraIdOrConfig);
        }
    } catch(e) {
        initScanner(cameraIdOrConfig);
    }
}

function closePublicScanner() {
    document.getElementById('publicScannerModal').classList.add('hidden');
    if (html5Qrcode) {
        try {
            html5Qrcode.stop().then(() => {
                try { html5Qrcode.clear(); } catch(e) {}
                html5Qrcode = null;
            }).catch(() => { html5Qrcode = null; });
        } catch(e) {}
    }
    
}

function onScanSuccess(decodedText) {
    if (scanning) return;
    scanning = true;

    const userId = parseInt(decodedText.trim(), 10);
    if (isNaN(userId)) {
        playSound('error');
        document.getElementById('scan-status').innerHTML = '<span class="text-red-500">QR tidak valid</span>';
        setTimeout(() => { scanning = false; }, 2000);
        return;
    }

    document.getElementById('scan-status').innerHTML = '<span class="text-blue-500">Memuat data...</span>';

    fetch(PUBLIC_SCAN_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': CSRF, 'Accept': 'application/json' },
        body: JSON.stringify({ user_id: userId })
    })
    .then(r => r.json())
    .then(data => {
        if (data.status === 'not_found') {
            playSound('error');
            document.getElementById('scan-status').innerHTML = '<span class="text-red-500">' + (data.message || 'Pengguna tidak ditemukan/tidak aktif.') + '</span>';
            setTimeout(() => { scanning = false; }, 2500);
            return;
        }
        if (data.status === 'redirect') {
            playSound('success');
            document.getElementById('scan-status').innerHTML = '<span class="text-green-600 font-bold">Berhasil! Mengalihkan...</span>';
            
            try {
                if (html5Qrcode) {
                    html5Qrcode.stop().then(() => {
                        window.location.replace(data.url);
                    }).catch(() => {
                        window.location.replace(data.url);
                    });
                } else {
                    window.location.replace(data.url);
                }
            } catch (e) {
                window.location.replace(data.url);
            }
            return;
        }
        


        playSound('error');
        document.getElementById('scan-status').innerHTML = '<span class="text-red-500">Gagal mengalihkan.</span>';
        setTimeout(() => { scanning = false; }, 2000);
    })
    .catch(() => {
        playSound('error');
        document.getElementById('scan-status').innerHTML = '<span class="text-red-500">Koneksi gagal.</span>';
        setTimeout(() => { scanning = false; }, 2000);
    });
}



function playSound(type) {
    // optional audio
}

function escHtml(str) {
    if (!str) return '';
    return String(str).replace(/[&<>'"]/g, match => {
        return {
            '&': '&amp;', '<': '&lt;', '>': '&gt;',
            "'": '&#39;', '"': '&quot;'
        }[match];
    });
}

</script>
<style>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #c1c1c1; border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #a8a8a8; }
</style>
@endpush
@endsection
