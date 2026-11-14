import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/core/password_hasher.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/address.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const AddressDraft _draft = AddressDraft(
  label: 'Rumah',
  recipientName: 'Aisyah',
  recipientPhone: '081298765432',
  province: 'Kalimantan Barat',
  city: 'Pontianak',
  district: 'Pontianak Kota',
  addressLine: 'Jl. Merdeka No. 5',
  postalCode: '78112',
);

const AddressDraft _emptyDraft = AddressDraft(
  label: '',
  recipientName: '',
  recipientPhone: '',
  province: '',
  city: '',
  district: '',
  addressLine: '',
  postalCode: '',
);

void main() {
  final t0 = DateTime(2026, 11, 14, 9);
  late LocalStore store;
  late AuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    repo = AuthRepository(store);
  });

  test('register creates a hashed user, default address, and session', () async {
    final result = await repo.register(
      name: 'Aisyah',
      email: 'AISYAH@example.com',
      phone: '+628111222333',
      password: 'Hijab1234',
      address: _draft,
      now: t0,
    );

    expect(result.isOk, isTrue);
    expect(store.sessionUserId, result.value!.id);
    expect(result.value!.email, 'aisyah@example.com');
    expect(result.value!.phone, '08111222333');
    expect(
      PasswordHasher.verify(
        'Hijab1234',
        result.value!.passwordSalt,
        result.value!.passwordHash,
      ),
      isTrue,
    );
    final addresses = repo.addressesFor(result.value!.id);
    expect(addresses.single.isDefault, isTrue);
    expect(addresses.single.city, 'Pontianak');
    expect(store.list('users').length, 2);
  });

  test('register rejects duplicate email and phone and invalid fields', () async {
    final emailDuplicate = await repo.register(
      name: 'Aisyah',
      email: ' NADIA@RNZSTORE.ID ',
      phone: '08111222333',
      password: 'Hijab1234',
      address: _draft,
    );
    expect(emailDuplicate.error!.code, 'validation');
    expect(emailDuplicate.error!.fields['email'], 'Email sudah terdaftar');

    final phoneDuplicate = await repo.register(
      name: 'Aisyah',
      email: 'aisyah@example.com',
      phone: '+6281234567890',
      password: 'Hijab1234',
      address: _draft,
    );
    expect(phoneDuplicate.error!.fields['phone'], 'Nomor telepon sudah terdaftar');

    final invalid = await repo.register(
      name: 'A',
      email: 'not-an-email',
      phone: '123',
      password: 'abc',
      address: _emptyDraft,
    );
    expect(
      invalid.error!.fields.keys,
      containsAll([
        'name',
        'email',
        'phone',
        'password',
        'label',
        'recipientName',
        'recipientPhone',
        'province',
        'city',
        'district',
        'addressLine',
        'postalCode',
      ]),
    );
    expect(store.list('users').length, 1);
    expect(store.sessionUserId, isNull);
  });

  test('five failed logins lock the account for 15 minutes', () async {
    for (var i = 0; i < 5; i++) {
      final failure = await repo.login(
        email: SeedData.demoEmail,
        password: 'Wrong1234',
        now: t0,
      );
      expect(failure.isOk, isFalse);
    }

    final locked = await repo.login(
      email: SeedData.demoEmail,
      password: SeedData.demoPassword,
      now: t0.add(const Duration(minutes: 5)),
    );
    expect(locked.error!.code, 'locked');
    expect(locked.error!.message, contains('menit'));

    final ok = await repo.login(
      email: SeedData.demoEmail,
      password: SeedData.demoPassword,
      now: t0.add(const Duration(minutes: 16)),
    );
    expect(ok.isOk, isTrue);
    expect(store.sessionUserId, ok.value!.id);
  });

  test('reset code expires after 30 minutes and is single use', () async {
    final code = (await repo.requestResetCode(
      SeedData.demoEmail,
      now: t0,
    )).value!;
    expect(code, matches(RegExp(r'^\d{6}$')));

    final wrongCode = code == '000000' ? '111111' : '000000';
    final wrong = await repo.resetPassword(
      email: SeedData.demoEmail,
      code: wrongCode,
      newPassword: 'Baru1234',
      now: t0.add(const Duration(minutes: 5)),
    );
    expect(wrong.error!.code, 'invalid_code');

    final expired = await repo.resetPassword(
      email: SeedData.demoEmail,
      code: code,
      newPassword: 'Baru1234',
      now: t0.add(const Duration(minutes: 31)),
    );
    expect(expired.error!.code, 'expired');

    final ok = await repo.resetPassword(
      email: SeedData.demoEmail,
      code: code,
      newPassword: 'Baru1234',
      now: t0.add(const Duration(minutes: 10)),
    );
    expect(ok.isOk, isTrue);

    final reused = await repo.resetPassword(
      email: SeedData.demoEmail,
      code: code,
      newPassword: 'Lagi1234',
      now: t0.add(const Duration(minutes: 11)),
    );
    expect(reused.error!.code, 'used');

    final oldPassword = await repo.login(
      email: SeedData.demoEmail,
      password: 'Hijab1234',
      now: t0.add(const Duration(minutes: 12)),
    );
    expect(oldPassword.isOk, isFalse);
    final newPassword = await repo.login(
      email: SeedData.demoEmail,
      password: 'Baru1234',
      now: t0.add(const Duration(minutes: 12)),
    );
    expect(newPassword.isOk, isTrue);
  });

  test('unknown email returns ok with a null code', () async {
    final result = await repo.requestResetCode('tidak@ada.id', now: t0);
    expect(result.isOk, isTrue);
    expect(result.value, isNull);
  });

  test('logout clears the session', () async {
    final login = await repo.login(
      email: SeedData.demoEmail,
      password: SeedData.demoPassword,
      now: t0,
    );
    expect(repo.currentUser()!.id, login.value!.id);

    await repo.logout();
    expect(store.sessionUserId, isNull);
    expect(repo.currentUser(), isNull);
  });
}
