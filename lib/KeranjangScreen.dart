import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class KeranjangScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  KeranjangScreen({required this.cartItems});

  @override
  _KeranjangScreenState createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // Fungsi untuk mengambil data keranjang dari Firestore
  Future<void> _loadCartItems() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('carts').doc(userId).get();

    if (snapshot.exists) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(snapshot['cartItems']);
      });
    } else {
      setState(() {
        cartItems = [];
      });
    }
  }

  // Fungsi untuk memperbarui jumlah produk di Firestore
  Future<void> _updateCartItemQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) return; // Cegah jumlah menjadi negatif atau 0

    String userId = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      cartItems[index]['quantity'] = newQuantity;
    });

    // Menyimpan data ke Firestore
    try {
      await FirebaseFirestore.instance.collection('carts').doc(userId).update({
        'cartItems': cartItems,
      });
      print('Data keranjang berhasil diperbarui');
    } catch (e) {
      print('Error updating cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90), // Adjust the height of the app bar
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          title: Row(
            children: [
              Text(
                'Keranjang',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(child: Text('Keranjang kosong'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                // Pastikan quantity tidak null, jika null set default 1
                int quantity = cartItems[index]['quantity'] ?? 1;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  
                  child: Container(
                    decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 3), // Shadow position
                      ),
                    ],
                  ),
                    child: Row(
                      children: [
                        // Gambar produk
                        Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300], // Placeholder image
                          child: Center(
                            child: Icon(Icons.image, color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Deskripsi produk dan jumlah
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartItems[index]['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('Rp ${cartItems[index]['price']}'),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        _updateCartItemQuantity(index, quantity - 1);
                                      }
                                    },
                                  ),
                                  Text(quantity.toString()), // Menampilkan jumlah produk
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      _updateCartItemQuantity(index, quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}