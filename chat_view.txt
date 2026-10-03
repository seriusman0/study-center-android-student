@extends('layouts.app')
@section('title', 'Chat — Study Center Nias')

@push('head')
<style>
/* ───────────────────────────── Layout ──────────────────────────────── */
#chat-root {
    height: calc(100dvh - 56px);
    display: flex;
    overflow: hidden;
    background: #f0f2f5;
}

/* Sidebar */
#chat-sidebar {
    width: 320px;
    min-width: 320px;
    display: flex;
    flex-direction: column;
    background: #fff;
    border-right: 1px solid #e5e7eb;
    overflow: hidden;
}

/* Area utama */
#chat-main {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
    overflow: hidden;
}

/* ───────────── Mobile ──────────────── */
@media (max-width: 639px) {
    #chat-sidebar  { width: 100%; min-width: 0; position: absolute; inset: 0; z-index: 10; }
    #chat-sidebar.hidden-mobile { display: none; }
    #chat-main.hidden-mobile    { display: none; }
}

/* ───────────── Bubble ──────────────── */
.bubble-me    { background: #dcf8c6; border-radius: 1rem 0.2rem 1rem 1rem; }
.bubble-other { background: #ffffff; border-radius: 0.2rem 1rem 1rem 1rem; }

/* ───────────── Message area bg ──────── */
#msg-area {
    background-color: #e5ddd5;
    background-image: repeating-linear-gradient(
        45deg,
        transparent,
        transparent 20px,
        rgba(0,0,0,.015) 20px,
        rgba(0,0,0,.015) 40px
    );
    overflow-y: auto;
    flex: 1;
}

/* ───────────── Thin scrollbar ──────── */
::-webkit-scrollbar         { width: 4px; height: 4px; }
::-webkit-scrollbar-thumb   { background: #b0b0b0; border-radius: 4px; }
::-webkit-scrollbar-track   { background: transparent; }

/* ───────────── Input area ──────────── */
#msg-input {
    background: #fff;
    border: none;
    outline: none;
    resize: none;
    flex: 1;
    padding: 10px 14px;
    font-size: 0.9rem;
    line-height: 1.4;
    min-height: 42px;
    max-height: 120px;
    overflow-y: auto;
    border-radius: 24px;
    box-shadow: 0 1px 3px rgba(0,0,0,.12);
    font-family: inherit;
    color: #111;
    -webkit-appearance: none;
}
#msg-input:focus {
    box-shadow: 0 0 0 2px #25d36655;
}
#msg-input::placeholder { color: #9ca3af; }

/* ───────────── Search input ────────── */
.search-input {
    width: 100%;
    background: #f3f4f6;
    border: 1px solid #e5e7eb;
    border-radius: 20px;
    padding: 7px 14px 7px 36px;
    font-size: 0.82rem;
    outline: none;
    transition: border-color .15s;
}
.search-input:focus { border-color: #25D366; background: #fff; }

/* ───────────── Conversation item ───── */
.conv-item {
    display: flex;
    align-items: center;
    padding: 10px 12px;
    cursor: pointer;
    border-bottom: 1px solid #f1f1f1;
    transition: background .1s;
    gap: 10px;
}
.conv-item:hover   { background: #f9fafb; }
.conv-item.active  { background: #d9fdd3; border-left: 3px solid #25D366; }
.conv-avatar {
    width: 44px; height: 44px; border-radius: 50%;
    background: #128C7E;
    color: #fff; font-weight: 700; font-size: 1.1rem;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
}

/* ───────────── Typing dots ─────────── */
.typing-dot {
    display: inline-block; width: 6px; height: 6px;
    background: #aaa; border-radius: 50%;
    animation: blink 1.2s infinite;
}
.typing-dot:nth-child(2) { animation-delay: .2s; }
.typing-dot:nth-child(3) { animation-delay: .4s; }
@keyframes blink { 0%,80%,100% { opacity:.2; } 40% { opacity:1; } }

/* ───────────── Hover actions on message ─── */
.msg-actions {
    position: absolute; top: 0;
    display: flex; gap: 4px;
    opacity: 0; pointer-events: none;
    transition: opacity .15s;
}
.msg-wrap:hover .msg-actions { opacity: 1; pointer-events: auto; }
</style>

{{-- Data server-side → JS global. Hindari multiline di x-data attribute (Alpine parser crash) --}}
<script>
window.__chatInit = {
    conversations: @json($conversations),
    users:         @json($users),
    userId:        {{ (int) Auth::id() }},
    userName:      @json(Auth::user()->name)
};
</script>
@endpush

@section('content')
<div id="chat-root"
     x-data="chatApp(window.__chatInit)"
     x-init="init()">

    {{-- ════════════════════════════════════════════════════════
         SIDEBAR
    ════════════════════════════════════════════════════════ --}}
    <aside id="chat-sidebar"
           :class="{ 'hidden-mobile': !showMobileSidebar }">

        {{-- Header sidebar --}}
        <div class="flex items-center justify-between px-3 py-2.5 flex-shrink-0"
             style="background:#075E54">
            <span class="text-white font-bold text-sm">💬 Chat</span>
            <div class="flex gap-1.5">
                <button @click="showNewGroup = !showNewGroup; showNewChat = false; userSearch = ''"
                        class="text-xs text-white bg-white/20 hover:bg-white/30 px-2.5 py-1 rounded-full transition">
                    + Grup
                </button>
                <button @click="showNewChat = !showNewChat; showNewGroup = false; userSearch = ''"
                        class="text-xs text-white bg-white/20 hover:bg-white/30 px-2.5 py-1 rounded-full transition">
                    + Chat
                </button>
            </div>
        </div>

        {{-- Search conversation --}}
        <div class="px-3 py-2 flex-shrink-0 border-b">
            <div class="relative">
                <svg class="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M21 21l-4.35-4.35M17 11A6 6 0 115 11a6 6 0 0112 0z"/>
                </svg>
                <input type="search" placeholder="Cari percakapan…"
                       class="search-input" style="padding-left:36px"
                       x-show="!showNewChat && !showNewGroup">
            </div>
        </div>

        {{-- ── Panel: Chat Baru ── --}}
        <div x-show="showNewChat" x-transition class="border-b bg-gray-50 flex-shrink-0">
            <div class="px-3 pt-2.5 pb-1">
                <p class="text-xs font-semibold text-gray-500 mb-1.5 uppercase tracking-wider">Mulai Chat Dengan</p>
                {{-- Search user --}}
                <div class="relative mb-2">
                    <svg class="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M21 21l-4.35-4.35M17 11A6 6 0 115 11a6 6 0 0112 0z"/>
                    </svg>
                    <input type="search"
                           x-model="userSearch"
                           placeholder="Cari nama user…"
                           class="search-input"
                           autocomplete="off">
                </div>
            </div>
            <div class="overflow-y-auto" style="max-height:220px">
                <template x-if="filteredUsers.length === 0">
                    <p class="text-xs text-gray-400 text-center py-4">Tidak ada user ditemukan</p>
                </template>
                <template x-for="u in filteredUsers" :key="u.id">
                    <button @click="startPrivateWith(u.id)"
                            class="w-full flex items-center gap-2.5 px-3 py-2 hover:bg-green-50 transition text-left">
                        <span class="w-8 h-8 rounded-full bg-[#128C7E] text-white flex items-center justify-center font-bold text-xs flex-shrink-0"
                              x-text="u.name[0].toUpperCase()"></span>
                        <span class="text-sm truncate" x-text="u.name"></span>
                    </button>
                </template>
            </div>
        </div>

        {{-- ── Panel: Buat Group ── --}}
        <div x-show="showNewGroup" x-transition class="border-b bg-gray-50 flex-shrink-0">
            <div class="px-3 pt-2.5 pb-2">
                <p class="text-xs font-semibold text-gray-500 mb-2 uppercase tracking-wider">Buat Grup Baru</p>
                <input x-model="groupName" type="text" placeholder="Nama grup…"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm mb-2
                              focus:ring-2 focus:ring-[#25D366] focus:border-transparent focus:outline-none" />
                <div class="relative mb-1.5">
                    <svg class="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                              d="M21 21l-4.35-4.35M17 11A6 6 0 115 11a6 6 0 0112 0z"/>
                    </svg>
                    <input type="search" x-model="userSearch" placeholder="Cari anggota…"
                           class="search-input" autocomplete="off">
                </div>
            </div>
            <div class="overflow-y-auto px-3" style="max-height:160px">
                <template x-for="u in filteredUsers" :key="u.id">
                    <label class="flex items-center gap-2.5 py-1.5 hover:bg-green-50 rounded cursor-pointer text-sm">
                        <input type="checkbox" :checked="selectedUserIds.includes(u.id)"
                               @change="toggleUser(u.id)"
                               class="rounded accent-[#128C7E] w-4 h-4">
                        <span x-text="u.name" class="truncate"></span>
                    </label>
                </template>
            </div>
            <div class="px-3 py-2 flex gap-2">
                <span class="text-xs text-gray-400 my-auto"
                      x-text="selectedUserIds.length + ' dipilih'"></span>
                <button @click="createGroup()"
                        class="ml-auto text-sm font-semibold bg-[#128C7E] text-white px-4 py-1.5
                               rounded-lg hover:bg-[#075E54] transition">
                    Buat
                </button>
                <button @click="showNewGroup=false; userSearch=''; selectedUserIds=[]"
                        class="text-sm text-gray-500 px-3 py-1.5 rounded-lg hover:bg-gray-100 transition">
                    Batal
                </button>
            </div>
        </div>

        {{-- Daftar Conversation --}}
        <div class="flex-1 overflow-y-auto">
            <template x-if="conversations.length === 0">
                <div class="p-8 text-center text-gray-400 text-sm">
                    <div class="text-4xl mb-3">💬</div>
                    <p class="font-medium text-gray-500">Belum ada percakapan</p>
                    <p class="text-xs mt-1">Klik <strong>+ Chat</strong> untuk memulai</p>
                </div>
            </template>

            <template x-for="conv in conversations" :key="conv.id">
                <div class="conv-item"
                     :class="{ active: activeConvId === conv.id }"
                     @click="openConversation(conv.id)">
                    <div class="conv-avatar" x-text="convInitial(conv)"></div>
                    <div class="flex-1 min-w-0">
                        <div class="flex justify-between items-baseline gap-1">
                            <span class="font-semibold text-sm truncate text-gray-800"
                                  x-text="convName(conv)"></span>
                            <span class="text-xs text-gray-400 flex-shrink-0 whitespace-nowrap"
                                  x-text="conv.last_message ? formatTime(conv.last_message.created_at) : ''">
                            </span>
                        </div>
                        <div class="flex justify-between items-center mt-0.5 gap-1">
                            <span class="text-xs text-gray-500 truncate"
                                  x-text="lastMsgPreview(conv)"></span>
                            <span x-show="(conv.unread_count ?? 0) > 0"
                                  class="flex-shrink-0 bg-[#25D366] text-white text-xs font-bold
                                         rounded-full min-w-[20px] h-5 flex items-center justify-center px-1"
                                  x-text="conv.unread_count > 99 ? '99+' : conv.unread_count">
                            </span>
                        </div>
                    </div>
                </div>
            </template>
        </div>
    </aside>

    {{-- ════════════════════════════════════════════════════════
         AREA CHAT UTAMA
    ════════════════════════════════════════════════════════ --}}
    <main id="chat-main"
          :class="{ 'hidden-mobile': showMobileSidebar && !activeConvId }">

        {{-- ── Empty state ── --}}
        <div x-show="!activeConvId"
             class="flex-1 flex flex-col items-center justify-center text-gray-400 h-full">
            <div class="text-6xl mb-4">💬</div>
            <p class="text-lg font-semibold text-gray-600">Study Center Nias Chat</p>
            <p class="text-sm mt-1">Pilih percakapan atau klik <strong>+ Chat</strong> untuk mulai</p>
        </div>

        {{-- ── Chat aktif ── --}}
        <template x-if="activeConvId">
            <div class="flex flex-col h-full">

                {{-- Header --}}
                <div class="flex items-center gap-3 px-4 py-2.5 flex-shrink-0 shadow-sm"
                     style="background:#075E54">
                    {{-- Tombol back mobile --}}
                    <button @click="backToList()"
                            class="sm:hidden text-white mr-1 p-1 -ml-1 rounded-lg hover:bg-white/20 transition">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
                        </svg>
                    </button>
                    <div class="w-9 h-9 rounded-full bg-white/20 flex items-center justify-center
                                font-bold text-white text-sm flex-shrink-0"
                         x-text="convInitial(activeConv)"></div>
                    <div class="flex-1 min-w-0">
                        <div class="font-semibold text-white text-sm truncate"
                             x-text="convName(activeConv)"></div>
                        <div class="h-4 text-xs text-green-200">
                            <template x-if="Object.keys(isTyping).length > 0">
                                <span>
                                    <span x-text="typingNames"></span> mengetik
                                    <span class="typing-dot"></span>
                                    <span class="typing-dot"></span>
                                    <span class="typing-dot"></span>
                                </span>
                            </template>
                        </div>
                    </div>
                </div>

                {{-- Pesan --}}
                <div id="msg-area" x-ref="messageList" class="px-3 py-4 space-y-1">

                    {{-- Loading --}}
                    <div x-show="isLoading" class="flex justify-center py-12">
                        <svg class="animate-spin h-7 w-7 text-[#128C7E]" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10"
                                    stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor"
                                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                        </svg>
                    </div>

                    <template x-for="msg in messages" :key="msg.id">
                        <div class="flex msg-wrap"
                             :class="msg.user_id === currentUserId ? 'justify-end' : 'justify-start'">
                            <div class="relative" style="max-width:72%;max-width:min(72%,380px)">

                                {{-- Nama pengirim (grup) --}}
                                <template x-if="msg.user_id !== currentUserId && activeConv?.type === 'group'">
                                    <div class="text-xs font-semibold mb-0.5 pl-1"
                                         style="color:#128C7E" x-text="msg.user_name"></div>
                                </template>

                                {{-- Bubble --}}
                                <div class="px-3 py-2 text-sm shadow-sm"
                                     :class="msg.user_id === currentUserId ? 'bubble-me' : 'bubble-other'">

                                    {{-- Reply preview --}}
                                    <template x-if="msg.reply_to && !msg.deleted_at">
                                        <div class="border-l-4 border-[#128C7E] pl-2 py-1 mb-2 rounded
                                                    bg-black/5 text-xs text-gray-500 truncate">
                                            <span x-text="msg.reply_to.body?.substring(0,80) ?? '📎 Lampiran'"></span>
                                        </div>
                                    </template>

                                    {{-- DELETED --}}
                                    <template x-if="msg.deleted_at">
                                        <span class="italic text-gray-400 text-xs">🚫 Pesan dihapus</span>
                                    </template>

                                    {{-- KONTEN --}}
                                    <template x-if="!msg.deleted_at">
                                        <div>
                                            {{-- IMAGE --}}
                                            <template x-if="msg.type === 'image'">
                                                <div>
                                                    <img :src="msg.thumbnail_url || msg.attachment_url"
                                                         @click="msg.attachment_url && window.open(msg.attachment_url,'_blank')"
                                                         class="rounded-lg max-w-full cursor-pointer object-cover"
                                                         style="max-height:220px"
                                                         loading="lazy" />
                                                    <template x-if="msg.body">
                                                        <p class="mt-1 whitespace-pre-wrap text-sm"
                                                           x-text="msg.body"></p>
                                                    </template>
                                                </div>
                                            </template>

                                            {{-- FILE --}}
                                            <template x-if="msg.type === 'file'">
                                                <div>
                                                    <a :href="msg.attachment_url"
                                                       target="_blank"
                                                       class="flex items-center gap-2.5 bg-black/5 rounded-lg
                                                              px-3 py-2 hover:bg-black/10 transition no-underline">
                                                        <div class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
                                                             style="background:#128C7E">
                                                            <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                                                                <path d="M4 18a2 2 0 002 2h8a2 2 0 002-2V8l-4-4H6a2 2 0 00-2 2v12zm8-12l2 2h-2V6z"/>
                                                            </svg>
                                                        </div>
                                                        <div class="min-w-0">
                                                            <p class="text-xs font-semibold truncate"
                                                               x-text="msg.attachment_name"></p>
                                                            <p class="text-xs text-gray-500"
                                                               x-text="formatSize(msg.attachment_size)"></p>
                                                        </div>
                                                        <svg class="w-4 h-4 text-gray-400 flex-shrink-0 ml-auto"
                                                             fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                                  stroke-width="2"
                                                                  d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                                                        </svg>
                                                    </a>
                                                    <template x-if="msg.body">
                                                        <p class="mt-1 text-sm whitespace-pre-wrap"
                                                           x-text="msg.body"></p>
                                                    </template>
                                                </div>
                                            </template>

                                            {{-- TEXT --}}
                                            <template x-if="msg.type === 'text'">
                                                <p class="whitespace-pre-wrap break-words text-sm"
                                                   x-text="msg.body"></p>
                                            </template>
                                        </div>
                                    </template>

                                    {{-- Timestamp --}}
                                    <div class="flex justify-end items-center gap-1 mt-1">
                                        <span class="text-xs text-gray-400"
                                              x-text="formatTime(msg.created_at)"></span>
                                        <template x-if="msg._sending">
                                            <svg class="w-3 h-3 text-gray-400 animate-spin" fill="none" viewBox="0 0 24 24">
                                                <circle class="opacity-25" cx="12" cy="12" r="10"
                                                        stroke="currentColor" stroke-width="4"></circle>
                                                <path class="opacity-75" fill="currentColor"
                                                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                                            </svg>
                                        </template>
                                        <template x-if="!msg._sending && msg.user_id === currentUserId && !msg.deleted_at">
                                            <svg class="w-3.5 h-3.5 text-blue-400" fill="currentColor" viewBox="0 0 24 24">
                                                <path d="M18 7l-9.5 9.5-4-4-1.5 1.5 5.5 5.5L19.5 8.5z"/>
                                            </svg>
                                        </template>
                                    </div>
                                </div>

                                {{-- Aksi (hover desktop, selalu di mobile) --}}
                                <div class="msg-actions"
                                     :class="msg.user_id === currentUserId ? 'right-full mr-1' : 'left-full ml-1'">
                                    <button @click="setReply(msg)"
                                            title="Balas"
                                            class="w-7 h-7 rounded-full bg-white shadow flex items-center
                                                   justify-center text-gray-500 hover:text-[#128C7E] text-sm">
                                        ↩
                                    </button>
                                    <template x-if="msg.user_id === currentUserId && !msg.deleted_at">
                                        <button @click="deleteMessage(msg.id)"
                                                title="Hapus"
                                                class="w-7 h-7 rounded-full bg-white shadow flex items-center
                                                       justify-center text-gray-400 hover:text-red-500">
                                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M1 7h22M8 7V5a1 1 0 011-1h6a1 1 0 011 1v2"/>
                                            </svg>
                                        </button>
                                    </template>
                                </div>

                            </div>
                        </div>
                    </template>
                </div>

                {{-- Reply bar --}}
                <div x-show="replyTo"
                     x-transition:enter="transition ease-out duration-100"
                     x-transition:enter-start="opacity-0 translate-y-1"
                     x-transition:enter-end="opacity-100 translate-y-0"
                     class="flex items-center gap-2 px-3 py-2 bg-white border-t border-gray-100 flex-shrink-0">
                    <div class="flex-1 min-w-0 border-l-4 border-[#128C7E] pl-2">
                        <p class="text-xs font-semibold text-[#128C7E]">↩ Membalas</p>
                        <p class="text-xs text-gray-500 truncate"
                           x-text="replyTo?.body?.substring(0,80) ?? '📎 Lampiran'"></p>
                    </div>
                    <button @click="cancelReply()"
                            class="flex-shrink-0 text-gray-400 hover:text-red-500 transition p-1">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                  d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                {{-- Attachment preview --}}
                <div x-show="attachmentFile"
                     x-transition
                     class="flex items-center gap-3 px-3 py-2 bg-white border-t border-gray-100 flex-shrink-0">
                    <template x-if="attachmentPreview">
                        <img :src="attachmentPreview"
                             class="h-14 w-14 rounded-lg object-cover flex-shrink-0 shadow-sm" />
                    </template>
                    <template x-if="!attachmentPreview && attachmentFile">
                        <div class="flex items-center gap-2">
                            <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                                 style="background:#128C7E">
                                <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                                    <path d="M4 18a2 2 0 002 2h8a2 2 0 002-2V8l-4-4H6a2 2 0 00-2 2v12zm8-12l2 2h-2V6z"/>
                                </svg>
                            </div>
                            <div class="min-w-0">
                                <p class="text-sm font-medium truncate max-w-[200px]"
                                   x-text="attachmentFile?.name"></p>
                                <p class="text-xs text-gray-400"
                                   x-text="formatSize(attachmentFile?.size)"></p>
                            </div>
                        </div>
                    </template>
                    <button @click="clearAttachment()"
                            class="ml-auto text-gray-400 hover:text-red-500 transition p-1 flex-shrink-0">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                  d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                {{-- ── Input bar ── --}}
                <div class="flex items-end gap-2 px-3 py-2 flex-shrink-0 bg-[#f0f2f5] border-t">

                    {{-- Tombol lampiran --}}
                    <label class="flex-shrink-0 cursor-pointer text-gray-500 hover:text-[#128C7E]
                                  transition p-1 mb-1 rounded-full hover:bg-gray-200" title="Lampirkan">
                        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                  d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828L18 9.828a4 4 0 00-5.656-5.656l-6.586 6.586a6 6 0 108.485 8.485L19.5 14.5"/>
                        </svg>
                        <input type="file"
                               class="hidden"
                               accept="image/*,application/pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.rar,.txt,.mp4,.mp3"
                               @change="handleFileSelect($event)">
                    </label>

                    {{-- Textarea input --}}
                    <textarea
                        id="msg-input"
                        x-ref="messageInput"
                        x-model="inputText"
                        @keydown="onInputKeydown($event)"
                        @input="onTyping()"
                        placeholder="Tulis pesan…"
                        rows="1"
                        autocomplete="off"
                        spellcheck="true"
                    ></textarea>

                    {{-- Kirim --}}
                    <button @click="sendMessage()"
                            :disabled="isSending"
                            class="flex-shrink-0 w-10 h-10 mb-0.5 rounded-full text-white
                                   flex items-center justify-center shadow transition
                                   active:scale-95 disabled:opacity-50"
                            style="background:#128C7E"
                            :style="isSending ? '' : 'hover:background:#075E54'">
                        <svg class="w-5 h-5 rotate-45" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
                        </svg>
                    </button>
                </div>

            </div>
        </template>
    </main>
</div>
@endsection
