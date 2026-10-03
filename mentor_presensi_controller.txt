<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MentorPresensi;
use App\Support\JurnalWeek;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MentorPresensiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = MentorPresensi::with(['kelas:id,nama,cabang_id', 'cabang:id,nama', 'mentor:id,name,username'])
            ->latest('tanggal')->latest('jam_datang');

        if (! $user->isAdmin()) {
            $q->where('mentor_id', $user->id);
        } elseif ($request->filled('mentor_id')) {
            $q->where('mentor_id', $request->mentor_id);
        }
        if ($request->filled('cabang_id')) $q->where('cabang_id', $request->cabang_id);
        if ($request->filled('from'))      $q->whereDate('tanggal', '>=', $request->from);
        if ($request->filled('to'))        $q->whereDate('tanggal', '<=', $request->to);

        $page = $q->paginate(20);
        return response()->json([
            'data' => $page->items(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page'    => $page->lastPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
            ],
        ]);
    }

    public function show(Request $request, MentorPresensi $mentorPresensi): JsonResponse
    {
        $this->authorize($request, $mentorPresensi);
        return response()->json(['data' => $mentorPresensi->load('kelas:id,nama', 'cabang:id,nama')]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_if(! $user->cabang_id, 422, 'Akun Anda belum terkait cabang.');
        $data = $this->validateData($request, $user);

        $rec = MentorPresensi::create([
            'mentor_id'    => $user->id,
            'cabang_id'    => $user->cabang_id,
            'kelas_id'     => $data['kelas_id'],
            'tanggal'      => $data['tanggal'],
            'jam_datang'   => $data['jam_datang'],
            'jam_pulang'   => $data['jam_pulang'],
            'jumlah_murid' => $data['jumlah_murid'],
            'catatan'      => $data['catatan'] ?? null,
        ]);
        return response()->json(['data' => $rec->load('kelas:id,nama')], 201);
    }

    public function update(Request $request, MentorPresensi $mentorPresensi): JsonResponse
    {
        $this->authorize($request, $mentorPresensi);
        abort_if(! $mentorPresensi->canEdit() && ! $request->user()->isAdmin(), 422, 'Presensi >24 jam tidak dapat diedit.');

        $data = $this->validateData($request, $request->user());
        $mentorPresensi->update([
            'kelas_id'     => $data['kelas_id'],
            'tanggal'      => $data['tanggal'],
            'jam_datang'   => $data['jam_datang'],
            'jam_pulang'   => $data['jam_pulang'],
            'jumlah_murid' => $data['jumlah_murid'],
            'catatan'      => $data['catatan'] ?? null,
        ]);
        return response()->json(['data' => $mentorPresensi->fresh()->load('kelas:id,nama')]);
    }

    public function destroy(Request $request, MentorPresensi $mentorPresensi): JsonResponse
    {
        $this->authorize($request, $mentorPresensi);
        abort_if(! $mentorPresensi->canEdit() && ! $request->user()->isAdmin(), 422, 'Presensi >24 jam tidak dapat dihapus.');
        $mentorPresensi->delete();
        return response()->json(['message' => 'deleted']);
    }

    private function authorize(Request $request, MentorPresensi $rec): void
    {
        $user = $request->user();
        if (! $user->isAdmin() && $rec->mentor_id !== $user->id) abort(403);
    }

    private function validateData(Request $request, $user): array
    {
        return $request->validate([
            'kelas_id' => [
                'required',
                Rule::exists('kelas_master', 'id')
                    ->where('is_active', true)
                    ->where('cabang_id', $user->cabang_id)
                    ->whereNull('deleted_at'),
            ],
            'tanggal'      => ['required', 'date', 'before_or_equal:' . JurnalWeek::today()->toDateString()],
            'jam_datang'   => 'required|date_format:H:i',
            'jam_pulang'   => 'required|date_format:H:i|after:jam_datang',
            'jumlah_murid' => 'required|integer|min:0|max:500',
            'catatan'      => 'nullable|string|max:1000',
        ]);
    }
}
