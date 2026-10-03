<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Message $message)
    {
        $this->message->load(['user:id,name', 'replyTo:id,body,user_id']);
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('conversation.' . $this->message->conversation_id)];
    }

    public function broadcastAs(): string
    {
        return 'MessageSent';
    }

    public function broadcastWith(): array
    {
        return [
            'id'              => $this->message->id,
            'conversation_id' => $this->message->conversation_id,
            'user_id'         => $this->message->user_id,
            'user_name'       => $this->message->user->name ?? '',
            'type'            => $this->message->type,
            'body'            => $this->message->body,
            'attachment_url'  => $this->message->attachment_url,
            'attachment_name' => $this->message->attachment_name,
            'attachment_mime' => $this->message->attachment_mime,
            'attachment_size' => $this->message->attachment_size,
            'thumbnail_url'   => $this->message->thumbnail_url,
            'reply_to'        => $this->message->replyTo ? [
                'id'      => $this->message->replyTo->id,
                'body'    => $this->message->replyTo->body,
                'user_id' => $this->message->replyTo->user_id,
            ] : null,
            'deleted_at'  => null,
            'created_at'  => $this->message->created_at->toISOString(),
        ];
    }
}
