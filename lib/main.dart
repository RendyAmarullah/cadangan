import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
      theme: ThemeData(primaryColor: Color(0xFF8DC63F)),
      home: AuthWrapper(),
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
          return MainScreen(userId: snapshot.data!.$id);
        } else {
          return SplashScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;

  MainScreen({required this.userId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();

    // Initialize widget options first
    _widgetOptions = <Widget>[
      HomeScreen(),
      RiwayatTransaksiScreen(userId: widget.userId),
      ProfileScreen(),
    ];

    // Initialize animation controllers for each nav item
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    // Initialize animations
    _animations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -15.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Animate the first item by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationControllers[0].forward();
      }
    });
  }

  @override
  void dispose() {
    // Dispose animation controllers properly
    for (var controller in _animationControllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Color(0xFF8DC63F),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAnimatedNavItem(0, Icons.home),
            _buildAnimatedNavItem(1, Icons.receipt_long),
            _buildAnimatedNavItem(2, Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(int index, IconData icon) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedBuilder(
        animation: _animations[index],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animations[index].value),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _selectedIndex == index ? Colors.white : Colors.transparent,
                boxShadow: _selectedIndex == index
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color:
                    _selectedIndex == index ? Color(0xFF8DC63F) : Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index && mounted) {
      // Reset previous animation safely
      if (_animationControllers[_selectedIndex].isAnimating) {
        _animationControllers[_selectedIndex].stop();
      }
      _animationControllers[_selectedIndex].reverse();

      setState(() {
        _selectedIndex = index;
      });

      // Start new animation safely
      if (mounted) {
        _animationControllers[index].forward();
      }
    }
  }
}

// Alternative Custom Bottom Navigation Bar Widget
class CustomElevatedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<AnimationController> animationControllers;
  final List<Animation<double>> animations;

  CustomElevatedBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.animationControllers,
    required this.animations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Color(0xFF8DC63F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background indicator for selected item
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: (MediaQuery.of(context).size.width / 3) * selectedIndex +
                (MediaQuery.of(context).size.width / 6) -
                30,
            top: 10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home),
              _buildNavItem(1, Icons.receipt_long),
              _buildNavItem(2, Icons.person),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedBuilder(
        animation: animations[index],
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animations[index].value),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Icon(
                icon,
                color:
                    selectedIndex == index ? Color(0xFF8DC63F) : Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}
