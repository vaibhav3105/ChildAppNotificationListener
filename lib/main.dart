import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:forground_app/auth/login_screen.dart';
import 'package:forground_app/pages/home_page.dart';
import 'package:forground_app/utils/helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        elevation: 0.0,
        child: Container(
          height: 500.0,
          color: Colors.red,
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserLoggedInAndIntroStatus();
  }

  Future getUserLoggedInAndIntroStatus() async {
    await Helper.getUserLoggedInStatus().then((value) {
      if (value != null) {
        setState(() {
          _isSignedIn = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Foreground servive starter',
      theme: ThemeData(
        primaryColor: Color(
          0xFFee7b64,
        ),
      ),
      home: _isSignedIn ? HomePage() : LoginScreen(),
    );
  }
}
