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
  String? _userName;
  String? _email;

  @override
  void initState() {
    super.initState();
    client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157');

    account = Account(client);

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
        _userName = user.name ?? 'No name';
        _email = user.email;
      });
      print('User loaded: ${user.name} - ${user.email}');
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Image.asset('images/logohome.jpg', width: 50),
              SizedBox(width: 8),
              Text(
                'Selamat datang, ${_userName ?? 'Guest'}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.black),
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
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(Icons.shopping_cart, 'Cart', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MarketScreen()),
                  );
                }),
                _buildIconButton(Icons.local_drink, 'Drink', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MinumanScreen()),
                  );
                }),
                _buildIconButton(Icons.ramen_dining, 'Soup', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BunsikScreen()),
                  );
                }),
                _buildIconButton(Icons.plagiarism, 'Non-halal', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NonHalalScreen()),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Menu Popular',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMenuItem('Tteokbokki', 'Rp 30.000'),
                _buildMenuItem('Kimchi', 'Rp 30.000'),
                _buildMenuItem('Jajangmyeon', 'Rp 42.000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green,
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
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
          color: Colors.grey[300],
        ),
        SizedBox(height: 8),
        Text(name),
        Text(price),
      ],
    );
  }
}
