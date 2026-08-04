import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/data_sources/delivery_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewDeliveryScreen extends StatefulWidget {
  const NewDeliveryScreen({super.key});
  @override
  State<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends State<NewDeliveryScreen> {
  String _project = 'Eastown';
  final _unitController = TextEditingController(text: 'B-1247');
  bool _isLoading = false;

  static const Map<String, int> projects = {
    'Allegria': 1, 'Eastown': 2, 'Villette': 3, 'Karmell': 4,
    'The Estates': 5, 'Sky Condos': 6, 'June': 7, 'Ogami': 8
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New delivery')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text('Where are you going?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text('PROJECT',
              style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: DropdownButton<String>(
                value: _project,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: kSurface,
                items: projects.keys.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) { if (v != null) setState(() => _project = v); },
              ),
            ),
            const SizedBox(height: 16),
            const Text('UNIT',
              style: TextStyle(color: kMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(controller: _unitController),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  final apiClient = ApiClient();
                  await apiClient.loadToken();
                  final ds = DeliveryRemoteDataSource(apiClient);
                  final projectId = projects[_project]!;
                  final res = await ds.createDelivery(projectId, _unitController.text);
                  
                  final prefs = await SharedPreferences.getInstance();
                  final plate = prefs.getString('plate_number') ?? 'Unknown Plate';
                  
                  if (mounted) {
                    context.push('/driver/qr', extra: {
                      'deliveryId': res['id'],
                      'qrPayload': res['qrPayload'],
                      'project': _project,
                      'unit': _unitController.text,
                      'plate': plate,
                    });
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Get gate QR'),
            ),
          ],
        ),
      ),
    );
  }
}
