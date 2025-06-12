import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/widgets.dart';
import 'dart:convert';

final client = Client()
  ..setEndpoint('https://fra.cloud.appwrite.io/v1') 
  ..setProject('681aa0b70002469fc157')
  ..setSelfSigned(status: true);

final databases = Databases(client);
final account = Account(client);

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CheckoutScreen({required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Client _client;
  late Databases _databases;
  late Account _account;

  String userId = '';
  String address = '';
  String _metodePembayaran = 'COD';
  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String cartsCollectionId = '68407db7002d8716c9d0';
  final String addressCollectionId = '68447d3d0007b5f75cc5'; 

  @override
  void initState() {
    super.initState();
    _initAppwrite();
  }

 
  void _initAppwrite() async {
    _client = Client();
    _client.setEndpoint('https://fra.cloud.appwrite.io/v1').setProject(projectId).setSelfSigned(status: true);
    
    _databases = Databases(_client);
    _account = Account(_client);

    await _getCurrentUser();
    await _fetchUserAddress();
  }
  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;

    setState(() {
      widget.cartItems[index]['quantity'] = newQuantity;
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

  Future<void> clearCartItems(String userId) async {
  try {
    final result = await _databases.listDocuments(
      databaseId: databaseId,
      collectionId: cartsCollectionId,
      queries: [
        Query.equal('userId', userId),
      ],
    );

    for (var doc in result.documents) {
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: cartsCollectionId,
        documentId: doc.$id,
      );
    }

    print('Cart cleared successfully.');
  } catch (e) {
    print('Error clearing cart: $e');
  }
}


  Future<void> _fetchUserAddress() async {
    try {
      final models.DocumentList result = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: addressCollectionId,
        queries: [
          Query.equal('user_id', userId), 
        ],
      );

      if (result.documents.isNotEmpty) {
        setState(() {
          address = result.documents.first.data['address'] ?? 'Alamat tidak tersedia';
        });
      } else {
        setState(() {
          address = 'Alamat tidak ditemukan';
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = widget.cartItems.fold<int>(0, (sum, item) {
      int price = item['price'] is int ? item['price'] : 0;
      int quantity = item['quantity'] is int ? item['quantity'] : 1;
      return sum + price * quantity;
    });

    int totalPrice2 = widget.cartItems.fold<int>(0, (sum, item) {
      
      return totalPrice + 10000;
    });

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
            'Checkout',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Alamat Pengiriman Section
              Align(
                alignment: Alignment.topLeft,
                child: Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(address),
              ),
              SizedBox(height: 16),
        
             
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    int quantity = widget.cartItems[index]['quantity'] ?? 1;
        
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            
                            width: 100,
                            height: 100,
                            
                           child: ClipOval(
                            child: Image.network(
                              widget.cartItems[index]['productImageUrl'] ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.cartItems[index]['name'] ?? 'Product'),
                                SizedBox(height: 10,),
                                Text('Rp ${widget.cartItems[index]['price'] ?? 0}',style: TextStyle(color: Colors.green),),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Container( padding: EdgeInsets.all(1),  
                                        decoration: BoxDecoration(
                                          color: Colors.green,  
                                           borderRadius: BorderRadius.zero,  
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          color: Colors.white,  // Icon color (white in this case)
                                        ),
                                        
                                        ),
                                      onPressed: () {
                                        if (quantity > 1) {
                                          _updateQuantity(index, quantity - 1);
                                        }
                                      },
                                    ),
                                    Text(quantity.toString()),
                                    IconButton(
                                      icon: Container( padding: EdgeInsets.all(1),  
                                        decoration: BoxDecoration(
                                          color: Colors.blue,  
                                           borderRadius: BorderRadius.zero,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,  // Icon color (white in this case)
                                        ),
                                        
                                        ),
                                      onPressed: () {
                                        _updateQuantity(index, quantity + 1);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        
              // Total Price and Checkout Button
              SizedBox(height: 20),
             Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(  // Use Column to arrange items vertically
        crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start (left)
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catatan Tambahan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // Add your text or input field here
              Text('Tinggalkan catatan'),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
           SizedBox(height: 10),
          // First line for Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Rp $totalPrice', style: TextStyle(color: Colors.green), ),
            ],
          ),
           // Add space between the Total and Catatan Tambahan
          // Second line for Catatan Tambahan
          
        ],
            ),
          ),
        ),
        SizedBox(height: 10,),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(  // Use Column to arrange items vertically
        crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start (left)
        children: [
         Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Pilih Pembayaran:',
                style: TextStyle(fontWeight: FontWeight.bold),),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      _metodePembayaran = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'COD',
                      child: Text('COD'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'QRIS',
                      child: Text('QRIS'),
                    ),
                  ],
                  child: Text(
                    '$_metodePembayaran >',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

          SizedBox(height: 10),
          Divider(),
           SizedBox(height: 10),
          // First line for Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pesanan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Rp $totalPrice', style: TextStyle(color: Colors.green), ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Biaya Pengiriman:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Rp 10000', style: TextStyle(color: Colors.green), ),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Rp $totalPrice2', style: TextStyle(color: Colors.green), ),
            ],
          ),
           // Add space between the Total and Catatan Tambahan
          // Second line for Catatan Tambahan
          
        ],
            ),
          ),
        ),
        
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
       try {
   
      final user = await account.get();
      final produkList = widget.cartItems.map((item) => {
        'nama': item['name'],
        'jumlah': item['quantity'],
        'harga': item['price'],
      }).toList();
      final produkJsonString = jsonEncode(produkList);
          
        final data = {
        'userId': user.$id,
        'alamat': address,
        'produk': produkJsonString, // simpan sebagai string
        'metodePembayaran': _metodePembayaran,
        'total': totalPrice2,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };


  
        final response = await databases.createDocument(
          databaseId: '681aa33a0023a8c7eb1f', // Ganti
          collectionId: '684b33e80033b767b024', // Ganti
          documentId: ID.unique(),
          data: data,
        );

         await clearCartItems(userId);

        print('Pesanan berhasil dibuat: ${response.$id}');
   
        Navigator.pop(context);
          } catch (e) {
            print('Gagal membuat pesanan: $e');
          
          }
        },

                child: Text('Buat Pesanan'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
