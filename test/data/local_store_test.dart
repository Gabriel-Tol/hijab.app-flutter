import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/core/password_hasher.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('seed creates demo account and catalog once', () async {
    final store = await LocalStore.open();
    await store.seedIfNeeded();
    await store.seedIfNeeded();
    expect(store.list('users').length, 1);
    expect(store.list('categories').length, 5);
    expect(store.list('products').length, 21);
    final user = User.fromJson(
      store.list('users').single as Map<String, dynamic>,
    );
    expect(
      PasswordHasher.verify('Hijab1234', user.passwordSalt, user.passwordHash),
      isTrue,
    );
  });

  test(
    'seed includes 4 payment methods, 4 shipping rates, and 2 demo orders',
    () async {
      final store = await LocalStore.open();
      await store.seedIfNeeded();
      expect(store.list('payment_methods').length, 4);
      expect(store.list('shipping_rates').length, 4);
      expect(store.list('orders').length, 2);
    },
  );

  test('corrupt JSON throws StoreCorruptException', () async {
    SharedPreferences.setMockInitialValues({'rnz.v1.products': '{not json'});
    final store = await LocalStore.open();
    expect(() => store.list('products'), throwsA(isA<StoreCorruptException>()));
  });

  test('clearAll removes every rnz key but keeps foreign keys', () async {
    SharedPreferences.setMockInitialValues({'other': 'keep'});
    final store = await LocalStore.open();
    await store.write('products', []);
    await store.clearAll();
    expect(store.list('products'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('other'), 'keep');
  });

  test('session, onboarding, and proof values persist', () async {
    final store = await LocalStore.open();
    await store.setSessionUserId('u1');
    await store.setOnboardingSeen();
    await store.setProof('proof.o1.p1', 'data:image/jpeg;base64,AAA');

    final reopened = await LocalStore.open();
    expect(reopened.sessionUserId, 'u1');
    expect(reopened.onboardingSeen, isTrue);
    expect(reopened.proof('proof.o1.p1'), 'data:image/jpeg;base64,AAA');

    await reopened.setSessionUserId(null);
    await reopened.removeProof('proof.o1.p1');
    expect(reopened.sessionUserId, isNull);
    expect(reopened.proof('proof.o1.p1'), isNull);
  });
}
