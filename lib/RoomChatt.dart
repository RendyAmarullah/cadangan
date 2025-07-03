import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'dart:convert';

class ChatRoomScreen extends StatefulWidget {
  final String orderId;
  final String userId;
  final String userRole; // 'customer' atau 'employee'
  final String orderInfo; // Info pesanan untuk header

  ChatRoomScreen({
    required this.orderId,
    required this.userId,
    required this.userRole,
    required this.orderInfo,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late Client _client;
  late Databases _databases;
  late Realtime _realtime;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  final String projectId = '681aa0b70002469fc157';
  final String databaseId = '681aa33a0023a8c7eb1f';
  final String chatCollectionId =
      '68666f5c00159b853aab'; // ID collection untuk chat

  @override
  void initState() {
    super.initState();
    _initAppwrite();
    _loadMessages();
    _subscribeToMessages();
  }

  void _initAppwrite() {
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject(projectId)
        .setSelfSigned(status: true);

    _databases = Databases(_client);
    _realtime = Realtime(_client);

    // Debug: Print client configuration
    print('Appwrite Client initialized');
    print('Endpoint: https://fra.cloud.appwrite.io/v1');
    print('Project ID: $projectId');
    print('Database ID: $databaseId');
    print('Chat Collection ID: $chatCollectionId');
  }

  Future<void> _loadMessages() async {
    try {
      print('Loading messages for order: ${widget.orderId}');

      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: chatCollectionId,
        queries: [
          Query.equal('orderId', widget.orderId),
          Query.orderAsc('\$createdAt'),
        ],
      );

      print(
          'Messages loaded successfully: ${response.documents.length} messages');

      setState(() {
        _messages = response.documents.map((doc) {
          return {
            'id': doc.$id,
            'message': doc.data['message'] ?? '',
            'senderId': doc.data['senderId'] ?? '',
            'senderRole': doc.data['senderRole'] ?? '',
            'timestamp': doc.data['timestamp'] ?? '',
            'createdAt': doc.$createdAt,
          };
        }).toList();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      print('Error type: ${e.runtimeType}');

      if (e is AppwriteException) {
        print('Appwrite Error Code: ${e.code}');
        print('Appwrite Error Message: ${e.message}');
        print('Appwrite Error Type: ${e.type}');
      }

      setState(() {
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pesan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _subscribeToMessages() {
    try {
      print('Subscribing to messages...');

      _realtime
          .subscribe(
              ['databases.$databaseId.collections.$chatCollectionId.documents'])
          .stream
          .listen(
            (response) {
              print('Realtime event received: ${response.events}');

              if (response.events
                  .contains('databases.*.collections.*.documents.*.create')) {
                final newMessage = response.payload;
                print('New message payload: $newMessage');

                if (newMessage['orderId'] == widget.orderId) {
                  setState(() {
                    _messages.add({
                      'id': newMessage['\$id'],
                      'message': newMessage['message'] ?? '',
                      'senderId': newMessage['senderId'] ?? '',
                      'senderRole': newMessage['senderRole'] ?? '',
                      'timestamp': newMessage['timestamp'] ?? '',
                      'createdAt': newMessage['\$createdAt'],
                    });
                  });
                  _scrollToBottom();
                }
              }
            },
            onError: (error) {
              print('Realtime subscription error: $error');
            },
          );
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    // Validasi data sebelum mengirim
    if (widget.orderId.isEmpty || widget.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data user atau order tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final message = _messageController.text.trim();
      print('Attempting to send message: $message');
      print('Order ID: ${widget.orderId}');
      print('User ID: ${widget.userId}');
      print('User Role: ${widget.userRole}');

      _messageController.clear();

      final messageData = {
        'orderId': widget.orderId,
        'message': message,
        'senderId': widget.userId,
        'senderRole': widget.userRole,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Message data to send: $messageData');

      final response = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: chatCollectionId,
        documentId: ID.unique(),
        data: messageData,
      );

      print('Message sent successfully: ${response.$id}');

      setState(() {
        _isSending = false;
      });
    } catch (e) {
      print('Detailed error sending message: $e');
      print('Error type: ${e.runtimeType}');

      // Cek jika error adalah AppwriteException
      if (e is AppwriteException) {
        print('Appwrite Error Code: ${e.code}');
        print('Appwrite Error Message: ${e.message}');
        print('Appwrite Error Type: ${e.type}');
        print('Appwrite Error Response: ${e.response}');
      }

      setState(() {
        _isSending = false;
      });

      // Tampilkan error yang lebih spesifik
      String errorMessage = 'Gagal mengirim pesan';
      if (e is AppwriteException) {
        switch (e.code) {
          case 401:
            errorMessage = 'Tidak memiliki izin untuk mengirim pesan';
            break;
          case 404:
            errorMessage = 'Database atau collection tidak ditemukan';
            break;
          case 400:
            errorMessage = 'Data pesan tidak valid';
            break;
          case 403:
            errorMessage = 'Akses ditolak';
            break;
          default:
            errorMessage = 'Error: ${e.message}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isMe = message['senderId'] == widget.userId;
    bool isEmployee = message['senderRole'] == 'employee';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      isEmployee ? 'Karyawan' : 'Pelanggan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[500] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isMe ? null : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    message['message'],
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message['timestamp']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk test koneksi
  Future<void> _testConnection() async {
    try {
      print('Testing connection...');
      final response = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: chatCollectionId,
        queries: [Query.limit(1)],
      );
      print(
          'Connection test successful: ${response.documents.length} documents found');
    } catch (e) {
      print('Connection test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: Color(0xFF0072BC),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.orderInfo,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Tambahkan tombol untuk test koneksi (development only)
          if (false) // Set ke true untuk development
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _testConnection,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white, // Explicit white background
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Memuat pesan...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada pesan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Mulai percakapan dengan mengirim pesan',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessage(_messages[index]);
                          },
                        ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Color(0xFF0072BC)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : Color(0xFF0072BC),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
