import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../config/theme.dart';

class QrDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const QrDisplayScreen({super.key, required this.data});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = widget.data['qrPayload'] ?? 'EDARA|v1|error';
    final project = widget.data['project'] ?? 'Unknown';
    final unit = widget.data['unit'] ?? 'Unknown';
    final plate = widget.data['plate'] ?? 'Unknown Plate';
    final deliveryId = widget.data['deliveryId'];

    return Scaffold(
      appBar: AppBar(title: const Text('Your QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Show at the gate',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text("Guard scans, you're in.",
              style: TextStyle(color: kMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                data: qrPayload,
                size: 240,
                backgroundColor: Colors.white,
                foregroundColor: kBg,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              deliveryId != null ? 'DLV-ID-#$deliveryId' : 'DLV-EX-4472-Q9K',
              style: const TextStyle(color: kAccent, fontFamily: 'JetBrainsMono', fontSize: 13, letterSpacing: 1.4),
            ),
            const SizedBox(height: 16),
            const _Countdown(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _KV(k: 'Destination', v: '$project · $unit'),
                  const SizedBox(height: 8),
                  _KV(k: 'Vehicle', v: plate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown();
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  int _seconds = 30 * 60;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _seconds <= 0) return false;
      setState(() => _seconds--);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return Column(
      children: [
        Text('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          style: const TextStyle(color: kWarn, fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const Text('expires in', style: TextStyle(color: kMuted, fontSize: 11)),
      ],
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  const _KV({required this.k, required this.v});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: kMuted, fontSize: 12)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
