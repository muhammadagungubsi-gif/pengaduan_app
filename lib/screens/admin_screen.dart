import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

const String baseUrl = "https://6a1114213e35d0f37ee2fad9.mockapi.io";

class AdminScreen extends StatefulWidget {
  final String? adminUserId;
  final String? adminUserName;

  const AdminScreen({
    super.key,
    this.adminUserId,
    this.adminUserName,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  List users = [];
  List feedbacks = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getUsers();
    getAllFeedbacks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =====================================================
  // GET USERS
  // =====================================================

  Future<void> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
    );

    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  // =====================================================
  // GET ALL FEEDBACKS
  // =====================================================

  Future<void> getAllFeedbacks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/feedbacks'),
    );

    if (response.statusCode == 200) {
      setState(() {
        feedbacks = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  // =====================================================
  // GET USER NAME
  // =====================================================

  String getUserName(dynamic userId) {
    try {
      // Extract angka dari userId (e.g., "userId 1" -> "1")
      String cleanUserId = (userId ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
      
      if (cleanUserId.isEmpty) return 'Unknown';
      
      final user = users.firstWhere(
        (u) {
          String uId = (u['id'] ?? '').toString().trim();
          return uId == cleanUserId;
        },
        orElse: () => {'name': 'Unknown'},
      );
      return user['name'] ?? 'Unknown';
    } catch (e) {
      print('Error getUserName: $e');
      return 'Unknown';
    }
  }

  // =====================================================
  // DELETE FEEDBACK
  // =====================================================

  Future<void> deleteFeedback(dynamic id) async {
    await http.delete(
      Uri.parse('$baseUrl/feedbacks/$id'),
    );
    getAllFeedbacks();
  }

  // =====================================================
  // DELETE USER
  // =====================================================

  Future<void> deleteUser(dynamic id) async {
    await http.delete(
      Uri.parse(
        '$baseUrl/users/$id',
      ),
    );

    getUsers();
  }

  // =====================================================
  // SHOW USER DETAIL WITH FEEDBACKS
  // =====================================================

  void showUserDetail(Map user) {
    final userFeedbacks = feedbacks
        .where((f) {
          // Extract angka dari userId
          String feedbackUserId = (f['userId'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '').trim();
          String userId = (user['id'] ?? '').toString().trim();
          
          return feedbackUserId == userId;
        })
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user['role'] == 'admin'
                                      ? Colors.red
                                      : Colors.teal,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user['role'].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Feedback Section
                    const Text(
                      'Feedback & Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (userFeedbacks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Belum ada feedback dari user ini',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userFeedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = userFeedbacks[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            Icons.star,
                                            size: 18,
                                            color: i <
                                                    (feedback['rating'] ?? 0)
                                                ? Colors.amber
                                                : Colors.grey.shade300,
                                          );
                                        }),
                                      ),
                                      Text(
                                        '${feedback['rating']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB71C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feedback['comments'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ADD USER
  // =====================================================

  Future<void> addUser(
    String name,
    String email,
    String role,
  ) async {
    await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({
        "name": name,
        "email": email,
        "role": role,
        "avatar": "avatar baru",
      }),
    );

    getUsers();
  }

  // =====================================================
  // DIALOG ADD USER
  // =====================================================

  void showAddUserDialog() {
    final TextEditingController nameController = TextEditingController();

    final TextEditingController emailController = TextEditingController();

    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Tambah User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('User'),
                      ),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedRole = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Role',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        emailController.text.isNotEmpty) {
                      await addUser(
                        nameController.text,
                        emailController.text,
                        selectedRole,
                      );

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('Users'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.feedback),
                  SizedBox(width: 8),
                  Text('Feedback'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFB71C1C),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: showAddUserDialog,
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: USERS LIST
                ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    
                    // Skip admin user yang sedang login
                    if (widget.adminUserId != null && 
                        user['id']?.toString() == widget.adminUserId) {
                      return const SizedBox.shrink();
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        onTap: () => showUserDetail(user),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            user['name'][0],
                            style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: user['role'] == 'admin'
                                    ? Colors.red
                                    : Colors.teal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                user['role'],
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                deleteUser(user['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // TAB 2: FEEDBACKS LIST
                feedbacks.isEmpty
                    ? const Center(
                        child: Text('Belum ada feedback'),
                      )
                    : ListView.builder(
                        itemCount: feedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = feedbacks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            getUserName(feedback['userId'] ?? ''),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                Icons.star,
                                                size: 16,
                                                color: i <
                                                        (feedback['rating'] ??
                                                            0)
                                                    ? Colors.amber
                                                    : Colors.grey.shade300,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          deleteFeedback(feedback['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feedback['comments'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
