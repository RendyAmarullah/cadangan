import 'package:flutter/material.dart';
import 'package:pemesanan/BarangScreen.dart';
import 'package:pemesanan/BeautyScreen.dart';
import 'package:pemesanan/BunsikScreen.dart';
import 'package:pemesanan/KeranjangScreen.dart';
import 'package:pemesanan/MarketScreen.dart';
import 'package:pemesanan/MinumanScreen.dart';
import 'package:pemesanan/NonHalalScreen.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Account? account;
  Client client = Client();
  Databases? databases;
  String? _userName;
  String? _email;
  int _cartItemCount = 0;

  // Banner carousel variables
  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // List banner images (ganti dengan path gambar Anda)
  final List<String> _bannerImages = [
    'images/banner1.jpg', // Gambar Mu Gung Hwa
    'images/banner2.jpg',
    'images/banner3.jpg', // Gambar Jinro
    // Tambahkan lebih banyak gambar banner jika diperlukan
  ];

  final String profil = '684083800031dfaaecad';

  @override
  void initState() {
    super.initState();
    client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157');

    account = Account(client);
    databases = Databases(client);

    _loadProfileData();
    _startAutoSlider();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlider() {
    _timer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
      if (_currentPage < _bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Map<String, dynamic>> cartItems = [];

  Future<void> _loadProfileData() async {
    try {
      final user = await account!.get();
      setState(() {
        _email = user.email;
      });
      print('User loaded: ${user.name} - ${user.email}');

      String userId = user.$id;
      final profileDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: profil,
        documentId: userId,
      );
      setState(() {
        _userName = profileDoc.data['name'] ?? 'No name';
      });
      print('Nama pengguna: ${profileDoc.data['name']}');
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(55),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                child: Image.asset('images/logotanpanama.png'),
              ),
              SizedBox(width: 8),
              Text(
                '안녕하세요, ${_userName ?? 'Guest'}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              // Cart Icon (tanpa realtime badge)
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_bag_rounded,
                        color: Color(0xFF0072BC), size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KeranjangScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: [
            // Banner Carousel section
            Container(
              margin: EdgeInsets.all(25),
              height: 150,
              child: Stack(
                children: [
                  // PageView untuk banner carousel
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _bannerImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: AssetImage(_bannerImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),

                  // Dot indicator
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _bannerImages.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.white)
                                    .withOpacity(
                                        _currentPage == entry.key ? 0.9 : 0.4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Category Grid - Menggunakan GridView untuk layout yang rata
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: GridView.count(
                crossAxisCount: 3, // 3 kolom
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9, // Rasio lebar:tinggi item
                crossAxisSpacing: 20,
                children: [
                  _buildIconButton(
                      Icons.shopping_cart, 'Market', Color(0xFF0072BC), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MarketScreen()),
                    );
                  }),
                  _buildIconButton(
                      Icons.local_drink, 'Minuman', Color(0xFF8DC63F), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MinumanScreen()),
                    );
                  }),
                  _buildIconButton(
                      Icons.ramen_dining, 'Bunsik', Color(0xFF0072BC), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BunsikScreen()),
                    );
                  }),
                  _buildIconButton(
                      Icons.no_food, 'Non-Halal', Color(0xFF8DC63F), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NonHalalScreen()),
                    );
                  }),
                  _buildIconButton(
                      Icons.inventory_2, 'Barang', Color(0xFF0072BC), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BarangScreen()),
                    );
                  }),
                  _buildIconButton(Icons.face_retouching_natural, 'Beauty',
                      Color(0xFF8DC63F), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BeautyScreen()),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 5),

            // Menu Popular section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Popular menu items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuItem(
                    'Tteokbokki',
                    'Rp 30.000',
                    'images/tteokbokki.jpg',
                  ),
                  _buildMenuItem(
                    'Kimchi',
                    'Rp 30.000',
                    'images/kimchi.png',
                  ),
                  _buildMenuItem(
                    'Jjajangmyeon',
                    'Rp 42.000',
                    'images/jjajangmyeon.jpg',
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(
                  10), // Mengubah dari shape: BoxShape.circle menjadi borderRadius
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String name, String price, String imagePath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[600],
                    size: 30,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
