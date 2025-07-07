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
  final String projectId = '681aa0b70002469fc157';

  @override
  void initState() {
    super.initState();
    _initializeAppwrite();
    _getCurrentLocation();
  }

  void _initializeAppwrite() {
    _client = Client()
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId);
    _databases = Databases(_client);
    _account = Account(_client);
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await _checkLocationService()) return;
      if (!await _checkLocationPermission()) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      _setAddress("Gagal mendapatkan lokasi.");
    }
  }

  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setAddress("Layanan lokasi tidak aktif.");
      return false;
    }
    return true;
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _setAddress("Izin lokasi tidak diberikan.");
        return false;
      }
    }
    return true;
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String fullAddress =
            "${place.name}, ${place.locality}, ${place.country}";
        _setAddress(fullAddress);
        await _saveAddressToDatabase(fullAddress);
      } else {
        _setAddress("Tidak dapat menemukan alamat.");
      }
    } catch (e) {
      _setAddress("Tidak dapat mengonversi lokasi ke alamat.");
    }
  }

  void _setAddress(String address) {
    setState(() {
      _address = address;
    });
  }

  Future<void> _saveAddressToDatabase(String address) async {
    try {
      final user = await _account.get();
      final userId = user.$id;

      final existingDocuments = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.equal('user_id', userId)],
      );

      final addressData = {
        'user_id': userId,
        'address': address,
      };

      if (existingDocuments.documents.isNotEmpty) {
        await _updateExistingAddress(
            existingDocuments.documents.first.$id, addressData);
      } else {
        await _createNewAddress(addressData);
      }
    } catch (e) {
      print("Gagal menyimpan alamat: $e");
    }
  }

  Future<void> _updateExistingAddress(
      String documentId, Map<String, dynamic> data) async {
    try {
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );
    } catch (e) {
      print("Error memperbarui alamat: $e");
    }
  }

  Future<void> _createNewAddress(Map<String, dynamic> data) async {
    try {
      await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: data,
      );
    } catch (e) {
      print("Error membuat alamat baru: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
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
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLocationIcon(),
              SizedBox(height: 20),
              _buildAddressTitle(),
              SizedBox(height: 10),
              _buildAddressText(),
              SizedBox(height: 30),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIcon() {
    return Icon(
      Icons.location_on,
      size: 60,
      color: Color(0xFF0072BC),
    );
  }

  Widget _buildAddressTitle() {
    return Text(
      "Alamat Anda:",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAddressText() {
    return Text(
      _address,
      style: TextStyle(fontSize: 18),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _getCurrentLocation,
      style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0072BC),
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(
        "Perbarui Lokasi",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
