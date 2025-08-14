import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/splash_screen.dart';
import 'web/web_auth_page.dart';
import 'web/google_maps_dashboard.dart';
import 'mobile/mobile_auth_page.dart';
import 'mobile/mobile_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated - show appropriate dashboard
          return kIsWeb ? const GoogleMapsDashboard() : const MobileDashboard();
        } else {
          // User not authenticated - show appropriate auth page
          return kIsWeb ? const WebAuthPage() : const MobileAuthPage();
        }
      },
    );
  }
}
