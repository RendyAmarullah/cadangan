import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pemesanan/BunsikScreen.dart';
import 'package:pemesanan/KeranjangScreen.dart';
import 'package:pemesanan/MarketScreen.dart';
import 'package:pemesanan/MinumanScreen.dart';
import 'package:pemesanan/NonHalalScreen.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

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
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF0072BC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.restaurant, color: Colors.white),
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
                    icon: Icon(Icons.shopping_bag_outlined,
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
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '2',
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
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: [
            // Banner section
            Container(
              margin: EdgeInsets.all(20),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  'Banner Area',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Category icons - First row (4 items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconButton(
                      Icons.shopping_cart, 'Makanan', Color(0xFF0072BC), () {
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
                          // Add navigation for Barang screen
                          print('Barang tapped');
                        }),
                        _buildIconButton(Icons.face_retouching_natural,
                            'Beauty', Color(0xFF8DC63F), () {
                          // Add navigation for Beauty screen
                          print('Beauty tapped');
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
                'Menu Popular',
                style: TextStyle(
                  fontSize: 18,
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
                  _buildMenuItem('Tteokbokki', 'Rp 30.000'),
                  _buildMenuItem('Kimchi', 'Rp 30.000'),
                  _buildMenuItem('Jjajangmyeon', 'Rp 42.000'),
                ],
              ),
            ),

            SizedBox(height: 20), // Reduced space since no bottom navigation
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

  Widget _buildMenuItem(String name, String price) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
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
