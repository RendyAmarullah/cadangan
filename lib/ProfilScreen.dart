import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/AlamatScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/AkunScreen.dart';  // Import AkunScreen
import 'package:pemesanan/SplahScreen.dart';
import 'package:geolocator/geolocator.dart';




class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Client _client;
  late Storage _storage;
  late Account _account;
  late Databases _databases;
  File? _imageFile;
  String? _profileImageUrl;
  String? _userName;
  models.Session? _session;
  models.User? _currentUser;
  String? _userLocation;

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '681aa352000e7e9b76b5';
  final String bucketId = '681aa16f003054da8969';
  final String projectId = '681aa0b70002469fc157';

  @override
  void initState() {
    super.initState();
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _storage = Storage(_client);
    _account = Account(_client);
    _databases = Databases(_client);

    _loadProfileData();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      final bucketId = '681aa16f003054da8969';

      final inputFile = InputFile.fromPath(path: _imageFile!.path);

      // Upload the image to Appwrite
      final result = await _storage.createFile(
        bucketId: bucketId,
        file: inputFile,
        fileId: fileId,
      );

      // Construct the URL to view the uploaded image
      final fileViewUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${result.$id}/view?project=$projectId';

      // Update profile image URL in the UI
      setState(() {
        _profileImageUrl = fileViewUrl;  // Update the profile image URL directly
      });

      // Save the image URL to the database
      await _saveProfileImage(result.$id);

    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    final user = await _account.get();  // Get current user info
    if (user != null) {
      try {
        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.$id,
        );

        // Update the document with the new profile image ID
        await _databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.$id,
          data: {'profile_image': fileId},
        );
        print("Profile image updated in the database successfully.");
      } catch (e) {
        if (e.toString().contains('document_not_found')) {
          await _databases.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: user.$id,
            data: {'profile_image': fileId},
          );
          print("Profile image saved to the database successfully.");
        } else {
          print('Error: $e');
        }
      }
    }
  }

  Future<void> _loadProfileData() async {
    try {
      // Get the current session
      _session = await _account.getSession(sessionId: 'current');
      _currentUser = await _account.get();

      final userId = _currentUser?.$id;
      if (userId != null) {
        try {
          // Fetch the profile data (image) from the current collection
          final profileDoc = await _databases.getDocument(
            databaseId: databaseId,
            collectionId: collectionId, // This collection contains the profile image
            documentId: userId,
          );

          final profileImageId = profileDoc.data['profile_image'];
          if (profileImageId != null) {
            final fileViewUrl =
                'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/$profileImageId/view?project=$projectId';
            setState(() {
              _profileImageUrl = fileViewUrl;  // Update profile image
            });
          }

          // Fetch the name from a different collection (usersCollectionId)
          final userNameDoc = await _databases.getDocument(
            databaseId: databaseId,
            collectionId: '684083800031dfaaecad', // Different collection for user name
            documentId: userId,
          );

          final name = userNameDoc.data['name'];
          if (name != null) {
            setState(() {
              _userName = name;  // Update name directly
            });
          }
        } catch (e) {
          print('Error loading profile data: $e');
        }
      }
    } catch (e) {
      print('Error loading session or current user: $e');
    }
  }

  Future<void> _getUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Cek apakah service lokasi diaktifkan
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Jika layanan lokasi tidak diaktifkan
    print('Location services are disabled.');
    return;
  }

  // Memeriksa apakah pengguna memberikan izin lokasi
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission is denied');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Jika izin lokasi ditolak secara permanen
    print('Location permission is permanently denied, we cannot request permissions.');
    return;
  }

  // Mendapatkan posisi pengguna
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  // Cetak lokasi pengguna (latitude dan longitude)
  print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');

  // Anda dapat memperbarui UI dengan lokasi yang didapat
  setState(() {
    // Misalnya, tampilkan latitude dan longitude dalam teks
    _userLocation = 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
  });
}



  Future<void> _refreshData() async {
    await _loadProfileData();
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
            'Profil',
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
        onRefresh: _refreshData, // Function to call when the user pulls to refresh
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    child: _profileImageUrl != null
                        ? CircleAvatar(radius: 60, backgroundImage: NetworkImage(_profileImageUrl!))
                        : const CircleAvatar(radius: 60, child: Icon(Icons.person)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  _userName ?? 'Guest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
            
                    _buildMenuItem('Alamat Tersimpan', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AlamatScreen()),
                      );
                    }),
                  //   ElevatedButton(
                  //   onPressed: _getUserLocation,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blue,
                  //     shape: StadiumBorder(),
                  //     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  //   ),
                  //   child: Text("Ambil Lokasi Saya", style: TextStyle(color: Colors.white)),
                  // ),

                    Divider(color: Colors.black, indent: 15, endIndent: 15),
                    _buildMenuItem('Akun Saya', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AkunScreen()),
                      );
                    }),
                    Divider(color: Colors.black, indent: 15, endIndent: 15),
                    _buildMenuItem('pesanan', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AkunScreen()),
                      );
                    }),
                    
                    Divider(color: Colors.black, indent: 15, endIndent: 15),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Butuh Bantuan?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                title: Text('For Customer Service (chat only)'),
                subtitle: Text('0831 - 8274 - 2991'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _account.deleteSession(sessionId: 'current');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                    );
                  } catch (e) {
                    print('Logout failed: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to logout, try again.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text("KELUAR", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
