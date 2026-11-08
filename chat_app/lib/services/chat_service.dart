import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Real-time stream of 1-on-1 chats for the current user
  Stream<List<ChatModel>> streamChats(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();
      list.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });
      return list;
    });
  }

  /// Real-time stream of groups for the current user
  Stream<List<GroupModel>> streamGroups(String currentUserId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => GroupModel.fromDocument(doc)).toList();
      list.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });
      return list;
    });
  }

  /// Real-time stream of messages in a 1-on-1 chat or group
  Stream<List<MessageModel>> streamMessages(String chatId, {bool isGroup = false}) {
    final collection = isGroup ? 'groups' : 'chats';
    return _firestore
        .collection(collection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList());
  }

  /// One-time fetch of chats for user
  Future<List<ChatModel>> getChats(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();
      final list =
          snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();
      list.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  /// One-time fetch of groups for user
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
    } catch (_) {
      return [];
    }
  }

  /// One-time fetch of messages
  Future<List<MessageModel>> getMessages(String chatId, {bool isGroup = false}) async {
    try {
      final collection = isGroup ? 'groups' : 'chats';
      final snapshot = await _firestore
          .collection(collection)
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MessageModel.fromDocument(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ensure initial users (Orvex Tech Solutions and demo contacts) exist in Firestore
  Future<void> ensureDefaultUsersSeeded() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final hasOrvex = usersSnap.docs.any(
        (doc) {
          final data = doc.data();
          final email = (data['email'] as String? ?? '').toLowerCase();
          return email == AuthService.orvexEmail || doc.id == 'orvex_tech_official';
        },
      );

      if (!hasOrvex) {
        String orvexUid = 'orvex_tech_official';
        try {
          final tempApp = await Firebase.initializeApp(
            name: 'OrvexSeedApp_${DateTime.now().millisecondsSinceEpoch}',
            options: DefaultFirebaseOptions.currentPlatform,
          );
          final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
          UserCredential cred;
          try {
            cred = await tempAuth.signInWithEmailAndPassword(
              email: AuthService.orvexEmail,
              password: AuthService.orvexPassword,
            );
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
              cred = await tempAuth.createUserWithEmailAndPassword(
                email: AuthService.orvexEmail,
                password: AuthService.orvexPassword,
              );
            } else {
              rethrow;
            }
          }
          if (cred.user != null) {
            orvexUid = cred.user!.uid;
            await cred.user!.updateDisplayName('Orvex Tech Solutions');
          }
          await tempApp.delete();
        } catch (_) {}

        await _firestore.collection('users').doc(orvexUid).set({
          'uid': orvexUid,
          'name': 'Orvex Tech Solutions',
          'email': AuthService.orvexEmail,
          'photoUrl':
              'https://ui-avatars.com/api/?name=Orvex+Tech&background=1B5E20&color=fff&size=256',
          'bio':
              'Official Account of Orvex Tech Solutions. We craft next-generation mobile apps, modern web platforms, and intelligent software systems.',
          'statusMessage': 'Transforming ideas into digital reality 🚀',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // If database has very few users, also add demo contacts so users can test immediately
      if (usersSnap.docs.length < 2) {
        await _firestore.collection('users').doc('ayesha_khan_dev').set({
          'uid': 'ayesha_khan_dev',
          'name': 'Ayesha Khan',
          'email': 'ayesha.khan@example.com',
          'photoUrl':
              'https://ui-avatars.com/api/?name=Ayesha+Khan&background=2E7D32&color=fff&size=256',
          'bio': 'Flutter Developer & UI/UX enthusiast ✨',
          'statusMessage': 'Building beautiful cross-platform apps 📱',
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('users').doc('hamza_ali_dev').set({
          'uid': 'hamza_ali_dev',
          'name': 'Hamza Ali',
          'email': 'hamza.ali@example.com',
          'photoUrl':
              'https://ui-avatars.com/api/?name=Hamza+Ali&background=388E3C&color=fff&size=256',
          'bio': 'Mobile App Architect & Cloud Specialist.',
          'statusMessage': 'Available for quick chat ☕',
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('ensureDefaultUsersSeeded error: $e');
    }
  }

  /// Real-time stream of registered users (excluding current user)
  Stream<List<UserModel>> streamAllUsers(String currentUserId) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        final data = doc.data();
        if (data['uid'] == currentUserId) continue;
        try {
          users.add(UserModel.fromDocument(doc));
        } catch (e) {
          debugPrint('Error parsing user doc ${doc.id}: $e');
        }
      }
      return users;
    });
  }

  /// Fetch registered users once
  Future<List<UserModel>> getAllUsers(String currentUserId) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final List<UserModel> users = [];
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        final data = doc.data();
        if (data['uid'] == currentUserId) continue;
        try {
          users.add(UserModel.fromDocument(doc));
        } catch (_) {}
      }
      return users;
    } catch (_) {
      return [];
    }
  }

  /// Get or create a 1-on-1 chat between two users
  Future<ChatModel> getOrCreateChat({
    required UserModel currentUser,
    required UserModel peerUser,
  }) async {
    final uids = [currentUser.uid, peerUser.uid]..sort();
    final chatId = '${uids[0]}_${uids[1]}';

    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await chatDocRef.get();

    if (docSnapshot.exists) {
      return ChatModel.fromDocument(docSnapshot);
    }

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
      'createdAt': FieldValue.serverTimestamp(),
    };

    await chatDocRef.set(newChatData);
    final createdDoc = await chatDocRef.get();
    return ChatModel.fromDocument(createdDoc);
  }

  /// Send message (supports both 1-on-1 chats and groups)
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    bool isGroup = false,
  }) async {
    if (text.trim().isEmpty) return;

    final collection = isGroup ? 'groups' : 'chats';
    final batch = _firestore.batch();

    final messageRef = _firestore
        .collection(collection)
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

    final parentRef = _firestore.collection(collection).doc(chatId);
    batch.update(parentRef, {
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

    final allMembers = {...memberIds, createdBy}.toList();
    final groupRef = _firestore.collection('groups').doc();

    final groupData = {
      'name': name.trim(),
      'groupName': name.trim(),
      'description': description.trim(),
      'iconUrl': iconUrl,
      'groupIcon': iconUrl,
      'createdBy': createdBy,
      'adminIds': [createdBy],
      'adminUids': [createdBy],
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

  /// Fetch call history for user
  Future<List<CallLogModel>> getCallLogs(String currentUserId) async {
    try {
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
    } catch (_) {
      return [];
    }
  }
}
