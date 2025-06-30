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
  final String bucketId = '681aa16f003054da8969';

  String userId = '';
  List<Map<String, dynamic>> cartItems = [];

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
      print('Error fetching cart: $e');
    }
  }

  String getImageUrl(String fileId) {
    String appwriteEndpoint = 'https://fra.cloud.appwrite.io/v1';
    return '$fileId';
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
      print('Error updating cart item quantity: $e');
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
      print('Error deleting cart item: $e');
    }
  }

  Future<void> _clearCart() async {
    try {
      // Get all cart documents for this user
      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      // Delete each document
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
      print('Error clearing cart: $e');
    }
  }

  void _showClearCartDialog() {
    if (cartItems.isEmpty) {
      // Show notification when cart is empty
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Belum ada produk di keranjangmu'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Show confirmation dialog when cart has items
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('Yakin ingin mengosongkan keranjang?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('Tidak'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  _clearCart(); // Clear the cart
                },
                child: Text('Ya'),
              ),
            ],
          );
        },
      );
    }
  }

  // Method untuk refresh cart items setelah kembali dari checkout
  void _refreshCartItems() async {
    await _fetchCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with total items and clear cart option - Always visible
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: _showClearCartDialog,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: Colors.red[800],
                        size: 25,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider line - Always visible
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),

          // Cart items list
          Expanded(
            child: cartItems.isEmpty
                ? Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      int quantity = cartItems[index]['quantity'] ?? 1;
                      String imageUrl = '';
                      if (cartItems[index].containsKey('productImageUrl')) {
                        imageUrl =
                            getImageUrl(cartItems[index]['productImageUrl']);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0), // Reduced vertical padding
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(7),
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
                                                  BorderRadius.circular(7),
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
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 12), // Reduced spacing
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 4, // Reduced spacing
                                  ),
                                  Text(
                                    cartItems[index]['name'] ?? 'Produk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14, // Reduced from 16 to 14
                                    ),
                                  ),
                                  SizedBox(height: 2), // Reduced spacing
                                  Text('Rp ${cartItems[index]['price'] ?? '-'}',
                                      style: TextStyle(
                                        color: Color(0xFF8DC63F),
                                        fontSize: 12, // Added smaller font size
                                      )),
                                  SizedBox(height: 4), // Reduced spacing
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        iconSize: 20, // Smaller button
                                        padding: EdgeInsets.all(
                                            4), // Reduced padding
                                        constraints: BoxConstraints(
                                          minWidth: 32, // Smaller minimum width
                                          minHeight:
                                              32, // Smaller minimum height
                                        ),
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: Color(0xFF0072BC),
                                          size: 30, // Smaller icon size
                                        ),
                                        onPressed: () {
                                          if (quantity > 0) {
                                            _updateCartItemQuantity(
                                                index, quantity - 1);
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8), // Reduced spacing
                                        child: Text(
                                          quantity.toString(),
                                          style: TextStyle(
                                              fontSize: 14), // Smaller text
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 20, // Smaller button
                                        padding: EdgeInsets.all(
                                            4), // Reduced padding
                                        constraints: BoxConstraints(
                                          minWidth: 32, // Smaller minimum width
                                          minHeight:
                                              32, // Smaller minimum height
                                        ),
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF8DC63F),
                                          size: 30, // Smaller icon size
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
                  // Navigate to CheckoutScreen and wait for result
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        cartItems: cartItems,
                        onCartUpdated: _refreshCartItems, // Pass callback
                      ),
                    ),
                  );

                  // Refresh cart items when returning from checkout
                  _refreshCartItems();
                },
                child: Text(
                  'Check Out',
                  style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8DC63F), // Checkout button color
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            )
          : null, // Hide checkout button when cart is empty
    );
  }
}
