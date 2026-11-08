import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    } catch (e) {
      return null;
    }
  }

  /// Upload an image to Firebase Storage and return its public download URL
  Future<String> uploadImage({
    required File file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Update user profile details
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String bio,
    required String statusMessage,
    File? newProfileImage,
    File? newCoverImage,
    String? currentPhotoUrl,
    String? currentCoverUrl,
  }) async {
    String photoUrl = currentPhotoUrl ?? '';
    String coverUrl = currentCoverUrl ?? '';

    // Upload profile image if selected
    if (newProfileImage != null) {
      final path = 'users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      photoUrl = await uploadImage(file: newProfileImage, path: path);
    }

    // Upload cover image if selected
    if (newCoverImage != null) {
      final path = 'users/$uid/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      coverUrl = await uploadImage(file: newCoverImage, path: path);
    }

    // Update Firebase Auth user profile
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      if (currentUser.displayName != name) {
        await currentUser.updateDisplayName(name.trim());
      }
      if (photoUrl.isNotEmpty && currentUser.photoURL != photoUrl) {
        await currentUser.updatePhotoURL(photoUrl);
      }
      await currentUser.reload();
    }

    // Update Cloud Firestore document
    await _firestore.collection('users').doc(uid).set({
      'name': name.trim(),
      'bio': bio.trim(),
      'statusMessage': statusMessage.trim(),
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update privacy preferences
  Future<void> updatePrivacySettings({
    required String uid,
    required PrivacySettings privacy,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'privacy': privacy.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

