import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parsedTime = DateTime.now();
    final rawTime = data['timestamp'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    }

    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: parsedTime,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantDetails; // {uid: {name, photoUrl, email}}
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastSenderId;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId = '',
    this.unreadCount = 0,
  });

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? parsedTime;
    final rawTime = data['lastMessageTime'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
    }

    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails:
          Map<String, dynamic>.from(data['participantDetails'] ?? {}),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTime: parsedTime,
      lastSenderId: data['lastSenderId'] as String? ?? '',
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get the peer user's information for 1-on-1 chat
  Map<String, dynamic> getPeerDetails(String currentUserId) {
    for (var entry in participantDetails.entries) {
      if (entry.key != currentUserId) {
        if (entry.value is Map) {
          return Map<String, dynamic>.from(entry.value as Map);
        }
      }
    }
    return {'name': 'User', 'photoUrl': ''};
  }
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String createdBy;
  final List<String> adminIds;
  final List<String> members;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastSenderId;
  final DateTime? createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.iconUrl = '',
    required this.createdBy,
    this.adminIds = const [],
    required this.members,
    this.lastMessage = 'Group created',
    this.lastMessageTime,
    this.lastSenderId = '',
    this.createdAt,
  });

  factory GroupModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parsedLastTime;
    final rawLast = data['lastMessageTime'];
    if (rawLast is Timestamp) {
      parsedLastTime = rawLast.toDate();
    }

    DateTime? parsedCreated;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      parsedCreated = rawCreated.toDate();
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Group',
      description: data['description'] as String? ?? '',
      iconUrl: data['iconUrl'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] as String? ?? 'Group created',
      lastMessageTime: parsedLastTime,
      lastSenderId: data['lastSenderId'] as String? ?? '',
      createdAt: parsedCreated,
    );
  }
}

class CallLogModel {
  final String id;
  final String callerId;
  final String callerName;
  final String callerPhoto;
  final String receiverId;
  final String receiverName;
  final String receiverPhoto;
  final bool isVideo;
  final bool isMissed;
  final DateTime timestamp;
  final String duration;

  const CallLogModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerPhoto = '',
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto = '',
    this.isVideo = false,
    this.isMissed = false,
    required this.timestamp,
    this.duration = '0s',
  });

  factory CallLogModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parsedTime = DateTime.now();
    final rawTime = data['timestamp'];
    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    }

    return CallLogModel(
      id: doc.id,
      callerId: data['callerId'] as String? ?? '',
      callerName: data['callerName'] as String? ?? 'Unknown',
      callerPhoto: data['callerPhoto'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? 'Unknown',
      receiverPhoto: data['receiverPhoto'] as String? ?? '',
      isVideo: data['isVideo'] as bool? ?? false,
      isMissed: data['isMissed'] as bool? ?? false,
      timestamp: parsedTime,
      duration: data['duration'] as String? ?? '0s',
    );
  }
}

