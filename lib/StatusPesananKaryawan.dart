import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:pemesanan/RoomChatt.dart';
import 'dart:convert';

class StatusPesananKaryawanScreen extends StatefulWidget {
  final String userId;
  StatusPesananKaryawanScreen({required this.userId});

  @override
  _StatusPesananKaryawanScreenState createState() =>
      _StatusPesananKaryawanScreenState();
}

class _StatusPesananKaryawanScreenState
    extends State<StatusPesananKaryawanScreen> {
  late Client _client;
  late Databases _databases;
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _timer;
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
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);
    _databases = Databases(_client);
    _startAutoUpdateTimer();
  }

  void _startAutoUpdateTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchOrders();
    });
  }
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ordersResult = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('status',
              ['sedang diproses', 'sedang diantar', 'pesanan telah diterima']),
          Query.orderDesc('\$createdAt'),
        ],
      );
      List<Map<String, dynamic>> orders = ordersResult.documents.map((doc) {
        List<dynamic> products = [];
        try {
          if (doc.data['produk'] is String) {
            products = jsonDecode(doc.data['produk']);
          } else if (doc.data['produk'] is List) {
            products = doc.data['produk'];
          }
        } catch (e) {
          products = [];
        }

        return {
          'orderId': doc.$id,
          'nama': doc.data['nama'],
          'originalOrderId': doc.data['orderId'],
          'produk': products,
          'total': doc.data['total'] ?? 0,
          'metodePembayaran': doc.data['metodePembayaran'] ?? 'COD',
          'alamat': doc.data['alamat'] ?? 'No Address',
          'tanggal': doc.data['tanggal'] ?? '',
          'status': doc.data['status'] ?? 'Menunggu',
        };
      }).toList();
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat pesanan. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        documentId: orderId,
        data: {'status': newStatus},
      );
      setState(() {
        _allOrders = _allOrders.map((order) {
          if (order['orderId'] == orderId) {
            order['status'] = newStatus;
          }
          return order;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesanan sedang $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pesanan')),
      );
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatOrderId(String orderId) {
    return '${orderId}';
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    List<dynamic> products = order['produk'];
    String status = order['status'] ?? 'unknown';
    bool showChat = status == 'sedang diproses' || status == 'sedang diantar';

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
                  _formatOrderId(order['originalOrderId']),
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
                    color: status == 'sedang diantar'
                        ? Colors.green[100]
                        : status == 'sedang diproses'
                            ? Colors.orange[100]
                            : Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'sedang diantar'
                          ? Colors.green[800]
                          : status == 'sedang diproses'
                              ? Colors.orange[800]
                              : Colors.blue[800],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      ...products.map((product) {
                        bool isNonHalal = product['kategori'] == 'Non-halal';

                        return Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            '• ${product['name']} (${product['jumlah']}x)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isNonHalal ? Colors.red : Colors.grey[600],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                        order['metodePembayaran'].toUpperCase(),
                        style: TextStyle(
                          color: order['metodePembayaran'] == 'COD'
                              ? Colors.green[700]
                              : Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatDate(order['tanggal']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
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
            if (status == 'sedang diproses')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(
                            order['orderId'], 'sedang diantar'),
                        child: Text('Sedang Diantar'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFF8DC63F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChatRoom(order),
                        icon: Icon(Icons.chat, size: 18),
                        label: Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF8DC63F),
                          side: BorderSide(color: Color(0xFF8DC63F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (status == 'sedang diantar' ||
                status == 'selesai' ||
                status == 'Pesanan Telah Diterima')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChatRoom(order),
                        icon: Icon(Icons.chat, size: 18),
                        label: Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF8DC63F),
                          side: BorderSide(color: Color(0xFF8DC63F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openChatRoom(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          orderId: order['orderId'],
          userId: widget.userId,
          userRole: 'employee',
          orderInfo: 'Order #${order['originalOrderId']}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF0072BC),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Text(
          'Status Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: 
          
               RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _allOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_allOrders[index]);
                    },
                  ),
                ),
    );
  }
}
