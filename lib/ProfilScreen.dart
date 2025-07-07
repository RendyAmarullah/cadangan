import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:pemesanan/AlamatScreen.dart';
import 'package:pemesanan/FavoritScreen.dart';
import 'package:pemesanan/AkunScreen.dart';
import 'package:pemesanan/SplahScreen.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      print('Gagal mengupload gambar: $e');
    }
  }

  Future<void> _saveProfileImage(String fileId) async {
    final user = await _account.get();
    if (user != null) {
      try {
        await _databases.getDocument(
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
      } catch (e) {
        if (e.toString().contains('document_not_found')) {
          await _databases.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: user.$id,
            data: {'profile_image': fileId},
          );
        }
      }
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _session = await _account.getSession(sessionId: 'current');
      _currentUser = await _account.get();

      setState(() {
        _userEmail = _currentUser?.email;
        if (_currentUser?.name != null && _currentUser!.name.isNotEmpty) {
          _userName = _currentUser!.name;
        }
      });

      final userId = _currentUser?.$id;
      if (userId != null) {
        await _loadProfileImage(userId);
        await _loadUserName(userId);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileImage(String userId) async {
    try {
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
      }
    } catch (e) {
      if (e.toString().contains('document_not_found')) {
        await _databases.createDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: userId,
          data: {'profile_image': null},
        );
      }
    }
  }

  Future<void> _loadUserName(String userId) async {
    try {
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
      }
    } catch (e) {
      if (e.toString().contains('document_not_found')) {
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
      }
    }
  }

  Future<void> _openWhatsApp() async {
    const phoneNumber = '6282377832998';
    const message = 'Halo, saya butuh bantuan customer service';
    final encodedMessage = Uri.encodeComponent(message);
    final url =
        'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      _showErrorDialog('Tidak dapat membuka WhatsApp. Error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshData() async {
    await _loadProfileData();
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
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem('Alamat', isLast: false, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AlamatScreen()),
                            );
                          }),
                          _buildMenuItem('Akun Saya', isLast: false, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AkunScreen()),
                            );
                          }),
                          _buildMenuItem('Favorit', isLast: true, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FavoriteScreen()),
                            );
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Butuh Bantuan?',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: FaIcon(FontAwesomeIcons.whatsapp,
                          color: Color(0xFF8DC63F)),
                      title: Text(
                        'For Customer Service (chat only)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '0823 - 7783 - 2998',
                        style: TextStyle(fontSize: 13),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: Colors.black, size: 12),
                      onTap: _openWhatsApp,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to logout, try again.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8DC63F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      ),
                      child: Text(
                        "Keluar",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMenuItem(String title,
      {required bool isLast, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          title: Text(title, style: TextStyle(fontSize: 16)),
          trailing: Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
          minVerticalPadding: 0,
        ),
        if (!isLast) Divider(height: 1, thickness: 0.8),
      ],
    );
  }
}
