import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'dart:convert';

class HomeScreenKaryawan extends StatefulWidget {
  @override
  _HomeScreenKaryawanState createState() => _HomeScreenKaryawanState();
}

class _HomeScreenKaryawanState extends State<HomeScreenKaryawan> {
  Account? account;
  Client client = Client();
  Databases? databases;
  String? _userName;
  String? _email;
  List<Map<String, dynamic>> _orders = [];
  final String profil = '684083800031dfaaecad';
  final String ordersCollectionId = '684b33e80033b767b024';
  String userId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157')
        .setSelfSigned(status: true);
    account = Account(client);
    databases = Databases(client);
    _loadProfileData();
    _loadOrders();
  }

  // Fungsi untuk validasi koneksi
  Future<bool> _checkConnection() async {
    try {
      await databases!.listDocuments(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        queries: [Query.limit(1)],
      );
      return true;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  // Fungsi load orders dengan error handling yang lebih baik
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool hasConnection = await _checkConnection();
      if (!hasConnection) {
        throw Exception('Tidak ada koneksi internet');
      }

      final response = await databases!.listDocuments(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('status', 'menunggu'),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );

      print('Orders loaded: ${response.documents.length}'); // Debug log

      setState(() {
        _orders = response.documents.map((doc) {
          List<dynamic> products = [];
          if (doc.data['produk'] != null) {
            if (doc.data['produk'] is String) {
              try {
                products = jsonDecode(doc.data['produk']);
              } catch (e) {
                print('Error parsing produk JSON: $e');
                products = [];
              }
            } else if (doc.data['produk'] is List) {
              products = doc.data['produk'];
            }
          }

          return {
            'userId': doc.data['userId'] ?? '',
            'alamat': doc.data['alamat'] ?? '',
            'produk': products,
            'metodePembayaran': doc.data['metodePembayaran'] ?? 'COD',
            'total': doc.data['total'] ?? 0,
            'orderId': doc.$id,
            'createdAt':
                doc.data['createdAt'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error mengambil data pesanan: $e');
      setState(() {
        _isLoading = false;
      });

      // Tampilkan error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pesanan: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _loadOrders,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = await account!.get();
      setState(() {
        _email = user.email;
        userId = user.$id; // Set userId here
      });

      print('User ID: $userId'); // Debug log

      final profileDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: profil,
        documentId: userId,
      );
      setState(() {
        _userName = profileDoc.data['name'] ?? 'No name';
      });
    } catch (e) {
      print('Failed to load user profile: $e');
      // Jika gagal load profile, tetap coba ambil user ID
      try {
        final user = await account!.get();
        setState(() {
          _email = user.email;
          userId = user.$id;
        });
      } catch (e2) {
        print('Failed to get user: $e2');
      }
    }
  }

  // Fungsi accept order dengan perbaikan
  Future<void> _acceptOrder(String orderId, int index) async {
    try {
      print('Accepting order: $orderId with userId: $userId'); // Debug log

      // Tampilkan loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Memproses pesanan...'),
            ],
          ),
        ),
      );

      // Validasi userId
      if (userId.isEmpty) {
        Navigator.pop(context); // Tutup loading dialog
        throw Exception('User ID tidak valid. Silakan login ulang.');
      }

      // Ambil data order yang akan diproses
      final orderDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
      );

      print('Order status: ${orderDoc.data['status']}'); // Debug log

      // Validasi apakah order masih ada dan statusnya masih 'menunggu'
      if (orderDoc.data['status'] != 'menunggu') {
        Navigator.pop(context);
        throw Exception('Order sudah diproses oleh orang lain');
      }

      // Proses data produk dengan validasi
      List<dynamic> products = [];
      if (orderDoc.data['produk'] != null) {
        if (orderDoc.data['produk'] is String) {
          try {
            products = jsonDecode(orderDoc.data['produk']);
          } catch (e) {
            print('Error parsing produk JSON: $e');
            products = [];
          }
        } else if (orderDoc.data['produk'] is List) {
          products = orderDoc.data['produk'];
        }
      }

      String productsJson = jsonEncode(products);

      await databases!.createDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: '6854b40600020e4a49aa',
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'orderId': orderId,
          'alamat': orderDoc.data['alamat'] ?? '',
          'produk': productsJson,
          'metodePembayaran': orderDoc.data['metodePembayaran'] ?? 'COD',
          'total': orderDoc.data['total'] ?? 0,
          'status': 'sedang diproses',
          'createdAt': DateTime.now().toIso8601String(),
          'acceptedByy': userId,
          'acceptedAt': DateTime.now().toIso8601String(),
        },
      );

      await databases!.updateDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
        data: {
          'status': 'sedang diproses',
          'acceptedByy': userId,
          'acceptedAt': DateTime.now().toIso8601String(),
        },
      );

      Navigator.pop(context);

      setState(() {
        _orders.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${_formatOrderId(orderId)} berhasil diterima'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print(
          'Pesanan #$orderId berhasil diterima dan dipindahkan ke sedang diproses');
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error menerima pesanan: $e');

      String errorMessage = 'Gagal menerima pesanan';
      if (e.toString().contains('User ID tidak valid')) {
        errorMessage = 'Sesi Anda telah berakhir, silakan login ulang';
      } else if (e.toString().contains('sudah diproses')) {
        errorMessage = 'Pesanan sudah diproses oleh orang lain';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Koneksi bermasalah, coba lagi';
      } else if (e.toString().contains('AppwriteException')) {
        errorMessage = 'Error server: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId, int index) async {
    try {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin ingin menolak pesanan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Tolak'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      print('Rejecting order: $orderId with userId: $userId');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Menolak pesanan...'),
            ],
          ),
        ),
      );

      if (userId.isEmpty) {
        Navigator.pop(context);
        throw Exception('User ID tidak valid. Silakan login ulang.');
      }

      final orderDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
      );

      if (orderDoc.data['status'] != 'menunggu') {
        Navigator.pop(context);
        throw Exception('Order sudah diproses oleh orang lain');
      }

      List<dynamic> products = [];
      if (orderDoc.data['produk'] != null) {
        if (orderDoc.data['produk'] is String) {
          try {
            products = jsonDecode(orderDoc.data['produk']);
          } catch (e) {
            print('Error parsing produk JSON: $e');
            products = [];
          }
        } else if (orderDoc.data['produk'] is List) {
          products = orderDoc.data['produk'];
        }
      }

      String productsJson = jsonEncode(products);

      await databases!.createDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: '6854ba6e003bad3da579',
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'orderId': orderId,
          'alamat': orderDoc.data['alamat'] ?? '',
          'produk': productsJson,
          'metodePembayaran': orderDoc.data['metodePembayaran'] ?? 'COD',
          'total': orderDoc.data['total'] ?? 0,
          'status': 'ditolak',
          'createdAt': DateTime.now().toIso8601String(),
          'rejectedBy': userId,
          'rejectedAt': DateTime.now().toIso8601String(),
        },
      );

      await databases!.updateDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
        data: {
          'status': 'ditolak',
          'rejectedBy': userId,
          'rejectedAt': DateTime.now().toIso8601String(),
        },
      );

      Navigator.pop(context);

      setState(() {
        _orders.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${_formatOrderId(orderId)} berhasil ditolak'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      print('Pesanan #$orderId berhasil ditolak');
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error menolak pesanan: $e');

      String errorMessage = 'Gagal menolak pesanan';
      if (e.toString().contains('User ID tidak valid')) {
        errorMessage = 'Sesi Anda telah berakhir, silakan login ulang';
      } else if (e.toString().contains('sudah diproses')) {
        errorMessage = 'Pesanan sudah diproses oleh orang lain';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Koneksi bermasalah, coba lagi';
      } else if (e.toString().contains('AppwriteException')) {
        errorMessage = 'Error server: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatOrderId(String orderId) {
    return '#${orderId.substring(0, 10)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              child: Image.asset('images/logotanpanama.png'),
            ),
            SizedBox(width: 8),
            Text(
              '안녕하세요, ${_userName ?? 'Guest'}',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat pesanan...'),
                  ],
                ),
              )
            : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada pesanan menunggu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      var order = _orders[index];
                      List<dynamic> products = order['produk'];

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatOrderId(order['orderId']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Menunggu',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Alamat
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Alamat: ${order['alamat']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),

                              // Produk
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        ...products
                                            .map((product) => Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 8, top: 4),
                                                  child: Text(
                                                    '• ${product['nama']} (${product['jumlah']}x)',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Total dan COD
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'COD',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(order['total']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _rejectOrder(order['orderId'], index),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'Tolak',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _acceptOrder(order['orderId'], index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'Terima',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
