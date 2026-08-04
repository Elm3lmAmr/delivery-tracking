import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
    // Android emulator: http://10.0.2.2:4000/api/v1
    // Physical device / LAN: http://<YOUR_LAN_IP>:4000/api/v1
  );

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_api_base_url') ?? defaultUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    if (!formattedUrl.contains('/api/v1')) {
      formattedUrl = formattedUrl.endsWith('/') ? '${formattedUrl}api/v1' : '$formattedUrl/api/v1';
    }
    await prefs.setString('custom_api_base_url', formattedUrl);
  }

  late final Dio dio;
  String? _token;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: defaultUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final currentBaseUrl = await getBaseUrl();
        options.baseUrl = currentBaseUrl;
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        if (err.response?.statusCode == 401) {
          clearToken();
        }
        return handler.next(err);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('edara_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('edara_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('edara_token');
  }

  bool get hasToken => _token != null;
  String? get token => _token;
}
