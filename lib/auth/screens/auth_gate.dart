import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../pages/home_page.dart';
import '../screens/login_screen.dart';
import '../../models/user_model.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔥 AuthGate initState()');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔥 AuthGate build()');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        debugPrint('🔄 [$now] ConnectionState: ${snapshot.connectionState}');
        debugPrint('🔄 [$now] HasData: ${snapshot.hasData}');
        debugPrint('🔄 [$now] User: ${snapshot.data?.email}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ [$now] Waiting...');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang kiểm tra...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          debugPrint('✅ [$now] Showing HomePage for: ${snapshot.data?.email}');

          final firebaseUser = snapshot.data!;
          final userModel = UserModel(
            id: firebaseUser.uid,
            username: firebaseUser.email?.split('@')[0] ?? 'User',
            email: firebaseUser.email ?? '',
          );

          return HomePage(user: userModel);
        }

        debugPrint('⚠️ [$now] Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}
