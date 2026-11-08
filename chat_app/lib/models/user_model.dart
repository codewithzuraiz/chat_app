import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettings {
  final String lastSeen; // 'everyone', 'contacts', 'nobody'
  final String profilePhoto; // 'everyone', 'contacts', 'nobody'
  final String bio; // 'everyone', 'contacts', 'nobody'
  final bool readReceipts;

  const PrivacySettings({
    this.lastSeen = 'everyone',
    this.profilePhoto = 'everyone',
    this.bio = 'everyone',
    this.readReceipts = true,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PrivacySettings();
    return PrivacySettings(
      lastSeen: map['lastSeen'] as String? ?? 'everyone',
      profilePhoto: map['profilePhoto'] as String? ?? 'everyone',
      bio: map['bio'] as String? ?? 'everyone',
      readReceipts: map['readReceipts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastSeen': lastSeen,
      'profilePhoto': profilePhoto,
      'bio': bio,
      'readReceipts': readReceipts,
    };
  }

  PrivacySettings copyWith({
    String? lastSeen,
    String? profilePhoto,
    String? bio,
    bool? readReceipts,
  }) {
    return PrivacySettings(
      lastSeen: lastSeen ?? this.lastSeen,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      readReceipts: readReceipts ?? this.readReceipts,
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String photoUrl;
  final String coverUrl;
  final String bio;
  final String statusMessage;
  final bool isOnline;
  final DateTime? lastSeen;
  final PrivacySettings privacy;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    this.photoUrl = '',
    this.coverUrl = '',
    this.bio = '',
    this.statusMessage = 'Hey there! I am using ChatApp',
    this.isOnline = false,
    this.lastSeen,
    this.privacy = const PrivacySettings(),
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(doc.id, data);
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parsedLastSeen;
    final rawLastSeen = data['lastSeen'];
    if (rawLastSeen is Timestamp) {
      parsedLastSeen = rawLastSeen.toDate();
    } else if (rawLastSeen is int) {
      parsedLastSeen = DateTime.fromMillisecondsSinceEpoch(rawLastSeen);
    }

    return UserModel(
      uid: id,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      statusMessage: data['statusMessage'] as String? ?? 'Hey there! I am using ChatApp',
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: parsedLastSeen,
      privacy: PrivacySettings.fromMap(data['privacy'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'statusMessage': statusMessage,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'privacy': privacy.toMap(),
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? coverUrl,
    String? bio,
    String? statusMessage,
    bool? isOnline,
    DateTime? lastSeen,
    PrivacySettings? privacy,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      statusMessage: statusMessage ?? this.statusMessage,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      privacy: privacy ?? this.privacy,
    );
  }
}

