import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

import '../../../../core/api/server_config_dialog.dart';

class OtpArguments {
  final String phone;
  final bool isRegistration;
  final String? name;
  final String? plate;
  final String? idImagePath;
  final String? licenseImagePath;
  final String? selfieImagePath;

  OtpArguments({
    required this.phone,
    this.isRegistration = false,
    this.name,
    this.plate,
    this.idImagePath,
    this.licenseImagePath,
    this.selfieImagePath,
  });
}

class OtpScreen extends StatefulWidget {
  final OtpArguments args;
  const OtpScreen({super.key, required this.args});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final controllers = List.generate(6, (_) => TextEditingController());
  final focusNodes = List.generate(6, (_) => FocusNode());

  // Resend countdown
  static const _resendCooldown = 60;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in controllers) { c.dispose(); }
    for (final f in focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _verify() {
    final code = controllers.map((c) => c.text).join();
    if (code.length == 6) {
      context.read<AuthBloc>().add(VerifyOtpEvent(widget.args.phone, code));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resend() {
    for (final c in controllers) { c.clear(); }
    focusNodes.first.requestFocus();
    context.read<AuthBloc>().add(RequestOtpEvent(widget.args.phone));
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Verify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_input_antenna),
            tooltip: 'Server IP Settings',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // If it's a registration flow, we should upload the documents here
            if (widget.args.isRegistration) {
              // Fire an event to upload documents, or just do it in the bloc/UI.
              // For simplicity, let's fire a bloc event or handle it.
              // Actually, since we need to show loading, let's do it via bloc.
              context.read<AuthBloc>().add(SubmitDocumentsEvent(
                name: widget.args.name!,
                plate: widget.args.plate!,
                idImagePath: widget.args.idImagePath!,
                licenseImagePath: widget.args.licenseImagePath!,
                selfieImagePath: widget.args.selfieImagePath!,
              ));
            } else {
              // Login flow
              if (state.driverStatus == 'verified') {
                context.go('/driver/home');
              } else {
                // If they are login but pending/revoked, still go to home (which shows pending UI)
                // Wait, previously pending went to onboarding. But since onboarding is removed, go home.
                context.go('/driver/home');
              }
            }
          } else if (state is AuthDocumentsSubmitted) {
             context.go('/driver/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.lock_outline, size: 56, color: kAccent),
                const SizedBox(height: 16),
                const Text(
                  'Enter the 6-digit code',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${widget.args.phone}',
                  style: const TextStyle(color: kMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── 6-box OTP input ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 44,
                      child: TextField(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        autofocus: i == 0,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero, // FIX: ensures 22px font fits in 44px box
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kAccent, width: 2),
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            focusNodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            // Backspace: move focus back
                            focusNodes[i - 1].requestFocus();
                          }
                          // Auto-submit when last box filled
                          if (i == 5 && v.isNotEmpty) _verify();
                        },
                      ),
                    ),
                  )),
                ),

                const SizedBox(height: 32),

                // ── Verify button ──
                ElevatedButton(
                  onPressed: isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 16),

                // ── Resend button (visible after countdown) ──
                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          'Resend code in $_secondsLeft s',
                          style: const TextStyle(color: kMuted, fontSize: 14),
                        )
                      : TextButton(
                          onPressed: isLoading ? null : _resend,
                          child: const Text(
                            'Resend code',
                            style: TextStyle(color: kAccent, fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
