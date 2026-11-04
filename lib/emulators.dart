import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Liga a app aos emuladores locais do Firebase em vez do projeto real.
/// Só se ativa ao compilar com `--dart-define=USE_EMULATORS=true`, por isso
/// uma build normal nunca aponta para o teu computador. Arranca-os com:
///   firebase emulators:start --only auth,firestore,storage
const useEmulators = bool.fromEnvironment('USE_EMULATORS');

Future<void> connectToEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
