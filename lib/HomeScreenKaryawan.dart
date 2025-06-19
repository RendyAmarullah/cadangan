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

class HomeScreenKaryawan extends StatefulWidget {
  @override
  _HomeScreenKaryawanState createState() => _HomeScreenKaryawanState();
}

class _HomeScreenKaryawanState extends State<HomeScreenKaryawan> {
  Account? account;
  Client client = Client();
  Databases? databases;
  String? _userName;
  String? _email;
  int _cartItemCount = 0;
  Stream<DocumentSnapshot>? _cartStream;

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
                      if (cartCount > 0) 
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
                 
                ],
              ),
            ),

            SizedBox(height: 20),

            // Category icons - Second row (2 items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  
                ],
              ),
            ),

            SizedBox(height: 30),

            // Menu Popular section
           

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
