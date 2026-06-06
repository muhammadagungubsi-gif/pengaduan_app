import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

const String baseUrl = "https://6a1114213e35d0f37ee2fad9.mockapi.io";

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
    await http.delete(
      Uri.parse(
        '$baseUrl/feedbacks/$id',
      ),
    );

    getFeedbacks();
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

      print('Sending feedback: $feedbackData');

      final response = await http.post(
        Uri.parse('$baseUrl/feedbacks'),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(feedbackData),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
          
          // Refresh feedback list
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
      print('Error addFeedback: $e');
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
        backgroundColor: const Color(0xFFB71C1C),
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
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ===================================
                  // PROFILE
                  // ===================================

                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.red.shade100,
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB71C1C),
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

                  const SizedBox(height: 6),

                  Text(
                    userData['email']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===================================
                  // FORM FEEDBACK
                  // ===================================

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
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
                                      size: 40,
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
                          Text(
                            'Rating: $selectedRating / 5',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB71C1C),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Feedback text
                          TextField(
                            controller: _feedbackController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tulis feedback Anda di sini...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Kirim Feedback'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: addFeedback,
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
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feedbacks.length,
                          itemBuilder: (context, index) {
                            final feedback = feedbacks[index];

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(
                                bottom: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
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
                                            Builder(
                                              builder: (context) {
                                                int rating = 0;
                                                try {
                                                  rating = int.parse(feedback['rating'].toString());
                                                } catch (e) {
                                                  rating = 0;
                                                }
                                                
                                                // Cap rating to 5
                                                rating = rating > 5 ? 5 : rating;
                                                
                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Rating: $rating/5',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Color(0xFFB71C1C),
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
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
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
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
