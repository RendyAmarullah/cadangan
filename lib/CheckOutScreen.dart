import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/AlamatScreen.dart';
import 'package:pemesanan/main.dart';

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
  late Storage _storage;

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
  final String ordersCollectionId = '684b33e80033b767b024';

  String? _qrisImageUrl =
      'https://fra.cloud.appwrite.io/v1/storage/buckets/681aa16f003054da8969/files/685cf51a0024c374db5e/view?project=681aa0b70002469fc157&mode=admin';
  XFile? _selectedPaymentProof;

  @override
  void initState() {
    super.initState();
    _initAppwrite();
  }

  void _initAppwrite() async {
    _client = Client()
      ..setEndpoint('https://fra.cloud.appwrite.io/v1')
      ..setProject(projectId)
      ..setSelfSigned(status: true);

    _databases = Databases(_client);
    _account = Account(_client);
    _storage = Storage(_client);

    await _getCurrentUser();
    if (userId.isNotEmpty) {
      await _fetchUserAddress();
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      final models.User user = await _account.get();
      setState(() {
        userId = user.$id;
      });
    } catch (e) {
      print('Gagal mendapatkan info pengguna: $e');
    }
  }

  Future<void> _fetchUserAddress() async {
    if (userId.isEmpty) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: addressCollectionId,
        queries: [Query.equal('user_id', userId)],
      );

      if (result.documents.isNotEmpty) {
        setState(() {
          address =
              result.documents.first.data['address'] ?? 'Alamat tidak tersedia';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          address = 'Alamat belum diatur';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        address = 'Gagal mengambil alamat';
        _isLoadingAddress = false;
      });
    }
  }

  void _updateQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) return;

    setState(() {
      widget.cartItems[index]['quantity'] = newQuantity;
    });

    try {
      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('productId', widget.cartItems[index]['productId']),
        ],
      );

      if (docs.documents.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: docs.documents.first.$id,
          data: {'quantity': newQuantity},
        );
        widget.onCartUpdated?.call();
      }
    } catch (e) {
      setState(() {
        widget.cartItems[index]['quantity'] = widget.cartItems[index]
                ['quantity'] -
            (newQuantity - widget.cartItems[index]['quantity']);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCartItems() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      for (var doc in result.documents) {
        await _databases.deleteDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: doc.$id,
        );
      }
    } catch (e) {
      print('Tidak dapat menghapus produk di keranjang: $e');
    }
  }

  String _generateOrderId() {
    final random = Random();
    final randomDigits = random.nextInt(9000) + 1000;
    return 'MGH$randomDigits';
  }

  Future<void> _createOrder() async {
    if (_isProcessingOrder) return;

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      if (_isInvalidAddress()) {
        _showSnackBar(
            'Silakan pilih alamat pengiriman terlebih dahulu', Colors.red);
        return;
      }

      if (widget.cartItems.isEmpty) {
        _showSnackBar('Keranjang kosong', Colors.red);
        return;
      }

      String? paymentProofUrl;
      if (_metodePembayaran == 'QRIS') {
        paymentProofUrl = await _uploadPaymentProof();
        if (paymentProofUrl == null) return;
      }

      final user = await _account.get();
      final orderData = await _buildOrderData(user, paymentProofUrl);

      final response = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        documentId: ID.unique(),
        data: orderData,
      );

      await _clearCartItems();

      if (mounted) {
        _showSnackBar(
            'Pesanan berhasil dibuat! Order ID: ${orderData['orderId']}',
            Colors.green);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(userId: user.$id)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membuat pesanan. Silakan coba lagi.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }

  bool _isInvalidAddress() {
    return address.isEmpty ||
        address == 'Alamat belum diatur' ||
        address == 'Alamat tidak tersedia' ||
        address == 'Gagal mengambil alamat' ||
        address == 'Memuat alamat...';
  }

  Future<String?> _uploadPaymentProof() async {
    if (_selectedPaymentProof == null) {
      _showSnackBar('Harap unggah bukti pembayaran untuk QRIS', Colors.red);
      return null;
    }

    try {
      final file = await _storage.createFile(
        bucketId: paymentProofBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: _selectedPaymentProof!.path),
      );
      return 'https://fra.cloud.appwrite.io/v1/storage/buckets/$paymentProofBucketId/files/${file.$id}/view?project=$projectId';
    } catch (e) {
      _showSnackBar('Gagal mengunggah bukti pembayaran: $e', Colors.red);
      return null;
    }
  }

  Future<Map<String, dynamic>> _buildOrderData(
      models.User user, String? paymentProofUrl) async {
    final produkList = widget.cartItems
        .map((item) => {
              'name': item['name'] ?? 'Produk',
              'jumlah': item['quantity'] ?? 1,
              'harga': item['price'] ?? 0,
              'productImageUrl': item['productImageUrl'] ?? ''
            })
        .toList();

    int totalPrice = _calculateTotalPrice();
    int totalPriceWithShipping = totalPrice + 5000;

    return {
      'userId': user.$id,
      'orderId': _generateOrderId(),
      'alamat': address,
      'produk': jsonEncode(produkList),
      'metodePembayaran': _metodePembayaran,
      'total': totalPriceWithShipping,
      'tanggal': DateTime.now().toIso8601String(),
      'status': 'menunggu',
      'paymentProofUrl': paymentProofUrl,
      'catatanTambahan': _catatanTambahan,
    };
  }

  int _calculateTotalPrice() {
    return widget.cartItems.fold<int>(0, (sum, item) {
      int price = item['price'] is int ? item['price'] : 0;
      int quantity = item['quantity'] is int ? item['quantity'] : 1;
      return sum + price * quantity;
    });
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

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

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Pesanan'),
          content: Text('Apakah Anda yakin ingin membuat pesanan?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
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

  void _navigateToAddressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlamatScreen()),
    );
    await _fetchUserAddress();
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = _calculateTotalPrice();
    int totalPriceWithShipping = totalPrice + 5000;

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
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildAddressSection(),
              SizedBox(height: 10),
              _buildCartItemsSection(),
              SizedBox(height: 10),
              _buildNotesSection(),
              SizedBox(height: 10),
              _buildPaymentSection(totalPrice, totalPriceWithShipping),
              SizedBox(height: 20),
              _buildOrderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0072BC)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Memuat alamat...',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                )
              : Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isInvalidAddress() ? Colors.red : Colors.grey[700],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCartItemsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: widget.cartItems.length,
        itemBuilder: (context, index) => _buildCartItem(index),
      ),
    );
  }

  Widget _buildCartItem(int index) {
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
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                widget.cartItems[index]['productImageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 25,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
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
                            AlwaysStoppedAnimation<Color>(Color(0xFF0072BC)),
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
                Text(widget.cartItems[index]['name'] ?? 'Product'),
                SizedBox(height: 5),
                Text(
                  'Rp ${formatPrice(widget.cartItems[index]['price'] ?? 0)}',
                  style: TextStyle(color: Color(0xFF0072BC)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFF0072BC),
                        size: 25,
                      ),
                      onPressed: () {
                        if (quantity > 1) {
                          _updateQuantity(index, quantity - 1);
                        }
                      },
                    ),
                    Text(quantity.toString()),
                    IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.add_circle_outlined,
                        color: Color(0xFF0072BC),
                        size: 25,
                      ),
                      onPressed: () => _updateQuantity(index, quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Catatan Tambahan:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _catatanTambahan = value),
                decoration: InputDecoration(
                  hintText: 'Tinggalkan catatan',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                style: TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.right,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(int totalPrice, int totalPriceWithShipping) {
    return Container(
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
                      if (value != 'QRIS') {
                        _selectedPaymentProof = null;
                      }
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                        value: 'COD', child: Text('COD')),
                    const PopupMenuItem<String>(
                        value: 'QRIS', child: Text('QRIS')),
                  ],
                  child: Text(
                    '$_metodePembayaran >',
                    style: TextStyle(
                      color: Color(0xFF0072BC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp ${formatPrice(totalPriceWithShipping)}',
                    style: TextStyle(color: Color(0xFF0072BC))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton() {
    return ElevatedButton(
      onPressed: _isProcessingOrder
          ? null
          : () async {
              bool? isConfirmed = await _showConfirmationDialog();
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text('Buat Pesanan', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isProcessingOrder ? Colors.grey : Color(0xFF8DC63F),
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
