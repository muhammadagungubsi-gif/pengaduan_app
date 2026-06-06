import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'login_screen.dart';


class UserScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Map userData = {};
  List feedbacks = [];
  bool isLoading = true;

  // For adding feedback
  final TextEditingController _feedbackController = TextEditingController();
  int selectedRating = 5;

  @override
  void initState() {
    super.initState();
    getUser();
    getFeedbacks();
  }

  // ======================================================
  // GET USER
  // ======================================================

  Future<void> getUser() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/${widget.userId}',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            userData = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      print('Error getUser: $e');
    }
  }

  // ======================================================
  // GET FEEDBACK USER SENDIRI
  // ======================================================

  Future<void> getFeedbacks() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/feedbacks?userId=${widget.userId}',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            feedbacks = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error getFeedbacks: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ======================================================
  // DELETE USER
  // ======================================================

  Future<void> deleteUser() async {
    await http.delete(
      Uri.parse(
        '$baseUrl/users/${widget.userId}',
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  // ======================================================
  // DELETE FEEDBACK
  // ======================================================

  Future<void> deleteFeedback(dynamic id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus feedback ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/feedbacks/$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Feedback berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        getFeedbacks();
      }
    } catch (e) {
      // Handled silently or log
    }
  }

  // ======================================================
  // EDIT PROFILE
  // ======================================================

  Future<void> updateProfile(String name, String email, String password) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${widget.userId}'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": name,
          "email": email,
          "password": password,
          "role": userData['role'] ?? 'user',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
        getUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error update profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: userData['name']?.toString() ?? '');
    final TextEditingController emailController = TextEditingController(text: userData['email']?.toString() ?? '');
    final TextEditingController passwordController = TextEditingController(text: userData['password']?.toString() ?? '');
    bool isPasswordObscured = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFB71C1C)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFB71C1C)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: isPasswordObscured,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFB71C1C)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              isPasswordObscured = !isPasswordObscured;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                      updateProfile(nameController.text, emailController.text, passwordController.text);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Semua kolom wajib diisi'),
                          backgroundColor: Colors.orange,
                        ),
                      );
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

  // ======================================================
  // ADD FEEDBACK
  // ======================================================

  Future<void> addFeedback() async {

    if (_feedbackController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Feedback tidak boleh kosong'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Validasi rating
      if (selectedRating < 1 || selectedRating > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Rating harus 1-5'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final feedbackData = {
        "userId": widget.userId,
        "comments": _feedbackController.text.trim(),
        "rating": selectedRating,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/feedbacks'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(feedbackData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _feedbackController.clear();
          setState(() {
            selectedRating = 5;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Feedback berhasil dikirim'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          getFeedbacks();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error ${response.statusCode}: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Request timeout (>10 detik)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ======================================================
  // UI
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Data Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
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
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ===================================
                  // PROFILE CARD
                  // ===================================
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB71C1C).withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: Text(
                                (userData['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB71C1C),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFFB71C1C)),
                                const SizedBox(width: 4),
                                Text(
                                  (userData['role'] ?? 'user').toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB71C1C),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userData['email']?.toString() ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: showEditProfileDialog,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Profil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: const Color(0xFFB71C1C),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===================================
                  // FORM FEEDBACK
                  // ===================================

                  Card(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Berikan Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Rating picker
                          const Text(
                            'Rating (1-5 bintang)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (index) {
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedRating = index + 1;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.star,
                                      size: 38,
                                      color: index < selectedRating
                                          ? Colors.amber
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.center,
                            child: Builder(
                              builder: (context) {
                                String textLabel = 'Sangat Baik';
                                Color colorLabel = Colors.green;
                                if (selectedRating == 1) {
                                  textLabel = 'Sangat Kurang';
                                  colorLabel = Colors.red;
                                } else if (selectedRating == 2) {
                                  textLabel = 'Kurang';
                                  colorLabel = Colors.orange;
                                } else if (selectedRating == 3) {
                                  textLabel = 'Cukup';
                                  colorLabel = Colors.amber.shade700;
                                } else if (selectedRating == 4) {
                                  textLabel = 'Baik';
                                  colorLabel = Colors.blue;
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorLabel.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Rating Anda: $selectedRating / 5 ($textLabel)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorLabel,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Feedback text
                          TextField(
                            controller: _feedbackController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tulis feedback Anda di sini...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE53935),
                                    Color(0xFFB71C1C),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB71C1C).withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send_outlined, color: Colors.white, size: 18),
                                label: const Text(
                                  'KIRIM FEEDBACK',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: addFeedback,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===================================
                  // FEEDBACK TITLE
                  // ===================================

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Feedback Saya',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===================================
                  // FEEDBACK LIST
                  // ===================================

                  feedbacks.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada feedback',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];
                            int rating = 0;
                            try {
                              rating = int.parse(feedback['rating'].toString());
                            } catch (e) {
                              rating = 0;
                            }
                            rating = rating > 5 ? 5 : rating;

                            Color ratingColor = Colors.green;
                            if (rating == 1) {
                              ratingColor = Colors.red;
                            } else if (rating == 2) {
                              ratingColor = Colors.orange;
                            } else if (rating == 3) {
                              ratingColor = Colors.amber;
                            } else if (rating == 4) {
                              ratingColor = Colors.blue;
                            }

                            return Card(
                              elevation: 2,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(
                                bottom: 14,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: ratingColor,
                                        width: 6,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Rating: $rating/5',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: ratingColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: List.generate(5, (i) {
                                                  return Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: i < rating
                                                        ? Colors.amber
                                                        : Colors.grey.shade300,
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              deleteFeedback(
                                                feedback['id'],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        feedback['comments']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
