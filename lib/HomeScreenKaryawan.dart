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
  String userId = '';  // Variable to store userId

  @override
  void initState() {
    super.initState();
    client.setEndpoint('https://cloud.appwrite.io/v1').setProject('681aa0b70002469fc157');
    account = Account(client);
    databases = Databases(client);
    _loadProfileData();
    _loadOrders();
  }

  // Function to load orders with 'pending' status
  Future<void> _loadOrders() async {
    try {
      final response = await databases!.listDocuments(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('status', 'menunggu'), // Only fetch orders with 'pending' status
        ],
      );

      setState(() {
        _orders = response.documents.map((doc) {
          List<dynamic> products = [];
          if (doc.data['produk'] is String) {
            products = jsonDecode(doc.data['produk']);
          } else if (doc.data['produk'] is List) {
            products = doc.data['produk'];
          }

          return {
            'userId': doc.data['userId'],
            'alamat': doc.data['alamat'],
            'produk': products,
            'metodePembayaran': doc.data['metodePembayaran'],
            'total': doc.data['total'],
            'orderId': doc.$id,
          };
        }).toList();
      });
    } catch (e) {
      print('Gagal mengambil data pesanan: $e');
    }
  }

  // Function to load profile data and get userId
  Future<void> _loadProfileData() async {
    try {
      final user = await account!.get();
      setState(() {
        _email = user.email;
      });
      String userId = user.$id;  // Get userId from account
      final profileDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: profil,
        documentId: userId,
      );
      setState(() {
        _userName = profileDoc.data['name'] ?? 'No name';
        this.userId = userId;  // Set userId for future reference
      });
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  // Accept order and save products to 'accepted_orders' as JSON string
  Future<void> _acceptOrder(String orderId, int index) async {
    try {
      final orderDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
      );

      List<dynamic> products = [];
      if (orderDoc.data['produk'] is String) {
        products = jsonDecode(orderDoc.data['produk']);
      } else if (orderDoc.data['produk'] is List) {
        products = orderDoc.data['produk'];
      }
      
      // Encode products to JSON string
      String productsJson = jsonEncode(products);

      // Save products to the 'accepted_orders' collection with JSON-encoded products
      await databases!.createDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: '6854b40600020e4a49aa',
        documentId: ID.unique(),
        data: {
          'userId': userId,  // Use the correct userId
          'orderId': orderId,
          'alamat' : orderDoc.data['alamat'],
          'produk': productsJson,  // Save as JSON string
          'metodePembayaran': orderDoc.data['metodePembayaran'] ?? 'Unknown',
          'total': orderDoc.data['total'],
          'status': 'accepted',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Update order status to 'accepted'
      await databases!.updateDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
        data: {'status': 'accepted'},
      );

      // Remove the accepted order from the list and refresh UI
      setState(() {
        _orders.removeAt(index);
      });

      print('Pesanan #$orderId diterima dan produk ditambahkan ke koleksi');
    } catch (e) {
      print('Gagal menerima pesanan dan menambahkan produk: $e');
    }
  }

  // Reject order and save products to 'rejected_orders' as JSON string
  Future<void> _rejectOrder(String orderId, int index) async {
    try {
      final orderDoc = await databases!.getDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
      );

      List<dynamic> products = [];
      if (orderDoc.data['produk'] is String) {
        products = jsonDecode(orderDoc.data['produk']);
      } else if (orderDoc.data['produk'] is List) {
        products = orderDoc.data['produk'];
      }

      // Encode products to JSON string
      String productsJson = jsonEncode(products);

      // Save rejected products to the 'rejected_orders' collection as JSON string
      await databases!.createDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: '6854ba6e003bad3da579',
        documentId: ID.unique(),
        data: {
          'userId': userId,  // Use the correct userId
          'orderId': orderId,
          'alamat' : orderDoc.data['alamat'],
          'produk': productsJson,  // Save as JSON string
          'metodePembayaran': orderDoc.data['metodePembayaran'] ?? 'Unknown',
          'total': orderDoc.data['total'],
          'status': 'accepted',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Update order status to 'rejected'
      await databases!.updateDocument(
        databaseId: '681aa33a0023a8c7eb1f',
        collectionId: ordersCollectionId,
        documentId: orderId,
        data: {'status': 'rejected'},
      );

      // Remove the rejected order from the list and refresh UI
      setState(() {
        _orders.removeAt(index);
      });

      print('Pesanan #$orderId ditolak dan produk ditambahkan ke koleksi');
    } catch (e) {
      print('Gagal menolak pesanan dan menambahkan produk: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Spacer(),
            ],
          ),
        ),
      body: _orders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                var order = _orders[index];
                List<dynamic> products = order['produk'];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alamat: ${order['alamat']}'),
                        Text('Metode Pembayaran: ${order['metodePembayaran']}'),
                        Text('Total: ${order['total']}'),
                        SizedBox(height: 10),
                        Text('Produk:'),
                        for (var product in products)
                          Text('Nama: ${product['nama']}, Jumlah: ${product['jumlah']}'),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _acceptOrder(order['orderId'], index),
                              child: Text('Terima', style: TextStyle(color: Colors.green)),
                            ),
                            TextButton(
                              onPressed: () => _rejectOrder(order['orderId'], index),
                              child: Text('Tolak', style: TextStyle(color: Colors.red)),
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
}
