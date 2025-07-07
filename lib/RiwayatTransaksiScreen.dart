import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/RoomChatt.dart';
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
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentFilter = 'Pesanan Kamu';
  Map<String, bool> _expandedOrders = {};

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
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        queries: [
          Query.equal('userId', widget.userId),
          Query.orderDesc('\$createdAt'),
        ],
      );
      setState(() {
        _orders = result.documents.map((doc) {
          return {
            'orderId': doc.$id,
            'originalOrderId': doc.data['orderId'],
            'produk': jsonDecode(doc.data['produk']),
            'total': doc.data['total'],
            'metodePembayaran': doc.data['metodePembayaran'],
            'alamat': doc.data['alamat'],
            'tanggal': doc.data['tanggal'],
            'status': doc.data['status'],
          };
        }).toList();

        if (_currentFilter == 'Pesanan Kamu') {
          _showActiveOrders();
        } else {
          _showCompletedOrders();
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat riwayat pesanan. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(
      String orderId, String status, String message) async {
    try {
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        documentId: orderId,
        data: {'status': status},
      );
      setState(() {
        _orders = _orders.map((order) {
          if (order['orderId'] == orderId) {
            order['status'] = status;
          }
          return order;
        }).toList();

        if (_currentFilter == 'Pesanan Kamu') {
          _showActiveOrders();
        } else {
          _showCompletedOrders();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pesanan.')),
      );
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    await _updateOrderStatus(orderId, 'Dibatalkan', 'Pesanan telah dibatalkan');
  }

  Future<void> _completeOrder(String orderId) async {
    await _updateOrderStatus(orderId, 'Selesai', 'Pesanan selesai');
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

  void _showCompletedOrders() {
    setState(() {
      _currentFilter = 'Semua Pesanan';
      _filteredOrders = _orders
          .where((order) =>
              order['status'].toString().toLowerCase() == 'dibatalkan' ||
              order['status'].toString().toLowerCase() == 'selesai' ||
              order['status'].toString().toLowerCase() == 'ditolak')
          .toList();
    });
  }

  void _showActiveOrders() {
    setState(() {
      _currentFilter = 'Pesanan Kamu';
      _filteredOrders = _orders.where((order) {
        String status = order['status'].toString().toLowerCase();
        return status == 'menunggu' ||
            status == 'diproses' ||
            status == 'sedang diantar' ||
            status == 'sedang diproses' ||
            status == 'pesanan telah diterima';
      }).toList();
    });
  }

  void _toggleExpanded(String orderId) {
    setState(() {
      _expandedOrders[orderId] = !(_expandedOrders[orderId] ?? false);
    });
  }

  Widget _buildProductList(
      List<Map<String, dynamic>> produkList, String orderId) {
    bool isExpanded = _expandedOrders[orderId] ?? false;
    List<Map<String, dynamic>> displayedProducts;

    if (produkList.length <= 2) {
      displayedProducts = produkList;
    } else {
      displayedProducts = isExpanded ? produkList : produkList.take(2).toList();
    }

    return Column(
      children: [
        ...displayedProducts.map((product) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product['productImageUrl'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Produk',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${product['jumlah']} x ${_formatCurrency(product['harga'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(product['harga'] * product['jumlah']),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (produkList.length > 2)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => _toggleExpanded(orderId),
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Color(0xFF0072BC),
              ),
              label: Text(
                isExpanded
                    ? 'Tampilkan Lebih Sedikit'
                    : 'Lihat ${produkList.length - 2} Produk Lainnya',
                style: TextStyle(
                  color: Color(0xFF0072BC),
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    String statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'menunggu':
        return Colors.orange;
      case 'diproses':
      case 'sedang diproses':
        return Colors.blue;
      case 'sedang diantar':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
      case 'ditolak':
        return Colors.red;
      case 'pesanan telah diterima':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _openChatRoom(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          orderId: order['orderId'],
          userId: widget.userId,
          userRole: 'customer',
          orderInfo: 'Order #${order['originalOrderId']}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color(0xFF0072BC),
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showActiveOrders,
                        child: Text('Pesanan Kamu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentFilter == 'Pesanan Kamu'
                              ? Color(0xFF8DC63F)
                              : Colors.white,
                          foregroundColor: _currentFilter == 'Pesanan Kamu'
                              ? Colors.white
                              : Colors.black,
                          side: _currentFilter != 'Pesanan Kamu'
                              ? BorderSide(color: Colors.grey[300]!)
                              : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showCompletedOrders,
                        child: Text('Semua Pesanan'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _currentFilter == 'Semua Pesanan'
                                ? Color(0xFF8DC63F)
                                : Colors.white,
                            foregroundColor: _currentFilter == 'Semua Pesanan'
                                ? Colors.white
                                : Colors.black,
                            side: _currentFilter != 'Semua Pesanan'
                                ? BorderSide(color: Colors.grey[300]!)
                                : null,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat riwayat pesanan...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOrders,
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                _currentFilter == 'Pesanan Kamu'
                    ? 'Belum ada pesanan'
                    : 'Belum ada riwayat pesanan selesai',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                _currentFilter == 'Pesanan Kamu'
                    ? 'Status pesanan kamu akan muncul di sini'
                    : 'Riwayat pesanan kamu akan muncul di sini',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          var order = _filteredOrders[index];
          var produkList = List<Map<String, dynamic>>.from(order['produk']);
          int totalPrice = order['total'];
          String paymentMethod = order['metodePembayaran'];
          String address = order['alamat'];
          String createdAt = order['tanggal'];
          String status = order['status'];
          String orderId = order['orderId'];

          bool isCompleteOrderButtonEnabled =
              status.toLowerCase() == 'sedang diantar' ||
                  status.toLowerCase() == 'pesanan telah diterima';
          Color completeOrderButtonColor =
              isCompleteOrderButtonEnabled ? Color(0xFF8DC63F) : Colors.grey;

          return Card(
            margin: EdgeInsets.only(bottom: 12.0),
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${order['originalOrderId']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                address,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.payment,
                                size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              paymentMethod,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Produk (${produkList.length} item)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildProductList(produkList, orderId),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatCurrency(totalPrice),
                        style: TextStyle(
                          color: Color(0xFF0072BC),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status Pesanan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          border: Border.all(color: _getStatusColor(status)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (status.toLowerCase() == 'pesanan telah diterima' ||
                      status.toLowerCase() == 'sedang diproses' ||
                      status.toLowerCase() == 'sedang diantar' ||
                      status.toLowerCase() == 'diproses')
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
                                foregroundColor: Color(0xFF0072BC),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Color(0xFF0072BC)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isCompleteOrderButtonEnabled
                                  ? () => _completeOrder(orderId)
                                  : null,
                              child: Text('Selesaikan Pesanan'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: completeOrderButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (status.toLowerCase() == 'menunggu')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () => _cancelOrder(orderId),
                            child: Center(
                              child: Text(
                                'Batalkan Pesanan',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xFF8DC63F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
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
