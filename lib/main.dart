import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pemesanan/HomeScreenKaryawan.dart';
import 'package:pemesanan/ProfilScreen.dart';
import 'package:pemesanan/RiwayatTransaksiScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/SplahScreen.dart';
import 'package:pemesanan/StatusPesananKaryawan.dart';
import 'package:pemesanan/homescreen.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';

Client client = Client()
  ..setEndpoint('https://cloud.appwrite.io/v1')
  ..setProject('681aa0b70002469fc157')
  ..setSelfSigned(status: true);
Account account = Account(client);
final Databases databases = Databases(client);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final client = Client();
  client
      .setEndpoint('https://fra.cloud.appwrite.io/v1')
      .setProject('681aa0b70002469fc157');
  final account = Account(client);

  try {
    final user = await account.get();
    runApp(MyApp(userId: user.$id));
  } catch (e) {
    print("Error fetching user ID: $e");
    runApp(MyApp(userId: ''));
  }
}

class MyApp extends StatelessWidget {
  final String userId;

  MyApp({required this.userId});

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
        '/home': (context) => MainScreen(userId: userId),
        '/home_karyawan': (context) => MainScreenKaryawan(userId: userId),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<Map<String, dynamic>?> checkLoginStatus() async {
    try {
      final session = await account.getSession(sessionId: 'current');
      if (session != null) {
        final user = await account.get();
        final userId = user.$id;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);

        final response = await databases.getDocument(
          databaseId: '681aa33a0023a8c7eb1f',
          collectionId: '684083800031dfaaecad',
          documentId: userId,
        );

        final roles = List<String>.from(response.data['roles'] ?? []);
        return {'user': user, 'isKaryawan': roles.contains('karyawan')};
      }
      return null;
    } catch (e) {
      print('Error checking login status: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!;
          final user = userData['user'] as models.User;
          final isKaryawan = userData['isKaryawan'] as bool;

          if (isKaryawan) {
            return MainScreenKaryawan(userId: user.$id);
          } else {
            return MainScreen(userId: user.$id);
          }
        } else {
          return SplashScreen();
        }
      },
    );
  }
}

abstract class BaseMainScreen extends StatefulWidget {
  final String userId;
  BaseMainScreen({required this.userId});
}

abstract class BaseMainScreenState<T extends BaseMainScreen> extends State<T>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;
  late List<Widget> _widgetOptions;

  List<Widget> getWidgetOptions();

  @override
  void initState() {
    super.initState();
    _widgetOptions = getWidgetOptions();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _animations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -15.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationControllers[0].forward();
      }
    });
  }

  @override
  void dispose() {
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
          color: Color(0xFF0072BC),
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
                    _selectedIndex == index ? Color(0xFF0072BC) : Colors.white,
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
      if (_animationControllers[_selectedIndex].isAnimating) {
        _animationControllers[_selectedIndex].stop();
      }
      _animationControllers[_selectedIndex].reverse();

      setState(() {
        _selectedIndex = index;
      });

      if (mounted) {
        _animationControllers[index].forward();
      }
    }
  }
}

class MainScreen extends BaseMainScreen {
  MainScreen({required String userId}) : super(userId: userId);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends BaseMainScreenState<MainScreen> {
  @override
  List<Widget> getWidgetOptions() {
    return <Widget>[
      HomeScreen(),
      RiwayatTransaksiScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }
}

class MainScreenKaryawan extends BaseMainScreen {
  MainScreenKaryawan({required String userId}) : super(userId: userId);

  @override
  _MainScreenKaryawanState createState() => _MainScreenKaryawanState();
}

class _MainScreenKaryawanState extends BaseMainScreenState<MainScreenKaryawan> {
  @override
  List<Widget> getWidgetOptions() {
    return <Widget>[
      HomeScreenKaryawan(),
      StatusPesananKaryawanScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }
}
