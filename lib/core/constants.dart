import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color ivory = Color(0xFFF7F2E9);
  static const Color surface = Color(0xFFFFFCF6);
  static const Color forest = Color(0xFF223A2D);
  static const Color terracotta = Color(0xFFC06B4E);
  static const Color ink = Color(0xFF1B1A17);
  static const Color muted = Color(0xFF6F6A60);
  static const Color line = Color(0xFFE3DACB);
  static const Color success = Color(0xFF3D6B4F);
  static const Color danger = Color(0xFFA84532);
  static const Color warning = Color(0xFFB07A2A);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20;
}

class AppRadius {
  AppRadius._();

  static const double small = 4;
  static const double medium = 12;
  static const double pill = 999;
}

class AppConstants {
  AppConstants._();

  static const String appName = 'RnZ Store';
  static const String prefPrefix = 'rnz.v1.';
  static const String seedVersion = '1';

  static const int maxAddresses = 5;
  static const int loginMaxAttempts = 5;
  static const Duration loginLockout = Duration(minutes: 15);
  static const Duration resetCodeLifetime = Duration(minutes: 30);
  static const Duration paymentWindow = Duration(hours: 24);
  static const Duration autoCompleteAfter = Duration(days: 7);
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration undoWindow = Duration(seconds: 5);
  static const int productsPerPage = 20;

  static const int maxProofBytes = 5 * 1024 * 1024;
  static const int proofMaxDimension = 1600;
  static const int proofTargetBytes = 1024 * 1024;

  static const String storeWhatsApp = '6281234567890';
  static const List<String> couriers = [
    'JNE',
    'J&T',
    'SiCepat',
    'Pos Indonesia',
    'Lainnya',
  ];
}

class AppAssets {
  AppAssets._();

  static const String hero = 'assets/images/products/rnz_05.jpg';

  static const List<String> productImages = [
    'assets/images/products/rnz_01.jpg',
    'assets/images/products/rnz_02.jpg',
    'assets/images/products/rnz_03.jpg',
    'assets/images/products/rnz_04.jpg',
    'assets/images/products/rnz_05.jpg',
    'assets/images/products/rnz_06.jpg',
    'assets/images/products/rnz_07.jpg',
    'assets/images/products/rnz_08.jpg',
    'assets/images/products/rnz_09.jpg',
    'assets/images/products/rnz_10.jpg',
    'assets/images/products/rnz_11.jpg',
    'assets/images/products/rnz_12.jpg',
    'assets/images/products/rnz_13.jpg',
    'assets/images/products/rnz_14.jpg',
  ];
}
