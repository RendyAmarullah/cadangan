import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/AlamatScreen.dart';
import 'package:pemesanan/RiwayatTransaksiScreen.dart';
import 'package:pemesanan/SignUpScreen.dart';
import 'package:pemesanan/AkunScreen.dart';
import 'package:pemesanan/SplahScreen.dart';
import 'package:geolocator/geolocator.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

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
  String? _userEmail;
  models.Session? _session;
  models.User? _currentUser;
  String? _userLocation;
  bool _isLoading = true;

  final String databaseId = '681aa33a0023a8c7eb1f';
  final String collectionId = '681aa352000e7e9b76b5';
  final String usersCollectionId = '684083800031dfaaecad';
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
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadImage();
    }
  }

  Future<bool?> _notifLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing by tapping outside the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Dismiss dialog with false (no logout)
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                    true); // Dismiss dialog with true (proceed with logout)
              },
              child: Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      final bucketId = '681aa16f003054da8969';

      final inputFile = InputFile.fromPath(path: _imageFile!.path);

      final result = await _storage.createFile(
        bucketId: bucketId,
        file: inputFile,
        fileId: fileId,
      );

      final fileViewUrl =
          'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${result.$id}/view?project=$projectId';

      setState(() {
        _profileImageUrl = fileViewUrl;
      });

      await _saveProfileImage(result.$id);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    final user = await _account.get();
    if (user != null) {
      try {
        final document = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.$id,
        );

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
    setState(() {
      _isLoading = true;
    });

    try {
      print("🔄 Starting to load profile data...");

      // Get the current session
      try {
        _session = await _account.getSession(sessionId: 'current');
        print("✅ Session loaded successfully");
      } catch (e) {
        print("❌ Error loading session: $e");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current user
      try {
        _currentUser = await _account.get();
        print("✅ Current user loaded: ${_currentUser?.$id}");
        print("📧 User email: ${_currentUser?.email}");
        print("👤 User name from auth: ${_currentUser?.name}");

        // Set email and name from auth as fallback
        setState(() {
          _userEmail = _currentUser?.email;
          if (_currentUser?.name != null && _currentUser!.name.isNotEmpty) {
            _userName = _currentUser!.name;
          }
        });
      } catch (e) {
        print("❌ Error loading current user: $e");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = _currentUser?.$id;
      if (userId != null) {
        // Try to load profile image
        try {
          print(
              "🖼️ Trying to load profile image from collection: $collectionId");
          final profileDoc = await _databases.getDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: userId,
          );

          final profileImageId = profileDoc.data['profile_image'];
          if (profileImageId != null) {
            final fileViewUrl =
                'https://fra.cloud.appwrite.io/v1/storage/buckets/$bucketId/files/$profileImageId/view?project=$projectId';
            setState(() {
              _profileImageUrl = fileViewUrl;
            });
            print("✅ Profile image loaded successfully");
          } else {
            print("ℹ️ No profile image found in document");
          }
        } catch (e) {
          print("❌ Error loading profile image: $e");
          // Create empty profile document if it doesn't exist
          if (e.toString().contains('document_not_found')) {
            try {
              await _databases.createDocument(
                databaseId: databaseId,
                collectionId: collectionId,
                documentId: userId,
                data: {'profile_image': null},
              );
              print("✅ Created empty profile document");
            } catch (createError) {
              print("❌ Error creating profile document: $createError");
            }
          }
        }

        // Try to load user name from users collection
        try {
          print(
              "👤 Trying to load user name from collection: $usersCollectionId");
          final userNameDoc = await _databases.getDocument(
            databaseId: databaseId,
            collectionId: usersCollectionId,
            documentId: userId,
          );

          final name = userNameDoc.data['name'];
          if (name != null && name.toString().isNotEmpty) {
            setState(() {
              _userName = name.toString();
            });
            print("✅ User name loaded from database: $name");
          } else {
            print("ℹ️ Name field is empty in users collection");
          }
        } catch (e) {
          print("❌ Error loading user name from database: $e");

          // If document doesn't exist, try to create it with data from auth
          if (e.toString().contains('document_not_found')) {
            try {
              final userData = {
                'name': _currentUser?.name ??
                    _currentUser?.email?.split('@')[0] ??
                    'User',
                'email': _currentUser?.email ?? '',
                'userId': userId,
              };

              await _databases.createDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId,
                data: userData,
              );

              setState(() {
                _userName = userData['name'];
              });

              print("✅ Created user document with name: ${userData['name']}");
            } catch (createError) {
              print("❌ Error creating user document: $createError");
            }
          }
        }
      }

      setState(() {
        _isLoading = false;
      });

      print("🎉 Profile data loading completed");
      print("Final state - Name: $_userName, Email: $_userEmail");
    } catch (e) {
      print('❌ General error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission is denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
          'Location permission is permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');

    setState(() {
      _userLocation =
          'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    });
  }

  Future<void> _refreshData() async {
    await _loadProfileData();
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
            'Profil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat data profil...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          child: _profileImageUrl != null
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundImage:
                                      NetworkImage(_profileImageUrl!))
                              : const CircleAvatar(
                                  radius: 60, child: Icon(Icons.person)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        _userName ??
                            _currentUser?.name ??
                            _userEmail?.split('@')[0] ??
                            'Guest',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 20),
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
                              MaterialPageRoute(
                                  builder: (context) => AlamatScreen()),
                            );
                          }),
                          Divider(
                              color: Colors.black, indent: 15, endIndent: 15),
                          _buildMenuItem('Akun Saya', onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AkunScreen()),
                            );
                          }),
                          Divider(
                              color: Colors.black, indent: 15, endIndent: 15),
                          _buildMenuItem('Pesanan', onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RiwayatTransaksiScreen(
                                      userId: widget.userId)),
                            );
                          }),
                          Divider(
                              color: Colors.black, indent: 15, endIndent: 15),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Butuh Bantuan?',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: FaIcon(FontAwesomeIcons.whatsapp,
                          color: Color(0xFF8DC63F)),
                      title: Text('For Customer Service (chat only)'),
                      subtitle: Text('0831 - 8274 - 2991'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {},
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        bool? isConfirmed = await _notifLogout(context);

                        if (isConfirmed == true) {
                          try {
                            await _account.deleteSession(sessionId: 'current');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SplashScreen()),
                            );
                          } catch (e) {
                            print('Logout failed: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to logout, try again.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0072BC),
                        shape: StadiumBorder(),
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      ),
                      child:
                          Text("KELUAR", style: TextStyle(color: Colors.white)),
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
