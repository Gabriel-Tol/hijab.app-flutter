import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'data/api_client.dart';
import 'data/local_store.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/checkout_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'routing/app_router.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';
import 'state/order_controller.dart';

class RnzApp extends StatefulWidget {
  const RnzApp({
    super.key,
    required this.store,
    required this.authRepository,
    required this.profileRepository,
    required this.catalogRepository,
    required this.cartRepository,
    required this.checkoutRepository,
    required this.orderRepository,
    required this.authController,
    required this.catalogController,
    required this.cartController,
    required this.orderController,
  });

  final LocalStore store;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final CatalogRepository catalogRepository;
  final CartRepository cartRepository;
  final CheckoutRepository checkoutRepository;
  final OrderRepository orderRepository;
  final AuthController authController;
  final CatalogController catalogController;
  final CartController cartController;
  final OrderController orderController;

  static RnzApp create(LocalStore store) {
    final apiClient = ApiClient(store: store);
    final catalogRepository = CatalogRepository(store, apiClient: apiClient);
    final profileRepository = ProfileRepository(store);
    final cartRepository = CartRepository(store, catalogRepository);
    final checkoutRepository = CheckoutRepository(
      store,
      cartRepository,
      catalogRepository,
      apiClient: apiClient,
    );
    final orderRepository = OrderRepository(
      store,
      cartRepository,
      profileRepository,
      checkoutRepository,
      apiClient: apiClient,
    );
    final authRepository = AuthRepository(store);
    final authController = AuthController(authRepository, profileRepository);
    final catalogController = CatalogController(catalogRepository);
    final cartController = CartController(cartRepository, authController);
    final orderController = OrderController(
      orderRepository,
      authController,
      cartController,
    );

    return RnzApp(
      store: store,
      authRepository: authRepository,
      profileRepository: profileRepository,
      catalogRepository: catalogRepository,
      cartRepository: cartRepository,
      checkoutRepository: checkoutRepository,
      orderRepository: orderRepository,
      authController: authController,
      catalogController: catalogController,
      cartController: cartController,
      orderController: orderController,
    );
  }

  @override
  State<RnzApp> createState() => _RnzAppState();
}

class _RnzAppState extends State<RnzApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(widget.authController);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStore>.value(value: widget.store),
        Provider<AuthRepository>.value(value: widget.authRepository),
        Provider<ProfileRepository>.value(value: widget.profileRepository),
        Provider<CatalogRepository>.value(value: widget.catalogRepository),
        Provider<CartRepository>.value(value: widget.cartRepository),
        Provider<CheckoutRepository>.value(value: widget.checkoutRepository),
        Provider<OrderRepository>.value(value: widget.orderRepository),
        ChangeNotifierProvider<AuthController>.value(
          value: widget.authController,
        ),
        ChangeNotifierProvider<CatalogController>.value(
          value: widget.catalogController,
        ),
        ChangeNotifierProvider<CartController>.value(
          value: widget.cartController,
        ),
        ChangeNotifierProvider<OrderController>.value(
          value: widget.orderController,
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
