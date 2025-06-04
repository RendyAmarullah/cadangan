import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pemesanan/ProfilScreen.dart';
import 'package:pemesanan/RiwayatTransaksiScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/SplahScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pemesanan/homescreen.dart';
import 'package:appwrite/appwrite.dart';
import 'appwrite_service.dart';
import 'package:appwrite/models.dart' as models;

// GLOBAL INSTANCE
Client client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1')
  ..setProject('681a925f0002c1ab6d72')
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
      title: 'Splash Screen Demo',
      home: AuthWrapper(),
      initialRoute: '/',
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/signin': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1') // Ganti dengan endpoint kamu
    ..setProject('681aa0b70002469fc157'); // Ganti dengan project ID kamu

  final Account account;

  AuthWrapper() : account = Account(Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('681aa0b70002469fc157'));

  Future<models.User?> _checkLoginStatus() async {
    try {
      final user = await account.get();
      return user;
    } catch (e) {
      return null; // Tidak login
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User?>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return MainScreen(); // User sudah login
        } else {
          return SplashScreen(); // Belum login
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

  // List of widget options for bottom navigation
  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    RiwayatTransaksi(),
    ProfileScreen(),
  ];

  // Function to handle bottom navigation item taps
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
        backgroundColor: const Color.fromRGBO(142, 198, 63, 0.847), // Custom green color for bottom bar
        items: [
          BottomNavigationBarItem(
            icon: _buildNavItem(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavItem(Icons.note),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavItem(Icons.person),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped, // Update the selected screen
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Helper method to create bottom navigation item with circular style
  Widget _buildNavItem(IconData icon) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.white,
      child: Icon(icon, color: Colors.green),
    );
  }
}
