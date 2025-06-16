import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'dart:convert';

class RiwayatTransaksiScreen extends StatefulWidget {
  final String userId;

  RiwayatTransaksiScreen({required this.userId});

  @override
  _RiwayatTransaksiScreenState createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  late Client _client;
  late Databases _databases;
  late Account _account;
  List<Map<String, dynamic>> _orders = [];

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String ordersCollectionId = '684b33e80033b767b024';

  @override
  void initState() {
    super.initState();
    _initAppwrite();
    _fetchOrders();
  }

  void _initAppwrite() {
    _client = Client();
    _client.setEndpoint('https://fra.cloud.appwrite.io/v1').setProject(projectId).setSelfSigned(status: true);
    
    _databases = Databases(_client);
    _account = Account(_client);
  }

  Future<void> _fetchOrders() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('userId', widget.userId),
        ],
      );

      if (result.documents.isNotEmpty) {
        setState(() {
          _orders = result.documents.map((doc) {
            return {
              'orderId': doc.$id,
              'produk': jsonDecode(doc.data['produk']),
              'total': doc.data['total'],
              'metodePembayaran': doc.data['metodePembayaran'],
              'alamat': doc.data['alamat'],
              'createdAt': doc.data['createdAt'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
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
            'Riwayat Pesanan',
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
      body: RefreshIndicator(
        onRefresh: _fetchOrders, // Trigger data refresh
        child: _orders.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  var order = _orders[index];
                  var produkList = List<Map<String, dynamic>>.from(order['produk']);
                  int totalPrice = order['total'];
                  String paymentMethod = order['metodePembayaran'];
                  String address = order['alamat'];
                  String createdAt = order['createdAt'];

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order['orderId']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Tanggal: $createdAt'),
                          SizedBox(height: 8),
                          Text('Alamat Pengiriman: $address'),
                          SizedBox(height: 8),
                          Text('Metode Pembayaran: $paymentMethod'),
                          SizedBox(height: 16),
                          Text('Produk:'),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: produkList.length,
                            itemBuilder: (context, index) {
                              var product = produkList[index];
                              return ListTile(
                                leading: Image.network(
                                  product['productImageUrl'] ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(product['name'] ?? 'Product'),
                                subtitle: Text('Jumlah: ${product['jumlah']} x Rp ${product['harga']}'),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          Divider(),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pembayaran:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Rp $totalPrice', style: TextStyle(color: Colors.green)),
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
