import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Stream<DocumentSnapshot>? _cartStream;

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
    _initializeCartStream();
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

  Future<void> _saveCartItems() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference cartCollection =
        FirebaseFirestore.instance.collection('carts');

    await cartCollection.doc(userId).set({
      'cartItems': cartItems,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('Data keranjang berhasil disimpan ke Firestore');
  }

  void _initializeCartStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cartStream = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .snapshots();
    }
  }

  int _calculateCartItemCount(List<dynamic>? cartItems) {
    if (cartItems == null) return 0;

    int totalCount = 0;
    for (var item in cartItems) {
      // Asumsi setiap item memiliki field 'quantity' atau 'jumlah'
      if (item is Map<String, dynamic>) {
        int quantity = item['quantity'] ?? item['jumlah'] ?? 1;
        totalCount += quantity;
      }
    }
    return totalCount;
  }

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
              // Realtime Cart Icon with Badge
              StreamBuilder<DocumentSnapshot>(
                stream: _cartStream,
                builder: (context, snapshot) {
                  int cartCount = 0;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    Map<String, dynamic>? data =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null && data.containsKey('cartItems')) {
                      cartCount = _calculateCartItemCount(data['cartItems']);
                    }
                  }

                  return Stack(
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
                      if (cartCount > 0) // Hanya tampilkan badge jika ada item
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              cartCount > 99 ? '99+' : cartCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
              margin: EdgeInsets.all(20),
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

            // Category icons - First row (4 items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                ],
              ),
            ),

            SizedBox(height: 20),

            // Category icons - Second row (2 items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIconButton(
                            Icons.inventory_2, 'Barang', Color(0xFF0072BC), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BarangScreen()),
                          );
                        }),
                        _buildIconButton(Icons.face_retouching_natural,
                            'Beauty', Color(0xFF8DC63F), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BeautyScreen()),
                          );
                        }),
                      ],
                    ),
                  ),
                  Expanded(
                      child: Container()), // Empty space to balance the layout
                ],
              ),
            ),

            SizedBox(height: 30),

            // Menu Popular section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Popular menu items
            // Ganti bagian Padding menu items dengan ini:
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuItem(
                    'Tteokbokki',
                    'Rp 30.000',
                    'images/tteokbokki.jpg', // Tambahkan parameter gambar
                  ),
                  _buildMenuItem(
                    'Kimchi',
                    'Rp 30.000',
                    'images/kimchi.png', // Tambahkan parameter gambar
                  ),
                  _buildMenuItem(
                    'Jjajangmyeon',
                    'Rp 42.000',
                    'images/jjajangmyeon.jpg', // Tambahkan parameter gambar
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
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(width: 8),
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

  // Pastikan method _buildMenuItem Anda seperti ini:
  Widget _buildMenuItem(String name, String price, String imagePath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
