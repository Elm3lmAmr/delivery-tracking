import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/server_config_dialog.dart';

class GuardLoginScreen extends StatefulWidget {
  const GuardLoginScreen({super.key});

  @override
  State<GuardLoginScreen> createState() => _GuardLoginScreenState();
}

class _GuardLoginScreenState extends State<GuardLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  List<dynamic> _gates = [];
  int? _selectedGateId;
  bool _isLoadingGates = true;

  @override
  void initState() {
    super.initState();
    _fetchGates();
  }

  Future<void> _fetchGates() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.dio.get('/auth/gates');
      if (mounted) {
        setState(() {
          _gates = res.data;
          if (_gates.isNotEmpty) {
            _selectedGateId = _gates[0]['id'];
          }
          _isLoadingGates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGates = false;
          _errorMessage = 'Failed to load gates. Using assigned gate.';
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      
      final Map<String, dynamic> data = {
        'email': email,
        'password': password,
      };
      
      if (_selectedGateId != null) {
        data['gateId'] = _selectedGateId;
      }

      final res = await apiClient.dio.post('/auth/login', data: data);

      await apiClient.saveToken(res.data['token']);
      if (mounted) {
        context.go('/guard/scanner');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['error'] ?? 'Login failed. Check your credentials.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Security Guard Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
              const Icon(Icons.admin_panel_settings, size: 80, color: kAccent),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingGates)
                const Center(child: CircularProgressIndicator())
              else if (_gates.isNotEmpty)
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Select Gate (Shift)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.door_sliding),
                  ),
                  initialValue: _selectedGateId,
                  items: _gates.map((g) {
                    return DropdownMenuItem<int>(
                      value: g['id'],
                      child: Text(g['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedGateId = val);
                  },
                ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
