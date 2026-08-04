import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/app.dart';
import 'core/api/api_client.dart';
import 'features/auth/data/data_sources/auth_remote_data_source.dart';
import 'features/auth/data/repositories_impl/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Run `flutterfire configure` if this is missing
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  final apiClient = ApiClient();
  
  // Initialize Push Notifications
  final pushService = PushNotificationService(apiClient);
  pushService.initialize().catchError((e) => debugPrint('Push init error: $e'));

  // We remove the await here. SplashScreen will load the token.
  // This ensures runApp is called immediately and the screen doesn't stay black.

  final authRemoteDataSource = AuthRemoteDataSource(apiClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(repository: authRepository),
          ),
        ],
        child: const EdaraApp(),
      ),
    ),
  );
}
