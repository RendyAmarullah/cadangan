import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/CheckOutScreen.dart';

class KeranjangScreen extends StatefulWidget {
  @override
  _KeranjangScreenState createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final Client _client = Client();
  late Databases _databases;
  late Account _account;

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String cartsCollectionId = '68407db7002d8716c9d0';

  String userId = '';
  List<Map<String, dynamic>> cartItems = [];

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
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _databases = Databases(_client);
    _account = Account(_client);

    await _getCurrentUser();
    await _fetchCartItems();
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

  Future<void> _fetchCartItems() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      setState(() {
        cartItems = result.documents.map((doc) => doc.data).toList();
      });
    } catch (e) {
      print('Gagal memuat keranjang: $e');
    }
  }

  Future<void> _updateCartItemQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) {
      _deleteCartItem(index);
      return;
    }

    try {
      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('productId', cartItems[index]['productId']),
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

        setState(() {
          cartItems[index]['quantity'] = newQuantity;
        });
      }
    } catch (e) {
      print('Gagal menambah jumlah produk: $e');
    }
  }

  Future<void> _deleteCartItem(int index) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('productId', cartItems[index]['productId']),
        ],
      );

      if (docs.documents.isNotEmpty) {
        final docId = docs.documents.first.$id;

        await _databases.deleteDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: docId,
        );

        setState(() {
          cartItems.removeAt(index);
        });
      }
    } catch (e) {
      print('Terjadi kesalahan saat menghapus item keranjang: $e');
    }
  }

  Future<void> _clearCart() async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      for (var doc in docs.documents) {
        await _databases.deleteDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: doc.$id,
        );
      }

      setState(() {
        cartItems.clear();
      });
    } catch (e) {
      print('Terjadi kesalahan saat mengosongkan keranjang: $e');
    }
  }

  void _showClearCartDialog() {
    if (cartItems.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Belum ada produk di keranjangmu'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Yakin ingin mengosongkan keranjang?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Tidak'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearCart();
                },
                child: Text('Ya'),
              ),
            ],
          );
        },
      );
    }
  }

  void _refreshCartItems() async {
    await _fetchCartItems();
  }

  @override
  Widget build(BuildContext context) {
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
            'Keranjang',
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cartItems.isEmpty
                      ? 'Total Item: '
                      : 'Total Item: ${cartItems.length}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: _showClearCartDialog,
                  child: Icon(
                    Icons.delete,
                    color: Colors.red[800],
                    size: 25,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      int quantity = cartItems[index]['quantity'] ?? 1;
                      String imageUrl =
                          cartItems[index]['productImageUrl'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[400],
                                              size: 30,
                                            ),
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color(0xFF0072BC),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    cartItems[index]['name'] ?? 'Produk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Rp ${formatPrice(cartItems[index]['price'] ?? 0)}',
                                    style: TextStyle(
                                      color: Color(0xFF0072BC),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        iconSize: 20,
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: Color(0xFF0072BC),
                                          size: 25,
                                        ),
                                        onPressed: () {
                                          if (quantity > 0) {
                                            _updateCartItemQuantity(
                                                index, quantity - 1);
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          quantity.toString(),
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 20,
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: Icon(
                                          Icons.add_circle_outlined,
                                          color: Color(0xFF0072BC),
                                          size: 25,
                                        ),
                                        onPressed: () {
                                          _updateCartItemQuantity(
                                              index, quantity + 1);
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
        ],
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        cartItems: cartItems,
                        onCartUpdated: _refreshCartItems,
                      ),
                    ),
                  );
                  _refreshCartItems();
                },
                child: Text(
                  'Check Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8DC63F),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
