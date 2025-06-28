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
      final user = await Account(_client).get();
      final userId = user.$id;

      final response = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: userId,
        data: {
          'user_id': userId,
          'address': address,
        },
      );
      print("Alamat berhasil disimpan: ${response.data}");
    } catch (e) {
      print("Gagal menyimpan alamat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Padding(
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
                child: Text("Perbarui Lokasi"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
