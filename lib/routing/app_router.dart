import 'package:go_router/go_router.dart';

import '../screens/address/address_form_screen.dart';
import '../screens/address/address_list_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/legal/privacy_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/payment_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/delete_account_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../state/auth_controller.dart';

const List<String> _privatePrefixes = [
  '/cart',
  '/checkout',
  '/addresses',
  '/orders',
  '/profile',
  '/change-password',
  '/delete-account',
];

bool _isPrivate(String path) {
  return _privatePrefixes.any(
    (prefix) => path == prefix || path.startsWith('$prefix/'),
  );
}

GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final loggedIn = auth.isLoggedIn;
      final isAuthPage = path == '/login' || path == '/register';

      if (!loggedIn && _isPrivate(path)) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (loggedIn && isAuthPage) {
        final from = state.uri.queryParameters['from'];
        final safe =
            from != null &&
            from.startsWith('/') &&
            !from.startsWith('/login') &&
            !from.startsWith('/register');
        return safe ? from : '/home';
      }

      return null;
    },
    routes: [
      _screen('/splash', (context, state) => const SplashScreen()),
      _screen('/onboarding', (context, state) => const OnboardingScreen()),
      _screen('/login', (context, state) => const LoginScreen()),
      _screen('/register', (context, state) => const RegisterScreen()),
      _screen(
        '/forgot-password',
        (context, state) => const ForgotPasswordScreen(),
      ),
      _screen(
        '/reset-password',
        (context, state) => const ResetPasswordScreen(),
      ),
      _screen('/home', (context, state) => const HomeScreen()),
      _screen('/search', (context, state) => const SearchScreen()),
      _screen(
        '/product/:id',
        (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      _screen('/privacy', (context, state) => const PrivacyScreen()),
      _screen('/cart', (context, state) => const CartScreen()),
      _screen('/checkout', (context, state) => const CheckoutScreen()),
      _screen('/addresses', (context, state) => const AddressListScreen()),
      _screen('/addresses/new', (context, state) => const AddressFormScreen()),
      _screen(
        '/addresses/:id/edit',
        (context, state) =>
            AddressFormScreen(addressId: state.pathParameters['id']),
      ),
      _screen('/orders', (context, state) => const OrdersScreen()),
      _screen(
        '/orders/:id',
        (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      _screen(
        '/orders/:id/payment',
        (context, state) => PaymentScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      _screen('/profile', (context, state) => const ProfileScreen()),
      _screen('/profile/edit', (context, state) => const ProfileEditScreen()),
      _screen(
        '/change-password',
        (context, state) => const ChangePasswordScreen(),
      ),
      _screen(
        '/delete-account',
        (context, state) => const DeleteAccountScreen(),
      ),
    ],
  );
}

GoRoute _screen(String path, GoRouterWidgetBuilder builder) {
  return GoRoute(path: path, builder: builder);
}
