import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pemesanan/BunsikScreen.dart';
import 'package:pemesanan/KeranjangScreen.dart';
import 'package:pemesanan/MarketScreen.dart';
import 'package:pemesanan/MinumanScreen.dart';
import 'package:pemesanan/NonHalalScreen.dart'; // Import the MarketScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  String? _Email;
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

List<Map<String, dynamic>> cartItems = [];
  Future<void> _saveCartItems() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference cartCollection = FirebaseFirestore.instance.collection('carts');

    // Menyimpan data keranjang ke Firestore, ID pengguna sebagai dokumen
    await cartCollection.doc(userId).set({
      'cartItems': cartItems,  // Menyimpan data keranjang dalam dokumen
      'updatedAt': FieldValue.serverTimestamp(),  // Timestamp saat diperbarui
    });

    print('Data keranjang berhasil disimpan ke Firestore');
  }
  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch the user's data from Firestore using the UID
        final documentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (documentSnapshot.exists) {
          // Assuming that the data is stored with 'email', 'name', 'password' fields
          final data = documentSnapshot.data() as Map<String, dynamic>;

          setState(() {
            _userName = data['name']; // Set the name
            _Email = data['email'];
            // Set the email
            // _password = data['password']; // We don't usually display passwords for security reasons
          });
        } else {
          print("No data found for this user.");
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              // logo mugung
              Image.asset('images/logohome.jpg', width: 50), // logo
              SizedBox(width: 8),
              Text(
                'Selamat datang, ${_userName ?? user?.displayName ?? 'Guest'}', // Display user's name or 'Guest' if not available
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Spacer(),
              // ikon keranjang
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.black),
                 onPressed: () {
          // Navigasi ke halaman keranjang
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KeranjangScreen(cartItems: cartItems),
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
          // Icons Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(Icons.shopping_cart, 'Cart', () {
                  // Navigate to the MarketScreen when the Cart button is pressed
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MarketScreen()),
                  );
                }),
                _buildIconButton(Icons.local_drink, 'Drink', () {
                  // Handle "Drink" button tap
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MinumanScreen()),
                  );
                }),
                _buildIconButton(Icons.ramen_dining, 'Soup', () {
                  // Handle "Soup" button tap
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BunsikScreen()),
                  );
                }),
                _buildIconButton(Icons.plagiarism, 'Non-halal', () {
                  // Handle "Discount" button tap
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NonHalalScreen()),
                  );
                }),
              ],
            ),
          ),
          
          // Menu Popular Section
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
          // Popular Menu Items
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

  // Helper method for creating icon buttons
  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed, // Call the onPressed callback when tapped
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

  // Helper method for creating menu items
  Widget _buildMenuItem(String name, String price) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          color: Colors.grey[300], // Placeholder for image
        ),
        SizedBox(height: 8),
        Text(name),
        Text(price),
      ],
    );
  }
}
