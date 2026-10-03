<?php

namespace App\Http\Controllers\Chat;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ConversationController extends Controller
{
    /**
     * GET /chat/conversations/{id}/messages
     * Load pesan (paginated, terbaru dulu).
     */
    public function messages(Conversation $conversation): JsonResponse
    {
        $userId = Auth::id();

        abort_unless(
            $conversation->participants()->where('user_id', $userId)->exists(),
            403,
            'Anda bukan peserta conversation ini.'
        );

        $messages = $conversation->messages()
            ->with(['user:id,name', 'replyTo:id,body,user_id'])
            ->withTrashed()
            ->latest()
            ->paginate(40);

        // Tandai dibaca
        DB::table('conversation_participants')
            ->where('conversation_id', $conversation->id)
            ->where('user_id', $userId)
            ->update(['last_read_at' => now()]);

        return response()->json($messages);
    }

    /**
     * POST /chat/private/{userId}
     * Mulai atau buka private chat.
     */
    public function startPrivate(int $targetUserId): JsonResponse
    {
        $me = Auth::id();
        abort_if($me === $targetUserId, 422, 'Tidak bisa chat dengan diri sendiri.');

        $conv = Conversation::findOrCreatePrivate($me, $targetUserId);

        return response()->json(['conversation_id' => $conv->id]);
    }

    /**
     * POST /chat/group
     * Buat group chat baru.
     */
    public function createGroup(Request $request): JsonResponse
    {
        $request->validate([
            'name'       => 'required|string|max:100',
            'user_ids'   => 'required|array|min:1',
            'user_ids.*' => 'exists:users,id',
        ]);

        $me   = Auth::id();
        $conv = Conversation::create([
            'type'       => 'group',
            'name'       => $request->name,
            'created_by' => $me,
        ]);

        $participants = collect($request->user_ids)
            ->push($me)
            ->unique()
            ->mapWithKeys(fn($id) => [$id => ['role' => $id === $me ? 'admin' : 'member']]);

        $conv->participants()->attach($participants);

        return response()->json(['conversation_id' => $conv->id]);
    }
}
