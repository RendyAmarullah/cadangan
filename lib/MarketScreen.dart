import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/KeranjangScreen.dart';
import 'package:pemesanan/TambahBarangScreen.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final Client _client = Client();
  late Databases _databases;
  late Account _account;

  final String projectId = '681aa0b70002469fc157'; // Ganti dengan Project ID Anda
  final String databaseId = '681aa33a0023a8c7eb1f'; // Ganti dengan Database ID Anda
  final String productsCollectionId = '68407bab00235ecda20d'; // Ganti dengan Collection ID untuk produk
  final String cartsCollectionId = '68407db7002d8716c9d0'; // Ganti dengan Collection ID untuk keranjang
  final String bucketId = '681aa16f003054da8969'; // Ganti dengan Bucket ID Anda

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cartItems = [];
  String userId = '';

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
  }

  void _initializeAppwrite() async {
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1') // Ganti dengan endpoint Appwrite Anda
        .setProject(projectId)
        .setSelfSigned(status: true);

    _databases = Databases(_client);
    _account = Account(_client);

    await _getCurrentUser();
    await _fetchProducts();
    await _fetchCart();
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

  Future<void> _fetchProducts() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollectionId,
      );

      setState(() {
        products = result.documents.map((doc) => doc.data).toList();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _fetchCart() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      if (result.documents.isNotEmpty) {
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(result.documents.first.data['cartItems']);
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );

      if (result.documents.isNotEmpty) {
        // Update existing cart
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: result.documents.first.$id,
          data: {
            'cartItems': cartItems,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Create new cart
        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'cartItems': cartItems,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void tambahKeranjang(Map<String, dynamic> product) {
    int index = cartItems.indexWhere((item) => item['name'] == product['name']);

    if (index != -1) {
      setState(() {
        cartItems[index]['quantity'] += 1;
      });
    } else {
      setState(() {
        product['quantity'] = 1;
        cartItems.add(product);
      });
    }

    _saveCart();
  }

 String getImageUrl(String fileId) {
    String appwriteEndpoint = 'https://fra.cloud.appwrite.io/v1';  // Replace with your Appwrite endpoint
    String bucketId = '681aa16f003054da8969';  // Replace with your Appwrite bucket ID
    return '$fileId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: products.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  String imageUrl = getImageUrl(products[index]['productImageUrl']);

                  return Card(
                    color: Color(0xFF81C784),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: Colors.white,
                          height: 60,
                          width: double.infinity,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            products[index]['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Rp ${products[index]['price']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              tambahKeranjang(products[index]);
                              print('Added to cart: ${products[index]['name']}');
                            },
                            child: Text('Keranjang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahBarangScreen(),
            ),
          );
        },
        child: Icon(Icons.shopping_cart),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
