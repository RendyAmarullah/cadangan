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
    }
  }

  // Fungsi untuk mendapatkan URL gambar dari Appwrite
  String getImageUrl(String fileId) {
    String appwriteEndpoint = 'https://fra.cloud.appwrite.io/v1';  // Replace with your Appwrite endpoint
    String bucketId = '681aa16f003054da8969';  // Replace with your Appwrite bucket ID
    return '$fileId';
  }

  // Fungsi untuk memperbarui jumlah produk di Firestore
  Future<void> _updateCartItemQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) {
      // Tampilkan dialog konfirmasi sebelum menghapus item
      _showDeleteConfirmationDialog(index);
    } else {
      setState(() {
        cartItems[index]['quantity'] = newQuantity;
      });

      String userId = FirebaseAuth.instance.currentUser!.uid;
      try {
        // Menyimpan perubahan jumlah produk ke Firestore
        await FirebaseFirestore.instance.collection('carts').doc(userId).update({
          'cartItems': cartItems,
        });
        print('Data keranjang berhasil diperbarui');
      } catch (e) {
        print('Error updating cart: $e');
      }
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi penghapusan produk
  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Pesanan'),
          content: Text('Apakah Anda yakin ingin menghapus pesanan ini dari keranjang?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  cartItems.removeAt(index);
                });
                String userId = FirebaseAuth.instance.currentUser!.uid;
                try {
                  FirebaseFirestore.instance.collection('carts').doc(userId).update({
                    'cartItems': cartItems,
                  });
                  print('Barang berhasil dihapus dari keranjang');
                } catch (e) {
                  print('Error deleting item: $e');
                }
                Navigator.of(context).pop();
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90),
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
                int quantity = cartItems[index]['quantity'] ?? 1;

                // Get the image URL using the productImageUrl (fileId from Appwrite)
                String imageUrl = getImageUrl(cartItems[index]['productImageUrl']);

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
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)  // Load the product image
                              : Center(child: Icon(Icons.image, color: Colors.white)), // Placeholder if no image
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
                                      if (quantity > 0) {
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
