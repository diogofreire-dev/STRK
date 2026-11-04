import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'habit_service.dart';
import 'notifications_service.dart';

/// Operações sobre a conta inteira: terminar sessão e eliminar a conta com
/// todos os dados (exigido pela App Store e pelo RGPD).
class AccountService {
  static final _db = FirebaseFirestore.instance;

  static bool get usesPassword =>
      FirebaseAuth.instance.currentUser?.providerData.any(
        (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  static Future<void> signOut() async {
    // O token FCM tem de sair antes do signOut: depois disso já não temos
    // permissão para escrever no documento do utilizador.
    await NotificationsService.removeFcmTokenForCurrentUser();
    if (!kIsWeb) await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// O Firebase só deixa eliminar a conta com um login recente. Pedimos
  /// sempre a confirmação ANTES de apagar os dados, para não ficarmos com
  /// os dados apagados e a conta ainda viva se o `user.delete()` falhar.
  static Future<void> reauthenticate({String? password}) async {
    final user = FirebaseAuth.instance.currentUser!;
    if (usesPassword) {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password!),
      );
    } else if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
    } else {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }
  }

  /// Apaga fotos, hábitos com os respetivos logs, o documento do utilizador
  /// e, por fim, a própria conta. Chamar só depois de [reauthenticate].
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userRef = _db.collection('users').doc(user.uid);

    final photos = await FirebaseStorage.instance
        .ref('users/${user.uid}')
        .listAll();
    await Future.wait(photos.items.map((ref) => ref.delete()));

    final habits = await userRef.collection('habits').get();
    for (final habit in habits.docs) {
      await HabitService.deleteHabit(habit.id);
    }
    await userRef.delete();

    if (!kIsWeb) await GoogleSignIn.instance.signOut();
    await user.delete();
  }
}
