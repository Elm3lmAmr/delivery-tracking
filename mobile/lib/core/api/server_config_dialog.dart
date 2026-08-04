import 'package:flutter/material.dart';
import 'api_client.dart';
import '../../config/theme.dart';

Future<void> showServerConfigDialog(BuildContext context) async {
  final currentUrl = await ApiClient.getBaseUrl();
  final controller = TextEditingController(text: currentUrl);

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: kSurface,
        title: const Row(
          children: [
            Icon(Icons.dns, color: kAccent),
            SizedBox(width: 8),
            Text('Server IP / URL', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend API server IP or URL. Change this whenever you switch networks or host machines:',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://192.168.1.50:4000/api/v1',
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'JetBrainsMono'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Default Android Emulator: http://10.0.2.2:4000/api/v1\nPhysical Phone: http://<LAN_IP>:4000/api/v1',
              style: TextStyle(color: kMuted, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiClient.setBaseUrl(newUrl);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server API URL updated to:\n$newUrl')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
