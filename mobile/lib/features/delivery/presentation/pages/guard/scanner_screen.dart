import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../config/theme.dart';
import '../../../data/data_sources/delivery_remote_data_source.dart';
import '../../../data/repositories_impl/delivery_repository_impl.dart';

import '../../../../../core/api/server_config_dialog.dart';

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});
  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  int _selectedIndex = 0;

  Future<void> _signOut() async {
    final apiClient = ApiClient();
    await apiClient.clearToken();
    if (mounted) {
      context.go('/onboarding/role');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    if (!code.startsWith('EDARA|v1|')) return;
    _handled = true;
    
    // Call backend API
    try {
      final apiClient = ApiClient();
      await apiClient.loadToken();
      final repo = DeliveryRepositoryImpl(remoteDataSource: DeliveryRemoteDataSource(apiClient));
      final data = await repo.lookupQr(code);
      
      final mode = data['mode']; // 'entry' or 'exit'
      if (_selectedIndex == 0 && mode != 'entry') {
        throw Exception('This QR is for Exit. Please use the "Scan Out" tab.');
      }
      if (_selectedIndex == 1 && mode != 'exit') {
        throw Exception('This QR is for Entry. Please use the "Scan In" tab.');
      }

      if (mounted) {
        context.push('/guard/verify', extra: data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _handled = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Gate A · Scan In' : _selectedIndex == 1 ? 'Gate A · Scan Out' : 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_input_antenna),
            tooltip: 'Server IP Settings',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: (_selectedIndex == 0 || _selectedIndex == 1) ? _buildScannerTab() : _buildProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: kSurface,
        selectedItemColor: kAccent,
        unselectedItemColor: kMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Scan In'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Scan Out'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, backgroundColor: kSurface2, child: Icon(Icons.security, color: kMuted, size: 40)),
            const SizedBox(height: 16),
            const Text('Guard Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kCrit,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab() {
    return Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: _selectedIndex == 0 ? kOk : kWarn, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 24,
            child: const Text('Align QR inside the frame',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            left: 20, right: 20, bottom: 60,
            child: ElevatedButton(
              onPressed: () => _onDetect(BarcodeCapture(barcodes: [Barcode(rawValue: 'EDARA|v1|TEST_SIMULATED_TOKEN')])),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              child: const Text('Simulate scan'),
            ),
          ),
        ],
      );
  }
}
