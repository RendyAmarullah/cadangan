import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pemesanan/ProfilScreen.dart';
import 'package:pemesanan/RiwayatTransaksiScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/SplahScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pemesanan/homescreen.dart';
import 'package:appwrite/appwrite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
  Client client = Client();
client
    .setEndpoint('https://fra.cloud.appwrite.io/v1')
    .setProject('681a925f0002c1ab6d72')
    .setSelfSigned(status: true); // For self signed certificates, only use for development;
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return MainScreen(); // User is logged in, show main screen with bottom navigation
        } else {
          return SplashScreen(); // User is not logged in, show splash screen
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
