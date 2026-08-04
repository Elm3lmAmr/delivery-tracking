import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'otp_screen.dart'; // Add this for OtpArguments

import '../../../../core/api/server_config_dialog.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController(text: '+20 ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_input_antenna),
            tooltip: 'Server IP Settings',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 68, height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.phone_iphone, color: kAccent, size: 32),
            ),
            const SizedBox(height: 24),
            const Text('Enter your phone',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text("One-time code, then you're in.",
              style: TextStyle(color: kMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
              decoration: const InputDecoration(labelText: 'Mobile number'),
            ),
            const SizedBox(height: 24),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthOtpSent) {
                  final phone = _controller.text.replaceAll(RegExp(r'\s+'), '');
                  context.push('/onboarding/otp', extra: OtpArguments(phone: phone, isRegistration: false));
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : () {
                    // Strip whitespace so "+20 1118196999" == "+201118196999"
                    final phone = _controller.text.replaceAll(RegExp(r'\s+'), '');
                    context.read<AuthBloc>().add(RequestOtpEvent(phone));
                  },
                  child: Text(isLoading ? 'Sending...' : 'Send code'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
