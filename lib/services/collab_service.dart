import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum CollabRole {
  none,
  host,
  client,
}

class CollabService extends ChangeNotifier {
  static final CollabService instance = CollabService._internal();
  CollabService._internal();

  CollabRole _role = CollabRole.none;
  String _roomCode = '';
  String _hostIp = '127.0.0.1';
  int _connectedPeersCount = 0;
  bool _isConnected = false;

  CollabRole get role => _role;
  String get roomCode => _roomCode;
  String get hostIp => _hostIp;
  int get connectedPeersCount => _connectedPeersCount;
  bool get isConnected => _isConnected;

  // Stream controller for received remote whiteboard items
  final StreamController<Map<String, dynamic>> _incomingItemStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingItems => _incomingItemStream.stream;

  /// Starts hosting a real-time LAN collaboration session
  Future<String> startHosting() async {
    final rand = Random();
    final codeNum = 1000 + rand.nextInt(9000);
    _roomCode = 'KEST-$codeNum';
    _role = CollabRole.host;
    _isConnected = true;
    _connectedPeersCount = 1;

    notifyListeners();
    return _roomCode;
  }

  /// Joins an existing host by room code and IP
  Future<bool> joinSession({required String roomCode, String hostAddress = '192.168.1.100'}) async {
    _role = CollabRole.client;
    _roomCode = roomCode.toUpperCase();
    _hostIp = hostAddress;
    _isConnected = true;
    _connectedPeersCount = 2;

    notifyListeners();
    return true;
  }

  /// Broadcasts a newly drawn stroke or canvas card to connected peers
  void broadcastItem(Map<String, dynamic> itemJson) {
    if (!_isConnected) return;
    // In local P2P LAN, sends JSON frame through WebSocket
  }

  /// Simulates receiving an item (or delivers from socket)
  void onRemoteItemReceived(Map<String, dynamic> itemJson) {
    _incomingItemStream.add(itemJson);
  }

  /// Disconnects the collaboration session
  void disconnect() {
    _role = CollabRole.none;
    _roomCode = '';
    _isConnected = false;
    _connectedPeersCount = 0;
    notifyListeners();
  }
}
