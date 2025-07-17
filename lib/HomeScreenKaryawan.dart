import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  Realtime? realtime;
  final StreamController<List<Map<String, dynamic>>> _ordersStreamController = StreamController<List<Map<String, dynamic>>>();
  Timer? _timer; 
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157')
        .setSelfSigned(status: true);
    account = Account(client);
    databases = Databases(client);
    realtime = Realtime(client);
    _loadProfileData();
    _loadOrders();
    _initializeRealtimeListener();
    _startAutoRefresh();
    _initializeNotifications();
    _listenForNewOrders();
  }


  void _listenForNewOrders() {
  realtime!.subscribe([
    'databases.681aa33a0023a8c7eb1f.collections.$ordersCollectionId.documents'
  ]).stream.listen((event) {
    // Jika ada pembaruan pada data pesanan
    if (event.events == 'documents.create') {
      Map<String, dynamic> newOrder = event.payload;
      _showNewOrderNotification(newOrder);  
      _vibrate();
    }
  });
}

Future<void> _showNewOrderNotification(Map<String, dynamic> updatedOrder) async {
  var androidDetails = AndroidNotificationDetails(
    'channel_id',
    'Notifikasi Pesanan',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  var generalNotificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Pesanan Baru',
    'Pesanan baru dengan ID ${updatedOrder['orderId']} telah diterima.',
    generalNotificationDetails,
  );
}


  void _initializeNotifications() {
    final androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: androidInitialization);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _loadOrders(); 
    });
  }
  void _vibrate() async {
    if (await Vibrate.canVibrate) {
      Vibrate.vibrate(); 
    }
  }

  
void _initializeRealtimeListener() {
  realtime!.subscribe([
    'databases.681aa33a0023a8c7eb1f.collections.$ordersCollectionId.documents'
  ]).stream.listen((response) {
    if (response.payload != null) {
      var updatedOrder = response.payload;

      if (updatedOrder is Map<String, dynamic>) {
        
        if (updatedOrder['status'] == 'menunggu' && !isProcessing) {
          setState(() {
            var existingIndex = _orders.indexWhere((order) => order['orderId'] == updatedOrder['orderId']);
            
            if (existingIndex >= 0) {
              _orders[existingIndex] = updatedOrder;
            } else {
              _orders.add(updatedOrder);
            }

            _ordersStreamController.add(List.from(_orders)); 
          });

          
          _showNewOrderNotification(updatedOrder);
          _vibrate();
        }
      }
    }
  });
}



  Future<bool> _checkConnection() async {
    try {
      await databases!.listDocuments(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        queries: [Query.limit(1)],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await databases!.listDocuments(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('status', 'menunggu'),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );

      setState(() {
        _orders = response.documents.map((doc) {
          List<dynamic> products = [];
          if (doc.data['produk'] != null) {
            if (doc.data['produk'] is String) {
              try {
                products = jsonDecode(doc.data['produk']);
              } catch (e) {
                products = [];
              }
            } else if (doc.data['produk'] is List) {
              products = doc.data['produk'];
            }
          }

          return {
            'userId': doc.data['userId'] ?? '',
            'nama': doc.data['nama'],
            'alamat': doc.data['alamat'] ?? '',
            'produk': products,
            'metodePembayaran': doc.data['metodePembayaran'] ?? 'COD',
            'total': doc.data['total'] ?? 0,
            'orderId': doc.$id,
            'orderId2': doc.data['orderId'],
            'createdAt': doc.data['createdAt'] ?? DateTime.now().toIso8601String(),
            'paymentProofUrl': doc.data['paymentProofUrl'] ?? '',
            'catatanTambahan': doc.data['catatanTambahan'],
          };
        }).toList();
        _isLoading = false;
        _ordersStreamController.add(_orders); // Add to stream
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        userId = user.$id;
      });

      final profileDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: profil,
        documentId: userId,
      );
      setState(() {
        _userName = profileDoc.data['name'] ?? 'No name';
      });
    } catch (e) {
      try {
        final user = await account!.get();
        setState(() {
          _email = user.email;
          userId = user.$id;
        });
      } catch (e2) {
        // Handle error if needed
      }
    }
  }

  Future<void> _acceptOrder(String orderId, int index) async {
    try {
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
            products = [];
          }
        } else if (orderDoc.data['produk'] is List) {
          products = orderDoc.data['produk'];
        }
      }

      String productsJson = jsonEncode(products);

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
          backgroundColor: Color(0xFF8DC63F),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

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
            products = [];
          }
        } else if (orderDoc.data['produk'] is List) {
          products = orderDoc.data['produk'];
        }
      }

      

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
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

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

  String _formatOrderId(String orderId2) {
    return '#${orderId2}';
  }

  void _showPaymentProof(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bukti Pembayaran'),
        content: imageUrl.isNotEmpty
            ? Image.network(imageUrl)
            : Text('Bukti pembayaran tidak tersedia.'),
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
  void dispose() {
    super.dispose();
    _ordersStreamController.close();
    _timer?.cancel();
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersStreamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat pesanan: ${snapshot.error}'));
          }

          var orders = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _loadOrders, 
            child: orders.isEmpty
                ? Center(child: Text('Tidak ada pesanan menunggu'))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order['orderId2'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Nama: ${order['nama']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
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
                                        ...products.map((product) {
                                          bool isNonHalal =
                                              product['kategori'] ==
                                                  'Non-halal';

                                          return Padding(
                                            padding: EdgeInsets.only(
                                                left: 8, top: 4),
                                            child: Text(
                                              '• ${product['name']} (${product['jumlah']}x)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isNonHalal
                                                    ? Colors.red
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.note_sharp,
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
                                          'Catatan:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, top: 4),
                                          child: Text(
                                            '• ${order['catatanTambahan']}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
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
                                      color: order['metodePembayaran'] == 'COD'
                                          ? Colors.green[50]
                                          : Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order['metodePembayaran'],
                                      style: TextStyle(
                                        color:
                                            order['metodePembayaran'] == 'COD'
                                                ? Colors.green[700]
                                                : Colors.blue[700],
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
                              if (order['metodePembayaran'] == 'QRIS' &&
                                  order['paymentProofUrl'] != null &&
                                  order['paymentProofUrl'].isNotEmpty)
                                Column(
                                  children: [
                                    SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: () => _showPaymentProof(
                                            context, order['paymentProofUrl']),
                                        child: Text(
                                          'Buka bukti pembayaran',
                                          style: TextStyle(
                                            color: Color(0xFF0072BC),
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _rejectOrder(order['orderId'], index),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: Color(0xFF8DC63F)),
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
                                          color: Color(0xFF8DC63F),
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
                                        backgroundColor: Color(0xFF8DC63F),
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
      );
        }
      )
    );
  }
}
