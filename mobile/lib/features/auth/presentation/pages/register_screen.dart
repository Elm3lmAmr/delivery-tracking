import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/theme.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'otp_screen.dart'; // To use OtpArguments

import '../../../../core/api/server_config_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+20 ');
  final _plateController = TextEditingController();

  File? _idImage;
  File? _licenseImage;
  File? _selfieImage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(File) onPicked, {CameraDevice preferredCameraDevice = CameraDevice.rear}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      preferredCameraDevice: preferredCameraDevice,
    );
    if (picked != null) {
      setState(() => onPicked(File(picked.path)));
    }
  }

  Widget _buildImagePicker({
    required String title,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: image == null ? kBorder : kOk, width: 2),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: kMuted),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
                  const Positioned(
                    top: 8, right: 8,
                    child: Icon(Icons.check_circle, color: kOk, size: 28),
                  ),
                ],
              ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_idImage == null || _licenseImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all required images.'), backgroundColor: Colors.red),
      );
      return;
    }

    final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
    context.read<AuthBloc>().add(RequestOtpEvent(phone));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Driver Registration'),
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
          if (state is AuthOtpSent) {
            final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
            context.push('/onboarding/otp', extra: OtpArguments(
              phone: phone,
              isRegistration: true,
              name: _nameController.text.trim(),
              plate: _plateController.text.trim(),
              idImagePath: _idImage!.path,
              licenseImagePath: _licenseImage!.path,
              selfieImagePath: _selfieImage!.path,
            ));
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.trim().length < 3 ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter your mobile number' : null,
                ),
                const SizedBox(height: 32),

                const Text('Vehicle Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Plate Number (e.g. ABC 123)', prefixIcon: Icon(Icons.directions_car)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter your plate number' : null,
                ),
                const SizedBox(height: 32),

                const Text('Documents & Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildImagePicker(
                        title: 'National ID',
                        icon: Icons.credit_card,
                        image: _idImage,
                        onTap: () => _pickImage(ImageSource.camera, (f) => _idImage = f),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImagePicker(
                        title: 'License',
                        icon: Icons.drive_eta,
                        image: _licenseImage,
                        onTap: () => _pickImage(ImageSource.camera, (f) => _licenseImage = f),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildImagePicker(
                  title: 'Take Selfie',
                  icon: Icons.face,
                  image: _selfieImage,
                  onTap: () => _pickImage(ImageSource.camera, (f) => _selfieImage = f, preferredCameraDevice: CameraDevice.front),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit & Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
