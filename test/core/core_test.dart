import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rnz_store/core/formatters.dart';
import 'package:rnz_store/core/password_hasher.dart';
import 'package:rnz_store/core/result.dart';
import 'package:rnz_store/core/validators.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  test('formatRupiah uses Indonesian thousands', () {
    expect(formatRupiah(1250000), 'Rp 1.250.000');
  });

  test('formatDateWib uses Indonesian month and WIB', () {
    expect(
      formatDateWib(DateTime(2026, 11, 14, 14, 30)),
      '14 Nov 2026, 14.30 WIB',
    );
  });

  test('formatCountdown shows hours and expiry', () {
    expect(formatCountdown(const Duration(hours: 1, minutes: 30)), '01:30:00');
    expect(formatCountdown(Duration.zero), 'Kedaluwarsa');
  });

  test('validators accept Indonesian phone variants', () {
    expect(Validators.phone('081234567890'), isNull);
    expect(Validators.phone('+6281234567890'), isNull);
    expect(Validators.phone('12345'), isNotNull);
  });

  test('password requires 8 chars, a letter, and a digit', () {
    expect(Validators.password('Hijab1234'), isNull);
    expect(Validators.password('hijabbbb'), isNotNull);
    expect(Validators.password('12345678'), isNotNull);
  });

  test('email is trimmed and postal code is five digits', () {
    expect(Validators.email('  Aisyah@Example.com '), isNull);
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.postalCode('78111'), isNull);
    expect(Validators.postalCode('7811'), isNotNull);
    expect(Validators.confirmPassword('Hijab1234', 'Hijab1234'), isNull);
    expect(Validators.confirmPassword('Hijab1235', 'Hijab1234'), isNotNull);
  });

  test('password hasher verifies only the right password', () {
    final salt = PasswordHasher.newSalt();
    final hash = PasswordHasher.hash('Hijab1234', salt);
    expect(PasswordHasher.verify('Hijab1234', salt, hash), isTrue);
    expect(PasswordHasher.verify('Wrong1234', salt, hash), isFalse);
  });

  test('AppResult failure keeps field errors', () {
    final r = AppResult<int>.fail(
      const AppError(
        code: 'validation',
        message: 'x',
        fields: {'email': 'Terdaftar'},
      ),
    );
    expect(r.isOk, isFalse);
    expect(r.error!.fields['email'], 'Terdaftar');
  });
}
