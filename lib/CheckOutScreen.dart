import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/RiwayatTransaksiScreen.dart';
import 'package:pemesanan/AlamatScreen.dart'; // Import AlamatScreen
import 'package:pemesanan/main.dart';

final client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1')
  ..setProject('681aa0b70002469fc157')
  ..setSelfSigned(status: true);

final databases = Databases(client);
final account = Account(client);

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CheckoutScreen({required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Client _client;
  late Databases _databases;
  late Account _account;

  String userId = '';
  String address = '';
  String _metodePembayaran = 'COD';
  bool _isProcessingOrder = false; // Tambahan untuk mencegah double-tap

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String cartsCollectionId = '68407db7002d8716c9d0';
  final String addressCollectionId = '68447d3d0007b5f75cc5';

  @override
  void initState() {
    super.initState();
    _initAppwrite();
  }

  void _initAppwrite() async {
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _databases = Databases(_client);
    _account = Account(_client);

    await _getCurrentUser();
    await _fetchUserAddress();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;

    setState(() {
      widget.cartItems[index]['quantity'] = newQuantity;
    });
  }

  Future<bool?> _notifCheckout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Pesanan'),
          content: Text('Apakah Anda yakin ingin membuat pesanan?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentUser() async {
    try {
      final models.User user = await _account.get();
      setState(() {
        userId = user.$id;
      });
    } catch (e) {
      print('Error getting user: $e');
    }
  }

  Future<void> clearCartItems(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      for (var doc in result.documents) {
        await _databases.deleteDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: doc.$id,
        );
      }

      print('Cart cleared successfully.');
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  Future<void> _fetchUserAddress() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: addressCollectionId,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      if (result.documents.isNotEmpty) {
        setState(() {
          address =
              result.documents.first.data['address'] ?? 'Alamat tidak tersedia';
        });
      } else {
        setState(() {
          address = 'Alamat tidak ditemukan';
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  // Method untuk navigate ke halaman alamat dan refresh alamat setelah kembali
  void _navigateToAddressScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlamatScreen()),
    );

    // Refresh alamat setelah kembali dari halaman alamat
    if (result == true || result == null) {
      await _fetchUserAddress();
    }
  }

  // Method untuk membuat pesanan dengan validasi
  Future<void> _createOrder() async {
    if (_isProcessingOrder) return; // Mencegah double-tap

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      // Validasi alamat
      if (address.isEmpty ||
          address == 'Alamat tidak ditemukan' ||
          address == 'Alamat tidak tersedia') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silakan pilih alamat pengiriman terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validasi cart items
      if (widget.cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keranjang kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user = await account.get();

      // Siapkan data produk
      final produkList = widget.cartItems
          .map((item) => {
                'name': item['name'] ?? 'Produk',
                'jumlah': item['quantity'] ?? 1,
                'harga': item['price'] ?? 0,
                'productImageUrl': item['productImageUrl'] ?? ''
              })
          .toList();

      final produkJsonString = jsonEncode(produkList);

      // Generate order ID
      String generateOrderId() {
        final random = Random();
        final randomDigits = random.nextInt(9000) + 1000;
        return 'MGH$randomDigits';
      }

      String orderId = generateOrderId();

      // Hitung total
      int totalPrice = widget.cartItems.fold<int>(0, (sum, item) {
        int price = item['price'] is int ? item['price'] : 0;
        int quantity = item['quantity'] is int ? item['quantity'] : 1;
        return sum + price * quantity;
      });
      int totalPriceWithShipping = totalPrice + 5000;

      // PENTING: Buat timestamp saat pesanan dibuat (saat tombol diklik)
      String orderTimestamp = DateTime.now().toUtc().toIso8601String();

      final data = {
        'userId': user.$id,
        'orderId': orderId,
        'alamat': address,
        'produk': produkJsonString,
        'metodePembayaran': _metodePembayaran,
        'total': totalPriceWithShipping,
        'tanggal': orderTimestamp, // Menggunakan timestamp saat pesanan dibuat
        'status': 'menunggu'
      };

      // Simpan pesanan ke database
      final response = await databases.createDocument(
        databaseId: databaseId,
        collectionId: '684b33e80033b767b024',
        documentId: ID.unique(),
        data: data,
      );

      // Clear cart setelah pesanan berhasil
      await clearCartItems(user.$id);

      print('Pesanan berhasil dibuat pada: $orderTimestamp');
      print('Order ID: $orderId');
      print('Response ID: ${response.$id}');

      // Tampilkan notifikasi sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan berhasil dibuat! Order ID: $orderId'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate ke main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userId: user.$id),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Gagal membuat pesanan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = widget.cartItems.fold<int>(0, (sum, item) {
      int price = item['price'] is int ? item['price'] : 0;
      int quantity = item['quantity'] is int ? item['quantity'] : 1;
      return sum + price * quantity;
    });

    int totalPrice2 = totalPrice + 5000; // Fixed calculation

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color(0xFF0072BC),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          title: Text(
            'Checkout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Section Alamat Pengiriman dengan tombol Ubah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alamat Pengiriman',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: _navigateToAddressScreen,
                    child: Text(
                      'Ubah',
                      style: TextStyle(
                        color: Color(0xFF0072BC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    int quantity = widget.cartItems[index]['quantity'] ?? 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                widget.cartItems[index]['productImageUrl'] ??
                                    '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                      size: 25,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF0072BC),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.cartItems[index]['name'] ??
                                    'Product'),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  'Rp ${widget.cartItems[index]['price'] ?? 0}',
                                  style: TextStyle(color: Color(0xFF8DC63F)),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF8DC63F),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        if (quantity > 1) {
                                          _updateQuantity(index, quantity - 1);
                                        }
                                      },
                                    ),
                                    Text(quantity.toString()),
                                    IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF0072BC),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        _updateQuantity(index, quantity + 1);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catatan Tambahan:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Tinggalkan catatan'),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp $totalPrice',
                              style: TextStyle(color: Color(0xFF8DC63F))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pilih Pembayaran:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              setState(() {
                                _metodePembayaran = value;
                              });
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'COD',
                                child: Text('COD'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'QRIS',
                                child: Text('QRIS'),
                              ),
                            ],
                            child: Text('$_metodePembayaran >',
                                style: TextStyle(
                                    color: Color(0xFF0072BC),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pesanan:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp $totalPrice',
                              style: TextStyle(color: Color(0xFF8DC63F))),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Biaya Pengiriman:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp 5000',
                              style: TextStyle(color: Color(0xFF8DC63F))),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp $totalPrice2',
                              style: TextStyle(color: Color(0xFF8DC63F))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessingOrder
                    ? null
                    : () async {
                        bool? isConfirmed = await _notifCheckout(context);

                        if (isConfirmed == true) {
                          await _createOrder();
                        }
                      },
                child: _isProcessingOrder
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Buat Pesanan',
                        style: TextStyle(color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isProcessingOrder ? Colors.grey : Color(0xFF0072BC),
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
