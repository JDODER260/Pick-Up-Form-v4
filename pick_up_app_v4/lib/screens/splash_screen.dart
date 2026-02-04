import "package:flutter/material.dart";
import "package:pickup_delivery_app/screens/home_screen.dart";

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _initialize_app();
  }

  Future<void> _initialize_app() async {
    if (_started) return;
    _started = true;

    // Simulate startup work (permissions, preload, etc.)
    await Future.delayed(Duration(seconds: 2));

    // 🔒 CRITICAL SAFETY CHECK
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Checking permissions...",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
