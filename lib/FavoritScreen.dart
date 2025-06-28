import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final Client _client = Client();
  late Databases _databases;
  late Account _account;

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String favoritesCollectionId =
      '685adb7f00015bc4ec5f'; // Collection untuk favorit

  List<Map<String, dynamic>> favoriteItems = [];
  String userId = '';
  bool isLoading = true;

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
        queries: [
          Query.equal('userIds', userId), // Menggunakan 'userId' sebagai filter
        ],
      );

      setState(() {
        favoriteItems = result.documents.map((doc) => doc.data).toList();
      });
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  // Fungsi untuk menghapus produk dari favorit
  Future<void> _removeFromFavorites(String docId) async {
    try {
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: favoritesCollectionId,
        documentId: docId,
      );

      setState(() {
        // Hapus produk yang dihapus dari favorit
        favoriteItems.removeWhere((item) => item['\$id'] == docId);
      });
    } catch (e) {
      print('Error removing from favorites: $e');
    }
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
          'Favorit Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoriteItems.isEmpty
              ? Center(child: Text('Tidak ada produk favorit.'))
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: favoriteItems.length,
                  itemBuilder: (context, index) {
                    var product = favoriteItems[index];
                    var docId = product['\$id']; // Ambil ID dokumen

                    return GestureDetector(
                      onTap: () {
                        // Anda bisa menambahkan logika untuk membuka detail produk
                      },
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    Text(
                                      'Rp ${product['price']}',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  // Menghapus item dari daftar favorit
                                  await _removeFromFavorites(docId);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
