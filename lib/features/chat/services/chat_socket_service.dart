import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';

class ChatSocketConfig {
  static const appKey = 'scnias_reverb_key_2026';
  static const host = 'studycenter.nanoprojectdevindonesia.com';
  static const port = 443;
  static const authUrl = 'https://studycenter.nanoprojectdevindonesia.com/broadcasting/auth';
}

class ChatSocketService {
  final StorageService _storage;
  PusherChannelsClient? _client;
  PrivateChannel? _currentChannel;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final Map<String, void Function(dynamic)> _channelListeners = {};

  ChatSocketService(this._storage);

  Future<void> connect({VoidCallback? onConnected, void Function(String)? onError}) async {
    if (_isConnected || _client != null) return;

    try {
      final token = await _storage.getToken();
      if (token == null) throw Exception('No auth token');

      final options = PusherChannelsOptions.fromHost(
        scheme: 'wss',
        host: ChatSocketConfig.host,
        port: ChatSocketConfig.port,
        key: ChatSocketConfig.appKey,
      );

      _client = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (error, trace, refresh) {
          debugPrint('[Pusher] Connection error: $error');
          onError?.call(error.toString());
        },
      );

      _client!.onConnectionEstablished.listen((event) {
        _isConnected = true;
        debugPrint('[Pusher] Connected');
        onConnected?.call();
      });

      _client!.lifecycleStream.listen((state) {
        if (state == PusherChannelsClientLifeCycleState.disconnected || state == PusherChannelsClientLifeCycleState.disposed || state == PusherChannelsClientLifeCycleState.connectionError) {
          _isConnected = false;
          debugPrint('[Pusher] Disconnected');
        }
      });

      _client!.connect();
    } catch (e) {
      debugPrint('[Pusher] Init Error: $e');
      onError?.call(e.toString());
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected || _client == null) return;
    _client!.disconnect();
    _client = null;
    _isConnected = false;
  }

  Future<void> subscribeConversation(int convId, void Function(dynamic) onEvent) async {
    if (_client == null) return;
    final channelName = 'private-conversation.$convId';
    _channelListeners[channelName] = onEvent;

    final token = await _storage.getToken();
    
    _currentChannel = _client!.privateChannel(
      channelName,
      authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
        authorizationEndpoint: Uri.parse(ChatSocketConfig.authUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    _currentChannel!.subscribeIfNotUnsubscribed();
    
    _currentChannel!.bind('MessageSent').listen((event) {
      debugPrint('[Pusher] Event MessageSent');
      onEvent(event);
    });

    _currentChannel!.bind('client-typing').listen((event) {
      debugPrint('[Pusher] Event client-typing');
      onEvent(event);
    });
  }

  Future<void> unsubscribeConversation(int convId) async {
    if (_currentChannel != null) {
      _currentChannel!.unsubscribe();
      _currentChannel = null;
    }
    final channelName = 'private-conversation.$convId';
    _channelListeners.remove(channelName);
    debugPrint('[Pusher] Unsubscribed from $channelName');
  }

  Future<void> sendTyping(int convId, int userId, String userName) async {
    if (_currentChannel != null) {
      _currentChannel!.trigger(
        eventName: 'client-typing',
        data: {
          'user_id': userId,
          'name': userName,
        },
      );
    }
  }
}

final chatSocketServiceProvider = Provider((ref) => ChatSocketService(ref.read(storageServiceProvider)));
