import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  /// Start observing app lifecycle for presence
  void init() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    // Listen to Auth State changes: when logged in -> set online
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setOnline();
      }
    });

    if (_auth.currentUser != null) {
      setOnline();
    }
  }

  /// Dispose observer
  void dispose() {
    if (!_isInitialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_auth.currentUser == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setOffline();
        break;
    }
  }

  /// Mark current user as online
  Future<void> setOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Mark current user as offline
  Future<void> setOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  /// Stream single user presence & data
  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    });
  }

  /// Helper to format "Last seen" for UI display
  static String formatLastSeen({
    required bool isOnline,
    required DateTime? lastSeen,
    String lastSeenPrivacy = 'everyone',
  }) {
    if (lastSeenPrivacy == 'nobody') {
      return isOnline ? 'Online' : '';
    }

    if (isOnline) {
      return 'Online';
    }

    if (lastSeen == null) {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    }

    final timeFormat = DateFormat('h:mm a');
    final formattedTime = timeFormat.format(lastSeen);

    final isToday = now.year == lastSeen.year &&
        now.month == lastSeen.month &&
        now.day == lastSeen.day;

    if (isToday) {
      return 'Last seen today at $formattedTime';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == lastSeen.year &&
        yesterday.month == lastSeen.month &&
        yesterday.day == lastSeen.day;

    if (isYesterday) {
      return 'Last seen yesterday at $formattedTime';
    }

    final dateFormat = DateFormat('MMM d');
    return 'Last seen ${dateFormat.format(lastSeen)} at $formattedTime';
  }
}

