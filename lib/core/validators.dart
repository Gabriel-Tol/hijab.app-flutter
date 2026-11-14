class Validators {
  Validators._();

  static String? required(String? value, [String message = 'Wajib diisi']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static String normalizePhone(String value) {
    var digits = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+62')) {
      digits = '0${digits.substring(3)}';
    } else if (digits.startsWith('62')) {
      digits = '0${digits.substring(2)}';
    }
    return digits;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nama wajib diisi';
    if (v.length < 2) return 'Nama minimal 2 karakter';
    if (v.length > 100) return 'Nama maksimal 100 karakter';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email wajib diisi';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    return valid ? null : 'Format email tidak valid';
  }

  static String? phone(String? value) {
    final v = normalizePhone(value ?? '');
    if (v.isEmpty) return 'Nomor telepon wajib diisi';
    final valid = RegExp(r'^08[0-9]{7,13}$').hasMatch(v);
    return valid ? null : 'Nomor telepon tidak valid';
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
      return 'Kata sandi harus berisi huruf dan angka';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != original) return 'Konfirmasi kata sandi tidak sama';
    return null;
  }

  static String? postalCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Kode pos wajib diisi';
    if (!RegExp(r'^\d{5}$').hasMatch(v)) return 'Kode pos harus 5 digit';
    return null;
  }
}
