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
      body: cartItems.isEmpty
          ? Center(child: Text('Keranjang kosong'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                int quantity = cartItems[index]['quantity'] ?? 1;
                String imageUrl = '';
                if (cartItems[index].containsKey('productImageUrl')) {
                  imageUrl = getImageUrl(cartItems[index]['productImageUrl']);
                }

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
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          
                          child: imageUrl.isNotEmpty
                              ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover))
                              : Center(
                                  child:
                                      Icon(Icons.image, color: Colors.white)),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8,),
                              Text(
                                cartItems[index]['name'] ?? 'Produk',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('Rp ${cartItems[index]['price'] ?? '-'}',style: TextStyle(color: Colors.green)),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Container( padding: EdgeInsets.all(1),  
                                        decoration: BoxDecoration(
                                          color: Colors.green,  
                                           borderRadius: BorderRadius.zero,
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          color: Colors.white,  // Icon color (white in this case)
                                        ),
                                        
                                        ),
                                    onPressed: () {
                                      if (quantity > 0) {
                                        _updateCartItemQuantity(
                                            index, quantity - 1);
                                      }
                                    },
                                  ),
                                  Text(quantity.toString()),
                                  IconButton(
                                    icon: Container( padding: EdgeInsets.all(1),  
                                        decoration: BoxDecoration(
                                          color: Colors.blue,  
                                           borderRadius: BorderRadius.zero,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,  // Icon color (white in this case)
                                        ),
                                        
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
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Navigate to CheckoutScreen and pass cartItems
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(cartItems: cartItems),
              ),
            );
          },
          child: Text('Checkout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Checkout button color
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}
