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

  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  PageController _menuPageController = PageController();
  int _currentMenuPage = 0;

  final List<String> _bannerImages = [
    'images/banner1.jpg',
    'images/banner2.jpg',
    'images/banner3.jpg',
  ];

  final String profil = '684083800031dfaaecad';
  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String productsCollectionId = '68407bab00235ecda20d';
  final String cartsCollectionId = '68407db7002d8716c9d0';

  Map<String, Map<String, dynamic>?> _featuredProducts = {
    'Bunsik': null,
    'Minuman': null,
    'Market': null,
    'Beauty': null,
    'NonHalal': null,
    'Barang': null,
  };

  String userId = '';

  String formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';

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
            Query.equal('category', category.toLowerCase()),
            Query.startsWith('name', 'A'),
            Query.limit(1),
          ],
        );

        if (response.documents.isNotEmpty) {
          setState(() {
            _featuredProducts[category] = response.documents.first.data;
          });
        }
      } catch (e) {
        print('Gagal mengambil produk $category: $e');
      }
    }
  }

  Future<void> _fetchCart() async {
    try {
      final user = await account!.get();
      userId = user.$id;

      final response = await databases!.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      int count = 0;
      for (var doc in response.documents) {
        count += doc.data['quantity'] as int;
      }

      setState(() {
        _cartItemCount = count;
      });
    } catch (e) {
      print('Terjadi kesalahan saat mengambil keranjang: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    client.setEndpoint('https://cloud.appwrite.io/v1').setProject(projectId);

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

  Future<void> _loadProfileData() async {
    try {
      final user = await account!.get();
      setState(() {
        _email = user.email;
      });

      String userId = user.$id;
      final profileDoc = await databases!.getDocument(
        databaseId: databaseId,
        collectionId: profil,
        documentId: userId,
      );
      setState(() {
        _userName = profileDoc.data['name'] ?? 'No name';
      });
    } catch (e) {
      print('Gagal memuat profil pengguna: $e');
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
            _buildBannerCarousel(),
            _buildCategoryGrid(),
            SizedBox(height: 5),
            _buildMenuSection(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Container(
      margin: EdgeInsets.all(25),
      height: 150,
      child: Stack(
        children: [
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
                    color: Colors.white
                        .withOpacity(_currentPage == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 0.9,
        crossAxisSpacing: 20,
        children: [
          _buildIconButton(Icons.shopping_cart, 'Market', Color(0xFF0072BC),
              () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MarketScreen()));
          }),
          _buildIconButton(Icons.local_drink, 'Minuman', Color(0xFF8DC63F), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MinumanScreen()));
          }),
          _buildIconButton(Icons.ramen_dining, 'Bunsik', Color(0xFF0072BC), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BunsikScreen()));
          }),
          _buildIconButton(Icons.no_food, 'Non-Halal', Color(0xFF8DC63F), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NonHalalScreen()));
          }),
          _buildIconButton(Icons.inventory_2, 'Barang', Color(0xFF0072BC), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BarangScreen()));
          }),
          _buildIconButton(
              Icons.face_retouching_natural, 'Beauty', Color(0xFF8DC63F), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => BeautyScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Container(
          height: 180,
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
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDotIndicator(0),
                    _buildDotIndicator(1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int index) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 4.0,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentMenuPage == index
            ? Color(0xFF0072BC)
            : Color(0xFF0072BC).withOpacity(0.3),
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
              borderRadius: BorderRadius.circular(10),
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

  Widget _buildDynamicMenuItem(
      Map<String, dynamic>? productData, Widget targetScreen) {
    if (productData == null) {
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
                color: Colors.grey[200],
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
    String imageUrl = productData['productImageUrl'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: SizedBox(
        width: 80,
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
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
