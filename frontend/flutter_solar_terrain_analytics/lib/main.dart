import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  debugPrint('Launching SolarAnalyticsApp...');
  runApp(const SolarAnalyticsApp());
}

class SolarAnalyticsApp extends StatelessWidget {
  const SolarAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Terrain Analytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      builder: (context, child) {
        // Replace default red error screen with inline message to aid debugging white screen issues.
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            appBar: AppBar(title: const Text('Runtime Error')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text('A runtime error occurred:\n\n'
                  '${details.exceptionAsString()}\n\n'
                  'Stack:\n${details.stack}')
            ),
          );
        };
        return child ?? const SizedBox();
      },
      home: const AuthWrapper(),
    );
  }
}
