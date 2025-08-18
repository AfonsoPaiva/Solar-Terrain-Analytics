import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enhanced error handling
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };
  
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Test Firebase Auth connection
    FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint('Auth state changed: ${user?.email ?? 'not logged in'}');
    });
    
    runApp(const SolarAnalyticsApp());
    
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Run app even if Firebase fails
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Terrain Analytics - Error',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Initialization Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Failed to initialize Firebase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Check the console for details'),
            ],
          ),
        ),
      ),
    );
  }
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
