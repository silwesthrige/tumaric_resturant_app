import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:the_tumeric_papplication/pages/profile_pages/feedback_page.dart';

import 'package:the_tumeric_papplication/services/feedback_services.dart';

class FeedbacksPage extends StatefulWidget {
  const FeedbacksPage({Key? key}) : super(key: key);

  @override
  State<FeedbacksPage> createState() => _FeedbacksPageState();
}

class _FeedbacksPageState extends State<FeedbacksPage>
    with SingleTickerProviderStateMixin {
  final FeedbackService _feedbackService = FeedbackService();
  late TabController _tabController;
  List<Map<String, dynamic>>? _cachedUserFeedbacks;
  List<Map<String, dynamic>>? _cachedAllFeedbacks;
  bool _isLoading = true;
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  void _loadInitialData() async {
    try {
      final userFeedbacks = await _feedbackService.getUserFeedbacks();
      final allFeedbacks = await _feedbackService.getRestaurantFeedbacks();
      final avgRating = await _feedbackService.getAverageRating();
      final distribution = await _feedbackService.getRatingDistribution();

      if (mounted) {
        setState(() {
          _cachedUserFeedbacks = userFeedbacks;
          _cachedAllFeedbacks = allFeedbacks;
          _averageRating = avgRating;
          _ratingDistribution = distribution;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _refreshData() async {
    try {
      final userFeedbacks = await _feedbackService.getUserFeedbacks();
      final allFeedbacks = await _feedbackService.getRestaurantFeedbacks();
      final avgRating = await _feedbackService.getAverageRating();
      final distribution = await _feedbackService.getRatingDistribution();

      if (mounted) {
        setState(() {
          _cachedUserFeedbacks = userFeedbacks;
          _cachedAllFeedbacks = allFeedbacks;
          _averageRating = avgRating;
          _ratingDistribution = distribution;
        });
      }
    } catch (e) {
      // Silently handle errors for background refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Restaurant Feedbacks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _refreshData();
              _showSnackBar('Refreshing feedbacks...', Colors.orange);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.orange[100],
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'All Reviews'),
            Tab(icon: Icon(Icons.person), text: 'My Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllFeedbacks(), _buildUserFeedbacks()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateFeedbackPage()),
          );
        },

        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Review'),
      ),
    );
  }

  Widget _buildAllFeedbacks() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    final allFeedbacks = _cachedAllFeedbacks ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Overview Card
            _buildRatingOverview(),
            const SizedBox(height: 20),

            // Rating Distribution
            _buildRatingDistribution(),
            const SizedBox(height: 20),

            // Reviews List
            Text(
              'Recent Reviews (${allFeedbacks.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            if (allFeedbacks.isEmpty)
              _buildEmptyState(
                'No Reviews Yet',
                'Be the first to leave a review!',
                Icons.star_outline,
              )
            else
              ...allFeedbacks.map((feedback) => _buildFeedbackCard(feedback)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFeedbacks() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    final userFeedbacks = _cachedUserFeedbacks ?? [];

    if (userFeedbacks.isEmpty) {
      return _buildEmptyState(
        'No Reviews Yet',
        'You haven\'t left any reviews yet.\nTap the + button to add your first review!',
        Icons.rate_review_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userFeedbacks.length,
        itemBuilder: (context, index) {
          return _buildFeedbackCard(userFeedbacks[index], isUserFeedback: true);
        },
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          _buildStarRating(_averageRating, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${(_cachedAllFeedbacks?.length ?? 0)} reviews',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final totalReviews = _ratingDistribution.values.fold(0, (a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rating Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              final stars = 5 - index;
              final count = _ratingDistribution[stars] ?? 0;
              final percentage =
                  totalReviews > 0 ? (count / totalReviews) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('$stars'),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$count',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
    Map<String, dynamic> feedback, {
    bool isUserFeedback = false,
  }) {
    final rating = (feedback['rating'] ?? 0.0).toDouble();
    final comment = feedback['comment'] ?? '';
    final categories = List<String>.from(feedback['categories'] ?? []);
    final createdAt = feedback['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Icon(
                          Icons.person,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isUserFeedback ? 'Your Review' : 'Customer Review',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt.toDate()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    if (isUserFeedback) ...[
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editFeedback(feedback);
                          } else if (value == 'delete') {
                            _deleteFeedback(feedback['id']);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rating
            Row(
              children: [
                _buildStarRating(rating),
                const SizedBox(width: 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            // Categories
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    categories
                        .map(
                          (category) => Chip(
                            label: Text(
                              category,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.orange[100],
                            side: BorderSide(color: Colors.orange[300]!),
                          ),
                        )
                        .toList(),
              ),
            ],

            // Comment
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text('Loading feedbacks...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _editFeedback(Map<String, dynamic> feedback) {
    Navigator.pushNamed(context, '/create-feedback', arguments: feedback);
  }

  void _deleteFeedback(String feedbackId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text(
              'Are you sure you want to delete this review? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _feedbackService.deleteFeedback(feedbackId);
                    _showSnackBar('Review deleted successfully', Colors.green);
                    _refreshData();
                  } catch (e) {
                    _showSnackBar('Failed to delete review: $e', Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
