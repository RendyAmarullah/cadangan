import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/KeranjangScreen.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final Client _client = Client();
  late Databases _databases;
  late Account _account;

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String productsCollectionId = '68407bab00235ecda20d';
  final String cartsCollectionId = '68407db7002d8716c9d0';
  final String favoritesCollectionId = '685adb7f00015bc4ec5f';

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> favoriteItems = [];
  Set<String> favoriteProductIds = {};
  Map<String, int> productQuantities = {};
  String userId = '';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  String formatPrice(dynamic price) {
    String priceStr = price.toString();

    // Tambahkan titik setiap 3 digit dari belakang
    String result = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.' + result;
        count = 0;
      }
      result = priceStr[i] + result;
      count++;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
    await _fetchFavorites();
    setState(() {
      isLoading = false;
    });
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

  Future<void> _fetchFavorites() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: favoritesCollectionId,
        queries: [Query.equal('userIds', userId)],
      );

      setState(() {
        favoriteItems = result.documents.map((doc) => doc.data).toList();
        favoriteProductIds =
            favoriteItems.map((item) => item['productId'].toString()).toSet();
      });
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    final productId = product['\$id'];

    try {
      final existingFavorites = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: favoritesCollectionId,
        queries: [
          Query.equal('userIds', userId),
          Query.equal('productId', productId),
        ],
      );

      if (existingFavorites.documents.isNotEmpty) {
        // Hapus dari favorit
        final docId = existingFavorites.documents.first.$id;
        await _databases.deleteDocument(
          databaseId: databaseId,
          collectionId: favoritesCollectionId,
          documentId: docId,
        );

        setState(() {
          favoriteItems.removeWhere((item) => item['productId'] == productId);
          favoriteProductIds.remove(productId);
        });

        _showSnackBar('${product['name']} dihapus dari favorit', Colors.orange);
      } else {
        // Tambahkan ke favorit
        final newFavorite = {
          'userIds': userId,
          'productId': productId,
          'name': product['name'],
          'price': product['price'],
          'productImageUrl': product['productImageUrl'],
        };

        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: favoritesCollectionId,
          documentId: ID.unique(),
          data: newFavorite,
        );

        setState(() {
          favoriteItems.add(newFavorite);
          favoriteProductIds.add(productId);
        });

        _showSnackBar(
            '${product['name']} ditambahkan ke favorit', Colors.green);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      _showSnackBar('Gagal mengubah favorit. Silakan coba lagi.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchProducts() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: productsCollectionId,
        queries: [
          Query.equal('category', ['market'])
        ],
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
      final result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      setState(() {
        productQuantities.clear();
        for (var doc in result.documents) {
          productQuantities[doc.data['productId']] = doc.data['quantity'];
        }
      });
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  Future<void> _addToCartWithQuantity(
      Map<String, dynamic> product, int quantity) async {
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
        // Update quantity
        final docId = existingItems.documents.first.$id;
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: docId,
          data: {'quantity': quantity},
        );
      } else {
        // Buat dokumen baru
        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: cartsCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': userId,
            'productId': product['\$id'],
            'name': product['name'],
            'price': product['price'],
            'quantity': quantity,
            'productImageUrl': product['productImageUrl'],
          },
        );
      }

      setState(() {
        productQuantities[product['\$id']] = quantity;
      });
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  void _showProductDetail(Map<String, dynamic> product) async {
    await _fetchCart();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int displayQty = productQuantities[product['\$id']] ?? 1;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              maxChildSize: 0.95,
              initialChildSize: 0.7,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.network(
                            product['productImageUrl'],
                            height: 180,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          product['name'],
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product['deskripsi'] ?? 'Tidak Ada Deskripsi',
                          style: TextStyle(color: Colors.black87),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Rp ${formatPrice(product['price'])}'),
                            Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: Color(0xFF0072BC),
                                      size: 25,
                                    ),
                                    onPressed: displayQty > 1
                                        ? () =>
                                            setModalState(() => displayQty--)
                                        : null,
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      displayQty.toString(),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 20,
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    icon: Icon(
                                      Icons.add_circle_outlined,
                                      color: Color(0xFF0072BC),
                                      size: 25,
                                    ),
                                    onPressed: () =>
                                        setModalState(() => displayQty++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8DC63F),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await _addToCartWithQuantity(product, displayQty);
                              Navigator.pop(context);
                            },
                            child: Text(
                              productQuantities[product['\$id']] != null
                                  ? 'Update Keranjang'
                                  : 'Tambahkan Ke Keranjang',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((product) {
      final name = product['name'].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0072BC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Text(
          'Market',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                          child:
                              Icon(Icons.clear, color: Colors.grey, size: 20),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(child: Text('Tidak ada produk ditemukan.'))
                    : ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          var product = filteredProducts[index];
                          bool isFavorite = favoriteItems.any(
                              (item) => item['productId'] == product['\$id']);

                          return GestureDetector(
                            onTap: () => _showProductDetail(product),
                            child: Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product['productImageUrl'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                          Text(
                                            'Rp ${formatPrice(product['price'])}',
                                            style: TextStyle(fontSize: 15),
                                          )
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.grey,
                                        size: 28,
                                      ),
                                      onPressed: () => _toggleFavorite(product),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KeranjangScreen()),
          );
          await _fetchCart();
        },
        child: Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 30),
        backgroundColor: Color(0xFF0072BC),
      ),
    );
  }
}
