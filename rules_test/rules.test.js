// Testes das regras do Firestore e do Storage contra os emuladores locais.
// Corre com: npm run emulators (dentro desta pasta).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { deleteObject, ref, uploadBytes } from 'firebase/storage';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-strk',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
});

after(() => env.cleanup());

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();

const habit = (overrides = {}) => ({
  id: 'h1',
  name: 'Beber água',
  icon: 'water',
  completedToday: true,
  streak: 3,
  lastCompletedDate: '2026-03-10',
  reminderEnabled: false,
  reminderHour: null,
  reminderMinute: null,
  lastUpdated: serverTimestamp(),
  ...overrides,
});

describe('users/{uid}', () => {
  test('o dono pode guardar campos conhecidos', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'users/alice'), { lastOpenDate: '2026-03-10' }),
    );
  });

  test('outro utilizador não lê nem escreve', async () => {
    await assertFails(
      setDoc(doc(bob(), 'users/alice'), { lastOpenDate: '2026-03-10' }),
    );
  });

  test('campos desconhecidos são recusados', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice'), { isAdmin: true }));
  });

  test('um campo antigo já existente não bloqueia updates', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/alice'), { legacy: 1 }),
    );
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users/alice'),
        { fcmToken: 'abc' },
        { merge: true },
      ),
    );
  });

  test('aniversário tem de ser uma data YYYY-MM-DD', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice'), { birthday: 'ontem' }),
    );
  });
});

describe('users/{uid}/habits/{habitId}', () => {
  test('hábito válido é aceite', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice/habits/h1'), habit()));
  });

  test('streak negativo é recusado', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice/habits/h1'), habit({ streak: -1 })),
    );
  });

  test('o id tem de coincidir com o documento', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice/habits/h1'), habit({ id: 'outro' })),
    );
  });

  test('campos extra são recusados', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice/habits/h1'), habit({ extra: 'x' })),
    );
  });

  test('nome vazio é recusado', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice/habits/h1'), habit({ name: '' })),
    );
  });

  test('lastCompletedDate pode ser null', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), 'users/alice/habits/h1'),
        habit({ lastCompletedDate: null, streak: 0 }),
      ),
    );
  });

  test('outro utilizador não pode apagar', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users/alice/habits/h1'), { id: 'h1' }),
    );
    await assertFails(deleteDoc(doc(bob(), 'users/alice/habits/h1')));
    await assertSucceeds(deleteDoc(doc(alice(), 'users/alice/habits/h1')));
  });
});

describe('logs', () => {
  const path = 'users/alice/habits/h1/logs/2026-03-10';

  test('log válido é aceite', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), path), { completed: true, date: '2026-03-10' }),
    );
  });

  test('a data tem de ser igual ao id do documento', async () => {
    await assertFails(
      setDoc(doc(alice(), path), { completed: true, date: '2026-03-11' }),
    );
  });

  test('o id tem de ser uma data', async () => {
    await assertFails(
      setDoc(doc(alice(), 'users/alice/habits/h1/logs/lixo'), {
        completed: true,
        date: 'lixo',
      }),
    );
  });
});

describe('storage', () => {
  const storage = (uid) => env.authenticatedContext(uid).storage();
  const png = new Uint8Array([137, 80, 78, 71]);

  test('o dono pode carregar uma foto', async () => {
    await assertSucceeds(
      uploadBytes(ref(storage('alice'), 'users/alice/profile_photo_1.png'), png, {
        contentType: 'image/png',
      }),
    );
  });

  test('nomes ou tipos inesperados são recusados', async () => {
    await assertFails(
      uploadBytes(ref(storage('alice'), 'users/alice/script.html'), png, {
        contentType: 'text/html',
      }),
    );
  });

  test('o dono pode apagar as suas fotos, outros não', async () => {
    const path = 'users/alice/profile_photo_1.png';
    await uploadBytes(ref(storage('alice'), path), png, {
      contentType: 'image/png',
    });
    await assertFails(deleteObject(ref(storage('bob'), path)));
    await assertSucceeds(deleteObject(ref(storage('alice'), path)));
  });
});
