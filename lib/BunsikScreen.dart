import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pemesanan/KeranjangScreen.dart'; // Untuk mengambil ID pengguna yang login

class BunsikScreen extends StatefulWidget {
  @override
  _BunsikScreenState createState() => _BunsikScreenState();
}

class _BunsikScreenState extends State<BunsikScreen> {
  List<Map<String, dynamic>> products = [
    {"name": "Onion Rings 90g", "price": 20000},
    {"name": "Choco Free Time Bar 36g", "price": 30000},
    {"name": "Peanut Caramel Candy 140g", "price": 19000},
    {"name": "Grace 85g", "price": 24000},
    {"name": "Caramel Corn Maple 74g", "price": 16000},
    {"name": "Chocochip Cookie 104g", "price": 21000},
  ];

  List<Map<String, dynamic>> cartItems = [];  // Daftar produk yang ada di keranjang

  // Fungsi untuk mengambil ID pengguna dari Firebase Authentication
  String get userId {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null ? user.uid : ''; // Mengembalikan ID pengguna jika ada
  }

  // Fungsi untuk menyimpan data keranjang ke Firestore berdasarkan ID pengguna
  Future<void> _simpanKeKeranjang() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference cartCollection = FirebaseFirestore.instance.collection('carts');

    // Menyimpan data keranjang ke Firestore, ID pengguna sebagai dokumen
    await cartCollection.doc(userId).set({
      'cartItems': cartItems,  // Menyimpan data keranjang dalam dokumen
      'updatedAt': FieldValue.serverTimestamp(),  // Timestamp saat diperbarui
    });

    print('Data keranjang berhasil disimpan ke Firestore');
  }

  // Fungsi untuk mengambil data keranjang dari Firestore berdasarkan ID pengguna
  Future<void> _ambilDataKeranjang() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('carts').doc(userId).get();

    if (snapshot.exists) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(snapshot['cartItems']);
      });
    }
  }

  
  // Menambahkan produk ke dalam keranjang
void tambahKeranjang(Map<String, dynamic> product) {
  // Cek apakah produk sudah ada di keranjang berdasarkan nama produk
  int index = cartItems.indexWhere((item) => item['name'] == product['name']);

  if (index != -1) {
    // Jika produk sudah ada, tambahkan quantity-nya
    setState(() {
      cartItems[index]['quantity'] += 1;
    });
  } else {
    // Jika produk belum ada, tambahkan produk baru ke keranjang
    setState(() {
      product['quantity'] = 1;  // Set quantity awal ke 1
      cartItems.add(product);
    });
  }

  _simpanKeKeranjang();  // Menyimpan keranjang yang diperbarui ke Firestore
}


  

  @override
  void initState() {
    super.initState();
    _ambilDataKeranjang();  // Memuat data keranjang saat halaman dimuat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120), // Adjust the height of the app bar
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          title: Row(
            children: [
              Text(
                'Market',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // Set color to white
            onPressed: () {Navigator.pop(context);},
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.blue),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari Produk',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.green,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return Card(
              color: Color(0xFF81C784),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    height: 60,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      products[index]['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Rp ${products[index]['price']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        tambahKeranjang(products[index]); // Menambahkan produk ke keranjang
                        print('Added to cart: ${products[index]['name']}');
                      },
                      child: Text('Keranjang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman keranjang
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KeranjangScreen(cartItems: cartItems),
            ),
          );
        },
        child: Icon(Icons.shopping_cart),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
