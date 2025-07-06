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

  // Menu slide variables
  PageController _menuPageController = PageController();
  int _currentMenuPage = 0;

  // List banner images (ganti dengan path gambar Anda)
  final List<String> _bannerImages = [
    'images/banner1.jpg', // Gambar Mu Gung Hwa
    'images/banner2.jpg',
    'images/banner3.jpg', // Gambar Jinro
    // Tambahkan lebih banyak gambar banner jika diperlukan
  ];

  final String profil = '684083800031dfaaecad';

  // Appwrite configuration (pastikan ini belum ada)
  final String projectId =
      '681aa0b70002469fc157'; // Sesuaikan jika projectId Anda berbeda
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String productsCollectionId = '68407bab00235ecda20d';
  final String cartsCollectionId = '68407db7002d8716c9d0';

  // State untuk menyimpan produk yang diambil
  Map<String, Map<String, dynamic>?> _featuredProducts = {
    'Bunsik': null,
    'Minuman': null,
    'Market': null,
    'Beauty': null,
    'NonHalal': null,
    'Barang': null,
  };

  String formatPrice(dynamic price) {
    if (price == null) {
      return 'Rp 0';
    }
    String priceString = price.toString();
    String formattedPrice = '';
    int count = 0;
    for (int i = priceString.length - 1; i >= 0; i--) {
      formattedPrice = priceString[i] + formattedPrice;
      count++;
      if (count % 3 == 0 && i != 0) {
        formattedPrice = '.' + formattedPrice;
      }
    }
    return 'Rp ' + formattedPrice;
  }

  // Fungsi baru untuk mengambil produk unggulan berdasarkan kategori dan huruf awal 'A'
  Future<void> _fetchFeaturedProducts() async {
    final categories = [
      'Bunsik',
      'Minuman',
      'Market',
      'Beauty',
      'NonHalal',
      'Barang'
    ];
    for (String category in categories) {
      try {
        final response = await databases!.listDocuments(
          databaseId: databaseId,
          collectionId: productsCollectionId,
          queries: [
            Query.equal(
                'category',
                category
                    .toLowerCase()), // Sesuaikan dengan kategori di Appwrite
            Query.startsWith(
                'name', 'A'), // Filter produk dengan nama dimulai 'A'
            Query.limit(1), // Ambil hanya 1 produk
          ],
        );

        if (response.documents.isNotEmpty) {
          setState(() {
            _featuredProducts[category] = response.documents.first.data;
          });
        }
      } catch (e) {
        print('Error fetching featured product for $category: $e');
      }
    }
  }

  String userId =
      ''; // Deklarasi userId, pastikan tidak duplikat jika sudah ada

  Future<void> _fetchCart() async {
    try {
      final user = await account!.get();
      userId = user.$id; // Pastikan userId terisi

      final response = await databases!.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      int count = 0;
      for (var doc in response.documents) {
        count += doc.data['quantity'] as int;
      }

      setState(() {
        _cartItemCount = count;
      });
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

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
    _fetchCart();
    _fetchFeaturedProducts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _menuPageController.dispose();
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),

            // Menu Slide Manual
            Container(
              height: 180,
              // Padding dipindahkan ke container utama
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  PageView(
                    controller: _menuPageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentMenuPage = page;
                      });
                    },
                    children: [
                      // Halaman 1 - tanpa padding tambahan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDynamicMenuItem(
                              _featuredProducts['Bunsik'], BunsikScreen()),
                          _buildDynamicMenuItem(
                              _featuredProducts['Minuman'], MinumanScreen()),
                          _buildDynamicMenuItem(
                              _featuredProducts['Market'], MarketScreen()),
                        ],
                      ),
                      // Halaman 2 - tanpa padding tambahan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDynamicMenuItem(
                              _featuredProducts['Beauty'], BeautyScreen()),
                          _buildDynamicMenuItem(
                              _featuredProducts['NonHalal'], NonHalalScreen()),
                          _buildDynamicMenuItem(
                              _featuredProducts['Barang'], BarangScreen()),
                        ],
                      ),
                    ],
                  ),
                  // Dot indicator untuk menu
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentMenuPage == 0
                                ? Color(0xFF0072BC)
                                : Color(0xFF0072BC).withOpacity(0.3),
                          ),
                        ),
                        Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentMenuPage == 1
                                ? Color(0xFF0072BC)
                                : Color(0xFF0072BC).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
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

  // Modified _buildMenuItem to be _buildDynamicMenuItem
  Widget _buildDynamicMenuItem(
      Map<String, dynamic>? productData, Widget targetScreen) {
    if (productData == null) {
      // Tampilan placeholder saat data belum dimuat atau tidak ditemukan
      return SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200], // Placeholder color
              ),
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey[600],
                size: 30,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Memuat...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Rp 0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    String name = productData['name'] ?? 'Nama Produk';
    String price = formatPrice(productData['price'] ?? 0);
    String imageUrl = productData['productImageUrl'] ??
        ''; // Asumsi ada field productImageUrl di Appwrite

    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman kategori yang spesifik
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: SizedBox(
        width: 80, // Membatasi lebar widget
        child: Column(
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
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
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
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 30,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            // Nama produk dengan text wrapping
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Maksimal 2 baris
              overflow: TextOverflow
                  .ellipsis, // Tambahkan ... jika masih terlalu panjang
            ),
            SizedBox(height: 4), // Spasi kecil antara nama dan harga
            // Harga produk
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // Harga hanya 1 baris
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
