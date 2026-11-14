import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/address.dart';
import 'package:rnz_store/data/models/order.dart';
import 'package:rnz_store/data/models/user.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

AddressDraft _draft([String label = 'Rumah']) {
  return AddressDraft(
    label: label,
    recipientName: 'Nadia Putri',
    recipientPhone: '081234567890',
    province: 'Kalimantan Barat',
    city: 'Pontianak',
    district: 'Pontianak Kota',
    addressLine: 'Jl. Gajahmada No. 12',
    postalCode: '78111',
  );
}

void main() {
  final t0 = DateTime(2026, 11, 14, 9);
  late LocalStore store;
  late ProfileRepository profile;
  late AuthRepository auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    profile = ProfileRepository(store);
    auth = AuthRepository(store);
  });

  test('first address becomes default and the sixth is rejected', () async {
    await store.setSessionUserId('u-demo');
    for (final address in profile.addresses('u-demo')) {
      await profile.deleteAddress('u-demo', address.id);
    }
    expect(profile.addresses('u-demo'), isEmpty);

    final first = await profile.addAddress('u-demo', _draft());
    expect(first.isOk, isTrue);
    expect(first.value!.isDefault, isTrue);

    for (var index = 2; index <= 5; index++) {
      final added = await profile.addAddress(
        'u-demo',
        _draft('Alamat $index'),
      );
      expect(added.isOk, isTrue);
    }

    final sixth = await profile.addAddress('u-demo', _draft('Alamat 6'));
    expect(sixth.error!.code, 'address_limit');
    expect(profile.addresses('u-demo').length, 5);
    expect(
      profile.addresses('u-demo').where((address) => address.isDefault).length,
      1,
    );
  });

  test('deleting the default promotes another address', () async {
    await store.setSessionUserId('u-demo');
    final defaultId = profile.defaultAddress('u-demo')!.id;

    final result = await profile.deleteAddress('u-demo', defaultId);
    expect(result.isOk, isTrue);

    final promoted = profile.defaultAddress('u-demo');
    expect(promoted, isNotNull);
    expect(promoted!.id, isNot(defaultId));
    expect(
      profile.addresses('u-demo').where((address) => address.isDefault).length,
      1,
    );
  });

  test('profile update rejects another user phone and saves valid data', () async {
    await auth.register(
      name: 'Aisyah',
      email: 'aisyah@example.com',
      phone: '08111222333',
      password: 'Hijab1234',
      address: _draft('Kantor'),
    );
    await store.setSessionUserId('u-demo');

    final clash = await profile.updateProfile(
      name: 'Nadia Putri',
      phone: '08111222333',
    );
    expect(clash.error!.fields['phone'], 'Nomor telepon sudah terdaftar');

    final ok = await profile.updateProfile(
      name: 'Nadia P.',
      phone: '+6281234567890',
    );
    expect(ok.isOk, isTrue);
    expect(ok.value!.phone, '081234567890');
    expect(profile.currentUser()!.name, 'Nadia P.');
  });

  test('changing password requires the current password', () async {
    await store.setSessionUserId('u-demo');

    final wrong = await profile.changePassword(
      currentPassword: 'Wrong1234',
      newPassword: 'Baru1234',
    );
    expect(wrong.error!.code, 'invalid_password');

    final same = await profile.changePassword(
      currentPassword: 'Hijab1234',
      newPassword: 'Hijab1234',
    );
    expect(same.error!.code, 'validation');

    final ok = await profile.changePassword(
      currentPassword: 'Hijab1234',
      newPassword: 'Baru1234',
    );
    expect(ok.isOk, isTrue);

    final login = await auth.login(
      email: SeedData.demoEmail,
      password: 'Baru1234',
    );
    expect(login.isOk, isTrue);
  });

  test('delete account is blocked while an order is active', () async {
    await store.setSessionUserId('u-demo');

    final wrong = await profile.deleteAccount(
      password: 'Wrong1234',
      now: t0,
    );
    expect(wrong.error!.code, 'invalid_password');

    final blocked = await profile.deleteAccount(
      password: 'Hijab1234',
      now: t0,
    );
    expect(blocked.error!.code, 'active_orders');
    expect(store.sessionUserId, 'u-demo');
  });

  test('delete account anonymizes the user, addresses, and order snapshots', () async {
    await store.setSessionUserId('u-demo');
    final rawOrders = store
        .list('orders')
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    for (final order in rawOrders) {
      order['status'] = 'completed';
      order['completedAt'] = t0.toIso8601String();
    }
    await store.write('orders', rawOrders);

    final result = await profile.deleteAccount(
      password: 'Hijab1234',
      now: t0,
    );
    expect(result.isOk, isTrue);
    expect(store.sessionUserId, isNull);

    final user = User.fromJson(
      store.list('users').first as Map<String, dynamic>,
    );
    expect(user.name, 'Pelanggan');
    expect(user.status, 'deleted');
    expect(user.email, 'deleted-u-demo@rnz.local');
    expect(store.list('addresses'), isEmpty);

    final orders = store
        .list('orders')
        .map((raw) => Order.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
    expect(orders.length, 2);
    expect(orders.first.addressSnapshot['recipientName'], 'Dianonimkan');
    expect(orders.first.addressSnapshot['addressLine'], 'Dianonimkan');
    expect(orders.first.items.single.productName, isNotEmpty);
    expect(orders.first.total, 140000);
  });
}
