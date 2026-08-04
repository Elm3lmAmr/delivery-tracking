import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/server_config_dialog.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Edara Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_input_antenna),
            tooltip: 'Server IP Settings',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.delivery_dining, size: 80, color: kAccent),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Edara',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'How are you using the app today?',
                style: TextStyle(fontSize: 16, color: kMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/onboarding/register');
                },
                icon: const Icon(Icons.person_add, size: 24),
                label: const Text('Register as Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/onboarding/phone');
                },
                icon: const Icon(Icons.login, size: 24),
                label: const Text('Login as Driver'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/guard/login');
                },
                icon: const Icon(Icons.security, size: 24),
                label: const Text('I am a Security Guard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showServerConfigDialog(context),
                icon: const Icon(Icons.settings_input_antenna, color: kAccent),
                label: const Text('Configure Server IP Address', style: TextStyle(color: kAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
