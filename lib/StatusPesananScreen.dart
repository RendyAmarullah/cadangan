import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'dart:convert';

final client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1')
  ..setProject('681aa0b70002469fc157')
  ..setSelfSigned(status: true);

final databases = Databases(client);
final account = Account(client);

class StatusPesanaScreen extends StatefulWidget {
  final String orderId;

  StatusPesanaScreen({required this.orderId});

  @override
  _StatusPesanaScreenState createState() => _StatusPesanaScreenState();
}

class _StatusPesanaScreenState extends State<StatusPesanaScreen> {
  late Client _client;
  late Databases _databases;
  late Account _account;

  String status = 'Loading...'; // Order status
  String orderDetails = '';

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String ordersCollectionId =
      '684b33e80033b767b024'; // Change to your order collection ID

  @override
  void initState() {
    super.initState();
    _initAppwrite();
    _fetchOrderStatus();
  }

  void _initAppwrite() {
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157')
        .setSelfSigned(status: true);
    _databases = Databases(_client);
    _account = Account(_client);
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final models.Document result = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: ordersCollectionId,
        documentId: widget.orderId,
      );

      setState(() {
        status = result.data['status'] ?? 'Unknown';
        orderDetails =
            result.data['produk']; // Assuming 'produk' is the order's details
      });
    } catch (e) {
      setState(() {
        status = 'Failed to fetch status';
      });
      print('Error fetching order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Order Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status: $status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Order Details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(orderDetails),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close this screen and return
              },
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
