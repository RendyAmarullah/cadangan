import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/KeranjangScreen.dart';
import 'package:pemesanan/TambahBarangScreen.dart';

class BeautyScreen extends StatefulWidget {
  @override
  _BeautyScreenState createState() => _BeautyScreenState();
}

class _BeautyScreenState extends State<BeautyScreen> {
  final Client _client = Client();
  late Databases _databases;
  late Account _account;

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String productsCollectionId = '68407bab00235ecda20d';
  final String cartsCollectionId = '68407db7002d8716c9d0';
  final String bucketId = '681aa16f003054da8969';

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
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
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
      print('Error getting user: \$e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        queries: [
          Query.equal('category', 'Beauty'),
        ],
      );

      setState(() {
        products = result.documents.map((doc) => doc.data).toList();
      });
    } catch (e) {
      print('Error fetching products: \$e');
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
          cartItems = List<Map<String, dynamic>>.from(
              result.documents.first.data['cartItems']);
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  Future<void> tambahKeranjang(Map<String, dynamic> product) async {
    try {
      final existingItems = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('productId', product['\$id']),
        ],
      );

      if (existingItems.documents.isNotEmpty) {
        final docId = existingItems.documents.first.$id;
        final currentQty = existingItems.documents.first.data['quantity'] ?? 1;

        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: docId,
          data: {
            'quantity': currentQty + 1,
          },
        );
      } else {
        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'productId': product['\$id'],
            'name': product['name'],
            'price': product['price'],
            'quantity': 1,
            'productImageUrl': product['productImageUrl'],
          },
        );
      }

      print('Barang berhasil disimpan ke keranjang');
    } catch (e) {
      print('Error menyimpan ke keranjang: $e');
    }
  }

  String getImageUrl(String fileId) {
    return fileId;
  }

  void _showProductDetail(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Image.network(
                product['productImageUrl'],
                fit: BoxFit.cover,
                height: 350,
                width: double.infinity,
              ),
              SizedBox(height: 16),
              Text(
                'Rp ${product['price']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text(
                'Deskripsi: ${product['description'] ?? 'No description available'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                 
                  tambahKeranjang(product);

                 
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Barang berhasil ditambahkan ke keranjang'),
                      duration: Duration(seconds: 7),  
                    ),
                  );
                },
                child: Text('Tambahkan Ke Keranjang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
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
            'Beauty',
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
                  String imageUrl =
                      getImageUrl(products[index]['productImageUrl']);

                  return GestureDetector(
                    onTap: () {
                      _showProductDetail(products[index]);
                    },
                    child: Card(
                      color: Color(0xFF81C784),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: Colors.white,
                            height: 110,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
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
                            // child: ElevatedButton(
                            //   onPressed: () {
                            //     tambahKeranjang(products[index]);
                            //   },
                            //   child: Text('Keranjang'),
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: Colors.blue,
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(8),
                            //     ),
                            //   ),
                            // ),
                          ),
                        ],
                      ),
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
              builder: (context) => KeranjangScreen(),
            ),
          );
        },
        child: Icon(Icons.shopping_cart),
        backgroundColor: Color(0xFF0072BC),
      ),
    );
  }
}
