import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/data_sources/delivery_remote_data_source.dart';
import '../../../../../config/theme.dart';

import '../../../../../core/api/server_config_dialog.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  String _driverName = 'Driver';

  @override
  void initState() {
    super.initState();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverName = prefs.getString('driver_name') ?? 'Driver';
    });

    try {
      final apiClient = ApiClient();
      await apiClient.loadToken();
      final ds = DeliveryRemoteDataSource(apiClient);
      final me = await ds.getMe();
      if (me['fullName'] != null && me['fullName'].toString().isNotEmpty) {
        await prefs.setString('driver_name', me['fullName']);
        if (mounted) setState(() => _driverName = me['fullName']);
      }
      if (me['plateNumber'] != null) {
        await prefs.setString('plate_number', me['plateNumber']);
      }
    } catch (e) {
      // Ignore network errors on silent reload
    }
  }

  Future<void> _signOut() async {
    final apiClient = ApiClient();
    await apiClient.clearToken();
    if (mounted) {
      context.go('/onboarding/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Home' : 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_input_antenna),
            tooltip: 'Server IP Settings',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomeTab(context) : _buildProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: kSurface,
        selectedItemColor: kAccent,
        unselectedItemColor: kMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
            const CircleAvatar(radius: 40, backgroundColor: kSurface2, child: Icon(Icons.person, color: kMuted, size: 40)),
            const SizedBox(height: 16),
            const Text('Driver Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildHomeTab(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Good afternoon', style: TextStyle(color: kMuted, fontSize: 13)),
                    Text(_driverName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                CircleAvatar(radius: 22, backgroundColor: kSurface2, child: const Icon(Icons.person, color: kMuted)),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push('/driver/new'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kAccent, Color(0xFF2A5FA0)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start a delivery',
                            style: TextStyle(color: kBg, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text("Pick where you're going, get your QR",
                            style: TextStyle(color: kBg, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: kBg, size: 32),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('RECENT DELIVERIES',
              style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _RecentItem(project: 'Eastown', unit: 'B-891', duration: '8m 42s'),
            _RecentItem(project: 'Villette', unit: 'VT-1204', duration: '11m 15s'),
            _RecentItem(project: 'Allegria', unit: 'AL-VL-442', duration: '14m 03s'),
          ],
        ),
      );
  }
}

class _RecentItem extends StatelessWidget {
  final String project;
  final String unit;
  final String duration;
  const _RecentItem({required this.project, required this.unit, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$project · $unit', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Yesterday · $duration', style: const TextStyle(color: kMuted, fontSize: 11)),
            ],
          ),
          const Text('COMPLETED',
            style: TextStyle(color: kOk, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
