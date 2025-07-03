import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

class AlamatScreen extends StatefulWidget {
  @override
  _AlamatScreenState createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  String _address = "Menunggu lokasi...";
  late Client _client;
  late Databases _databases;
  late Account _account;

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '68447d3d0007b5f75cc5';

  @override
  void initState() {
    super.initState();
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject('681aa0b70002469fc157');
    _databases = Databases(_client);
    _account = Account(_client);

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _address = "Layanan lokasi tidak aktif.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _address = "Izin lokasi tidak diberikan.";
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _getAddressFromCoordinates(position.latitude, position.longitude);
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      String fullAddress = "${place.name}, ${place.locality}, ${place.country}";
      setState(() {
        _address = fullAddress;
      });

      await _saveAddressToDatabase(fullAddress);
    } catch (e) {
      setState(() {
        _address = "Tidak dapat mengonversi lokasi ke alamat.";
      });
    }
  }

  Future<void> _saveAddressToDatabase(String address) async {
    try {
      final user = await _account.get();
      final userId = user.$id;

      // Cek apakah dokumen sudah ada
      try {
        final existingDocuments = await _databases.listDocuments(
          databaseId: databaseId,
          collectionId: collectionId,
          queries: [
            Query.equal('user_id', userId),
          ],
        );

        if (existingDocuments.documents.isNotEmpty) {
          // Update dokumen yang sudah ada
          final documentId = existingDocuments.documents.first.$id;
          await _databases.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: documentId,
            data: {
              'user_id': userId,
              'address': address,
            },
          );
          print("Alamat berhasil diperbarui: $address");
        } else {
          // Buat dokumen baru
          await _databases.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: ID.unique(),
            data: {
              'user_id': userId,
              'address': address,
            },
          );
          print("Alamat berhasil disimpan: $address");
        }
      } catch (e) {
        print("Error saat menyimpan/update alamat: $e");
      }
    } catch (e) {
      print("Gagal mendapatkan user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih bersih
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
            'Alamat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Kembali dengan mengirim signal bahwa alamat telah diperbarui
              Navigator.pop(context, true);
            },
          ),
        ),
      ),
      body: Container(
        color: Colors.white, // Pastikan body juga putih
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 60,
                  color: Color(0xFF0072BC),
                ),
                SizedBox(height: 20),
                Text(
                  "Alamat Anda:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  _address,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0072BC),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    "Perbarui Lokasi",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
