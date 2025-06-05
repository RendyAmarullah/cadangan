import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pemesanan/ProfilScreen.dart';
import 'package:pemesanan/RiwayatTransaksiScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/SplahScreen.dart';
import 'package:pemesanan/homescreen.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

// Appwrite config
Client client = Client()
  ..setEndpoint('https://cloud.appwrite.io/v1')
  ..setProject('681aa0b70002469fc157')
  ..setSelfSigned(status: true);
Account account = Account(client);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pemesanan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: AuthWrapper(),
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/signin': (context) => SplashScreen(),
        '/home': (context) => MainScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<models.User?> checkLoginStatus() async {
    try {
      final user = await account.get();
      return user;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User?>(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return MainScreen(); // langsung ke main dengan menu
        } else {
          return SplashScreen(); // atau ke login/signup
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    RiwayatTransaksi(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromRGBO(142, 198, 63, 0.847),
        items: [
          BottomNavigationBarItem(icon: _buildNavItem(Icons.home), label: ''),
          BottomNavigationBarItem(icon: _buildNavItem(Icons.note), label: ''),
          BottomNavigationBarItem(icon: _buildNavItem(Icons.person), label: ''),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildNavItem(IconData icon) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.white,
      child: Icon(icon, color: Colors.green),
    );
  }
}
