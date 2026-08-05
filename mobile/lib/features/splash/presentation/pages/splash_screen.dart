import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      
      final apiClient = ApiClient();
      await apiClient.loadToken();

      if (!mounted) return;

      if (apiClient.hasToken) {
        try {
          final decodedToken = JwtDecoder.decode(apiClient.token!);
          final type = decodedToken['type']; // 'driver' or 'user' (guard)

          if (type == 'user') {
            context.go('/guard/scanner');
          } else {
            // Default to driver home if not user/guard
            context.go('/driver/home');
          }
        } catch (e) {
          // Token is invalid or expired
          await apiClient.clearToken();
          context.go('/onboarding/role');
        }
      } else {
        context.go('/onboarding/role');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('EDARA',
              style: TextStyle(color: kAccent, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: 4),
            ),
            SizedBox(height: 8),
            Text('Delivery Tracking',
              style: TextStyle(color: kMuted, fontSize: 14, letterSpacing: 2),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: kAccent, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
