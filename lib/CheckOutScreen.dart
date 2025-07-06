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
import 'package:pemesanan/AlamatScreen.dart';
import 'package:pemesanan/main.dart';

final client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1')
  ..setProject('681aa0b70002469fc157')
  ..setSelfSigned(status: true);

final databases = Databases(client);
final account = Account(client);

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback? onCartUpdated;

  CheckoutScreen({required this.cartItems, this.onCartUpdated});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Client _client;
  late Databases _databases;
  late Account _account;
  late Storage _storage; // Add Storage instance

  String userId = '';
  String address = 'Memuat alamat...';
  String _metodePembayaran = 'COD';
  bool _isProcessingOrder = false;
  String _catatanTambahan = '';
  bool _isLoadingAddress = true;
  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String cartsCollectionId = '68407db7002d8716c9d0';
  final String addressCollectionId = '68447d3d0007b5f75cc5';
  final String paymentProofBucketId = '681aa16f003054da8969';

  String? _qrisImageUrl =
      'https://fra.cloud.appwrite.io/v1/storage/buckets/681aa16f003054da8969/files/685cf51a0024c374db5e/view?project=681aa0b70002469fc157&mode=admin'; // QRIS image URL
  XFile? _selectedPaymentProof; // To store selected payment proof image

  // Add the formatPrice function from KeranjangScreen
  String formatPrice(dynamic price) {
    String priceStr = price.toString();
    if (price is double) priceStr = price.toInt().toString();

    String result = '';
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = '${priceStr[i]}$result';
      count++;
    }
    return result;
  }

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
    _storage = Storage(_client); // Initialize Storage

    await _getCurrentUser();
    if (userId.isNotEmpty) {
      await _fetchUserAddress();
    }
  }

  // Updated method to update both local state and database
  void _updateQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) return;
    // Update local state immediately for better UX
    setState(() {
      widget.cartItems[index]['quantity'] = newQuantity;
    });
    try {
      // Update database
      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('productId', widget.cartItems[index]['productId']),
        ],
      );
      if (docs.documents.isNotEmpty) {
        final docId = docs.documents.first.$id;
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: docId,
          data: {
            'quantity': newQuantity,
          },
        );
        // Notify cart screen about the update
        if (widget.onCartUpdated != null) {
          widget.onCartUpdated!();
        }
      }
    } catch (e) {
      print('Error updating cart item quantity: $e');
      // Revert local state if database update fails
      setState(() {
        widget.cartItems[index]['quantity'] = widget.cartItems[index]
                ['quantity'] -
            (newQuantity - widget.cartItems[index]['quantity']);
      });
    }
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
      print('User ID: $userId');
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
    if (userId.isEmpty) {
      print('User ID kosong, tidak dapat mengambil alamat');
      return;
    }

    setState(() {
      _isLoadingAddress = true;
    });
    try {
      print('Mencari alamat untuk user ID: $userId');
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: addressCollectionId,
        queries: [
          Query.equal('user_id', userId),
        ],
      );
      print(
          'Hasil pencarian alamat: ${result.documents.length} dokumen ditemukan');
      if (result.documents.isNotEmpty) {
        String foundAddress =
            result.documents.first.data['address'] ?? 'Alamat tidak tersedia';
        setState(() {
          address = foundAddress;
          _isLoadingAddress = false;
        });
        print('Alamat ditemukan: $foundAddress');
      } else {
        setState(() {
          address = 'Alamat belum diatur';
          _isLoadingAddress = false;
        });
        print('Tidak ada alamat ditemukan untuk user ini');
      }
    } catch (e) {
      print('Error fetching address: $e');
      setState(() {
        address = 'Error mengambil alamat';
        _isLoadingAddress = false;
      });
    }
  }

  // Method untuk navigate ke halaman alamat dan refresh alamat setelah kembali
  void _navigateToAddressScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlamatScreen()),
    );
    // Refresh alamat setelah kembali dari halaman alamat
    print('Kembali dari halaman alamat dengan result: $result');
    await _fetchUserAddress();
  }

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _selectedPaymentProof = image;
      });
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bukti pembayaran dipilih: ${image.name}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          address == 'Alamat belum diatur' ||
          address == 'Alamat tidak tersedia' ||
          address == 'Error mengambil alamat' ||
          address == 'Memuat alamat...') {
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

      // Validasi bukti pembayaran jika metode pembayaran adalah QRIS
      String? paymentProofUrl;
      if (_metodePembayaran == 'QRIS') {
        if (_selectedPaymentProof == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Harap unggah bukti pembayaran untuk QRIS'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        // Upload image to Appwrite Storage
        try {
          final file = await _storage.createFile(
            bucketId: paymentProofBucketId,
            fileId: ID.unique(),
            file: InputFile.fromPath(path: _selectedPaymentProof!.path),
          );
          paymentProofUrl =
              'https://fra.cloud.appwrite.io/v1/storage/buckets/$paymentProofBucketId/files/${file.$id}/view?project=$projectId';
          print('Payment proof uploaded: $paymentProofUrl');
        } catch (e) {
          print('Error uploading payment proof: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengunggah bukti pembayaran: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
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

      String orderTimestamp = DateTime.now().toIso8601String();
      final data = {
        'userId': user.$id,
        'orderId': orderId,
        'alamat': address,
        'produk': produkJsonString,
        'metodePembayaran': _metodePembayaran,
        'total': totalPriceWithShipping,
        'tanggal': orderTimestamp,
        'status': 'menunggu',
        'paymentProofUrl': paymentProofUrl,
        'catatanTambahan': _catatanTambahan,
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

  void _showQrisImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QRIS Pembayaran'),
        content: _qrisImageUrl != null
            ? Image.network(_qrisImageUrl!)
            : Text('Gambar QRIS tidak tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
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
                child: _isLoadingAddress
                    ? Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0072BC),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Memuat alamat...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      )
                    : Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          color: address == 'Alamat belum diatur' ||
                                  address == 'Error mengambil alamat'
                              ? Colors.red
                              : Colors.grey[700],
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
                                  'Rp ${formatPrice(widget.cartItems[index]['price'] ?? 0)}',
                                  style: TextStyle(color: Color(0xFF0072BC)),
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
              SizedBox(height: 10),
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
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _catatanTambahan = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Tinggalkan catatan',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                          ),
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
                                // Clear selected payment proof if not QRIS
                                if (value != 'QRIS') {
                                  _selectedPaymentProof = null;
                                }
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
                      if (_metodePembayaran == 'QRIS') ...[
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('QRIS Payment:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: _showQrisImage,
                              child: Text(
                                'Buka',
                                style: TextStyle(
                                  color: Color(0xFF0072BC),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Center(
                              child: Text(
                                _selectedPaymentProof != null
                                    ? 'Bukti Terpilih: ${_selectedPaymentProof!.name}'
                                    : 'Kirim bukti pembayaran',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pesanan:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp ${formatPrice(totalPrice)}',
                              style: TextStyle(color: Color(0xFF0072BC))),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Biaya Pengiriman:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp ${formatPrice(5000)}',
                              style: TextStyle(color: Color(0xFF0072BC))),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp ${formatPrice(totalPrice2)}',
                              style: TextStyle(color: Color(0xFF0072BC))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
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
                        _isProcessingOrder ? Colors.grey : Color(0xFF8DC63F),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
