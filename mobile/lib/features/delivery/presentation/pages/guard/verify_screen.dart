import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../config/theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/data_sources/delivery_remote_data_source.dart';
import '../../../data/repositories_impl/delivery_repository_impl.dart';

class GuardVerifyScreen extends StatefulWidget {
  final Map<String, dynamic> deliveryData;

  const GuardVerifyScreen({super.key, required this.deliveryData});

  @override
  State<GuardVerifyScreen> createState() => _GuardVerifyScreenState();
}

class _GuardVerifyScreenState extends State<GuardVerifyScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      await apiClient.loadToken();
      final repo = DeliveryRepositoryImpl(remoteDataSource: DeliveryRemoteDataSource(apiClient));
      final isExit = widget.deliveryData['mode'] == 'exit';
      
      if (isExit) {
        await repo.confirmExit(widget.deliveryData['deliveryId']);
      } else {
        await repo.confirmEntry(widget.deliveryData['deliveryId']);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isExit ? 'Delivery checked out successfully.' : 'Delivery confirmed! Tracking started.')
        ));
        context.go('/guard/scanner');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          msg = e.response?.data['error']?.toString() ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      await apiClient.loadToken();
      final repo = DeliveryRepositoryImpl(remoteDataSource: DeliveryRemoteDataSource(apiClient));
      await repo.rejectEntry(widget.deliveryData['deliveryId'], 'Rejected by guard at gate');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery rejected.')));
        context.go('/guard/scanner');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          msg = e.response?.data['error']?.toString() ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.deliveryData;
    final driverData = data['driver'] as Map<String, dynamic>?;
    final destinationData = data['destination'] as Map<String, dynamic>?;
    
    final driverName = driverData?['fullName'] ?? 'Unknown Driver';
    final plateNumber = driverData?['plateNumber'] ?? 'Unknown Plate';
    final destination = '${destinationData?['projectName'] ?? 'Unknown Project'} · ${destinationData?['unitNumber'] ?? 'Unknown Unit'}';

    final isExit = data['mode'] == 'exit';

    return Scaffold(
      appBar: AppBar(title: Text(isExit ? 'Verify exit' : 'Verify entry')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: kOk.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('VERIFIED',
                style: TextStyle(color: kOk, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(radius: 60, backgroundColor: kSurface2, child: Icon(Icons.person, size: 60, color: kMuted)),
            const SizedBox(height: 16),
            Text(driverName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            Text(plateNumber,
              style: const TextStyle(color: kMuted, fontSize: 14, letterSpacing: 1),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(isExit ? 'CAME FROM' : 'GOING TO',
                    style: const TextStyle(color: kMuted, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(destination,
                    style: const TextStyle(color: kAccent, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isExit ? 'Confirm Exit & Stop Tracking' : 'Let in & start tracking'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleReject,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: kBorder),
                  foregroundColor: kText,
                ),
                child: Text(isExit ? 'Reject exit' : 'Reject entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
