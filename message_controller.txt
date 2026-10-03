<?php

namespace App\Http\Controllers\Chat;

use App\Events\MessageRead;
use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Jobs\ProcessChatAttachment;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class MessageController extends Controller
{
    /**
     * POST /chat/conversations/{id}/messages
     */
    public function send(Request $request, Conversation $conversation): JsonResponse
    {
        $userId = Auth::id();

        abort_unless(
            $conversation->participants()->where('user_id', $userId)->exists(),
            403
        );

        $request->validate([
            'type'        => 'required|in:text,image,file',
            'body'        => 'nullable|string|max:5000',
            'attachment'  => 'nullable|file|max:51200', // 50 MB
            'reply_to_id' => 'nullable|exists:messages,id',
        ]);

        if ($request->type === 'text' && ! $request->filled('body')) {
            return response()->json(['error' => 'Pesan tidak boleh kosong'], 422);
        }

        $data = [
            'conversation_id' => $conversation->id,
            'user_id'         => $userId,
            'type'            => $request->type,
            'body'            => $request->body,
            'reply_to_id'     => $request->reply_to_id,
        ];

        if ($request->hasFile('attachment')) {
            $file      = $request->file('attachment');
            $ext       = $file->getClientOriginalExtension();
            $filename  = Str::uuid() . '.' . $ext;
            $subFolder = $request->type === 'image' ? 'chat/images' : 'chat/files';
            $path      = $file->storeAs($subFolder, $filename, 'public');

            $data['attachment_path'] = $path;
            $data['attachment_name'] = $file->getClientOriginalName();
            $data['attachment_mime'] = $file->getMimeType();
            $data['attachment_size'] = $file->getSize();
        }

        $message = Message::create($data);

        if ($data['type'] === 'image' && ! empty($data['attachment_path'])) {
            ProcessChatAttachment::dispatch($message->id);
        }

        $conversation->update(['last_message_at' => now()]);

        DB::table('conversation_participants')
            ->where('conversation_id', $conversation->id)
            ->where('user_id', $userId)
            ->update(['last_read_at' => now()]);

        broadcast(new MessageSent($message));

        return response()->json([
            'message' => $message->fresh(['user:id,name', 'replyTo:id,body,user_id']),
        ], 201);
    }

    /**
     * DELETE /chat/messages/{id}
     */
    public function destroy(Message $message): JsonResponse
    {
        abort_unless($message->user_id === Auth::id(), 403);
        $message->delete();
        return response()->json(['ok' => true]);
    }

    /**
     * POST /chat/conversations/{id}/read
     */
    public function markRead(Conversation $conversation): JsonResponse
    {
        $userId = Auth::id();

        abort_unless(
            $conversation->participants()->where('user_id', $userId)->exists(),
            403
        );

        DB::table('conversation_participants')
            ->where('conversation_id', $conversation->id)
            ->where('user_id', $userId)
            ->update(['last_read_at' => now()]);

        broadcast(new MessageRead($conversation->id, $userId, now()->toISOString()))
            ->toOthers();

        return response()->json(['ok' => true]);
    }
}
