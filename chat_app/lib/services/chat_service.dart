import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetch user's 1-on-1 chats
  Future<List<ChatModel>> getChats(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      final list =
          snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();

      // Sort by latest message time in memory
      list.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Fetch user's group chats
  Future<List<GroupModel>> getGroups(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: currentUserId)
          .get();

      final list =
          snapshot.docs.map((doc) => GroupModel.fromDocument(doc)).toList();

      list.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Fetch call history for user
  Future<List<CallLogModel>> getCallLogs(String currentUserId) async {
    try {
      // Fetch calls where user is caller or receiver
      final callerSnapshot = await _firestore
          .collection('call_logs')
          .where('callerId', isEqualTo: currentUserId)
          .get();

      final receiverSnapshot = await _firestore
          .collection('call_logs')
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      final Map<String, CallLogModel> logsMap = {};

      for (var doc in callerSnapshot.docs) {
        logsMap[doc.id] = CallLogModel.fromDocument(doc);
      }
      for (var doc in receiverSnapshot.docs) {
        logsMap[doc.id] = CallLogModel.fromDocument(doc);
      }

      final list = logsMap.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Fetch all registered users to start new chat or create group
  Future<List<UserModel>> getAllUsers(String currentUserId) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromDocument(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get existing 1-on-1 chat or create a new one
  Future<ChatModel> getOrCreateChat({
    required UserModel currentUser,
    required UserModel peerUser,
  }) async {
    // Deterministic Chat ID based on sorted UIDs
    final uids = [currentUser.uid, peerUser.uid]..sort();
    final chatId = '${uids[0]}_${uids[1]}';

    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await chatDocRef.get();

    if (docSnapshot.exists) {
      return ChatModel.fromDocument(docSnapshot);
    }

    // Create new chat document
    final newChatData = {
      'participants': [currentUser.uid, peerUser.uid],
      'participantDetails': {
        currentUser.uid: {
          'name': currentUser.name,
          'photoUrl': currentUser.photoUrl,
          'email': currentUser.email,
        },
        peerUser.uid: {
          'name': peerUser.name,
          'photoUrl': peerUser.photoUrl,
          'email': peerUser.email,
        },
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unreadCount': 0,
    };

    await chatDocRef.set(newChatData);
    final createdDoc = await chatDocRef.get();
    return ChatModel.fromDocument(createdDoc);
  }

  /// Fetch messages for a chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromDocument(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Send a message in a 1-on-1 chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final batch = _firestore.batch();

    // 1. Add message document
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2. Update parent chat doc
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    });

    await batch.commit();
  }

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    File? iconFile,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    String iconUrl = '';

    // Upload group icon if provided
    if (iconFile != null) {
      try {
        final path = 'groups/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(path);
        final task = await ref.putFile(
          iconFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        iconUrl = await task.ref.getDownloadURL();
      } catch (_) {}
    }

    // Ensure creator is in members and adminIds
    final allMembers = {...memberIds, createdBy}.toList();
    final groupRef = _firestore.collection('groups').doc();

    final groupData = {
      'name': name.trim(),
      'description': description.trim(),
      'iconUrl': iconUrl,
      'createdBy': createdBy,
      'adminIds': [createdBy],
      'members': allMembers,
      'lastMessage': 'Group created',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await groupRef.set(groupData);
    final docSnapshot = await groupRef.get();
    return GroupModel.fromDocument(docSnapshot);
  }
}

