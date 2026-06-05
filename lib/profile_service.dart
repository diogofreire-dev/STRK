import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ImagePicker _picker = ImagePicker();

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<XFile?> pickProfilePhoto({
    ImageSource source = ImageSource.gallery,
  }) {
    if (kIsWeb && source == ImageSource.camera) {
      source = ImageSource.gallery;
    }
    return _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
  }

  static Future<String> uploadProfilePhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    final extension = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final metadata = SettableMetadata(
      contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
    );
    final ref = _storage.ref('users/$_uid/profile_photo_$timestamp.$extension');
    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  static Future<void> saveProfilePhotoUrl(String url) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updatePhotoURL(url);
    await _saveUserDocument({'photoUrl': url});
    await user.reload();
  }

  static Future<void> updateDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await _saveUserDocument({'displayName': name});
    await user.reload();
  }

  static Future<void> removeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updatePhotoURL(null);
    await _saveUserDocument({'photoUrl': FieldValue.delete()});
    await user.reload();
  }

  static Future<void> _saveUserDocument(Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .set(data, SetOptions(merge: true));
  }
}
