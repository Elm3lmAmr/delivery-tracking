import 'package:go_router/go_router.dart';

import '../features/splash/presentation/pages/splash_screen.dart';
import '../features/auth/presentation/pages/role_selection_screen.dart';
import '../features/auth/presentation/pages/guard_login_screen.dart';
import '../features/auth/presentation/pages/phone_screen.dart';
import '../features/auth/presentation/pages/otp_screen.dart';
import '../features/auth/presentation/pages/register_screen.dart';
import '../features/delivery/presentation/pages/driver/home_screen.dart';
import '../features/delivery/presentation/pages/driver/new_delivery_screen.dart';
import '../features/delivery/presentation/pages/driver/qr_display_screen.dart';
import '../features/delivery/presentation/pages/guard/scanner_screen.dart';
import '../features/delivery/presentation/pages/guard/verify_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding/role', builder: (c, s) => const RoleSelectionScreen()),
    GoRoute(path: '/onboarding/phone', builder: (c, s) => const PhoneScreen()),
    GoRoute(path: '/onboarding/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/guard/login', builder: (c, s) => const GuardLoginScreen()),
    GoRoute(
      path: '/onboarding/otp',
      builder: (c, s) {
        final args = s.extra as OtpArguments?;
        // Fallback for missing args or phone (shouldn't happen)
        return OtpScreen(args: args ?? OtpArguments(phone: ''));
      },
    ),
    GoRoute(path: '/driver/home', builder: (c, s) => const DriverHomeScreen()),
    GoRoute(path: '/driver/new', builder: (c, s) => const NewDeliveryScreen()),
    GoRoute(
      path: '/driver/qr',
      builder: (c, s) => QrDisplayScreen(
        data: s.extra as Map<String, dynamic>? ?? const {},
      ),
    ),
    GoRoute(path: '/guard/scanner', builder: (c, s) => const GuardScannerScreen()),
    GoRoute(
      path: '/guard/verify', 
      builder: (c, s) => GuardVerifyScreen(
        deliveryData: s.extra as Map<String, dynamic>? ?? const {},
      ),
    ),
  ],
);
