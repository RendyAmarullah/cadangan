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

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAppwriteSession();
  }

  Future<void> _checkAppwriteSession() async {
    try {
      final session = await account.getSession(sessionId: 'current');
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoggedIn) {
      return MainScreen(); // User is logged in
    } else {
      return SplashScreen(); // User not logged in
    }
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
