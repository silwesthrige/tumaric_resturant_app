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

  // Data state
  List<Map<String, dynamic>> _userFeedbacks = [];
  List<Map<String, dynamic>> _allFeedbacks = [];
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  // Loading states
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Timers and subscriptions
  Timer? _refreshTimer;
  StreamSubscription<QuerySnapshot>? _feedbackSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _feedbackSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadInitialData();
    _setupRealtimeListeners();
    _startAutoRefresh();
  }

  void _setupRealtimeListeners() {
    try {
      _feedbackSubscription = FirebaseFirestore.instance
          .collection('feedbacks')
          .snapshots()
          .listen(
            (snapshot) {
              if (mounted && !_isLoading) {
                _refreshData(showLoadingIndicator: false);
              }
            },
            onError: (error) {
              debugPrint('Firestore listener error: $error');
              if (mounted) {
                _showSnackBar(
                  'Connection issue. Please check your internet.',
                  Colors.orange,
                );
              }
            },
          );
    } catch (e) {
      debugPrint('Error setting up listeners: $e');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && !_isRefreshing) {
        _refreshData(showLoadingIndicator: false);
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Test connection first
      final hasConnection = await _feedbackService.testConnection();
      if (!hasConnection) {
        throw Exception('No internet connection');
      }

      // Load all data concurrently with timeout
      final results = await Future.wait([
        _feedbackService.getUserFeedbacks(),
        _feedbackService.getRestaurantFeedbacks(),
        _feedbackService.getAverageRating(),
        _feedbackService.getRatingDistribution(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            'Request timeout. Please check your internet connection.',
          );
        },
      );

      if (mounted) {
        setState(() {
          _userFeedbacks = results[0] as List<Map<String, dynamic>>;
          _allFeedbacks = results[1] as List<Map<String, dynamic>>;
          _averageRating = results[2] as double;
          _ratingDistribution = results[3] as Map<int, int>;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getErrorMessage(e);

          // Set safe default values
          _userFeedbacks = [];
          _allFeedbacks = [];
          _averageRating = 0.0;
          _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        });

        _showSnackBar(_errorMessage, Colors.red);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Connection timeout. Please check your internet.';
    } else if (errorString.contains('permission-denied')) {
      return 'Access denied. Please check your login status.';
    } else if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    } else if (errorString.contains('index')) {
      return 'Database setup in progress. Please try again in a moment.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Unable to load feedbacks. Please try again.';
    }
  }

  Future<void> _refreshData({bool showLoadingIndicator = true}) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final results = await Future.wait([
        _feedbackService.getUserFeedbacks(),
        _feedbackService.getRestaurantFeedbacks(),
        _feedbackService.getAverageRating(),
        _feedbackService.getRatingDistribution(),
      ]).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _userFeedbacks = results[0] as List<Map<String, dynamic>>;
          _allFeedbacks = results[1] as List<Map<String, dynamic>>;
          _averageRating = results[2] as double;
          _ratingDistribution = results[3] as Map<int, int>;
          _isRefreshing = false;
          _hasError = false;
        });

        if (showLoadingIndicator) {
          _showSnackBar('Feedbacks updated', Colors.green);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        if (showLoadingIndicator) {
          _showSnackBar(_getErrorMessage(e), Colors.red);
        }
      }
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
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : () => _refreshData(),
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
      body: _hasError ? _buildErrorWidget() : _buildTabBarView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateFeedback,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Review'),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [_buildAllFeedbacks(), _buildUserFeedbacks()],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllFeedbacks() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingOverview(),
            const SizedBox(height: 20),
            _buildRatingDistribution(),
            const SizedBox(height: 20),
            Text(
              'Recent Reviews (${_allFeedbacks.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (_allFeedbacks.isEmpty)
              _buildEmptyState(
                'No Reviews Yet',
                'Be the first to leave a review!',
                Icons.star_outline,
              )
            else
              ..._allFeedbacks.map((feedback) => _buildFeedbackCard(feedback)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFeedbacks() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_userFeedbacks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildEmptyState(
              'No Reviews Yet',
              'You haven\'t left any reviews yet.\nTap the + button to add your first review!',
              Icons.rate_review_outlined,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userFeedbacks.length,
        itemBuilder: (context, index) {
          return _buildFeedbackCard(
            _userFeedbacks[index],
            isUserFeedback: true,
          );
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStarRating(_averageRating, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${_allFeedbacks.length} reviews',
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
                        valueColor: const AlwaysStoppedAnimation<Color>(
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
    final userId = feedback['userId'] ?? '';

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
                          isUserFeedback ? Icons.person : Icons.account_circle,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUserFeedback
                                  ? 'Your Review'
                                  : 'Customer Review',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            if (!isUserFeedback && userId.isNotEmpty)
                              Text(
                                'User: ${userId.length > 8 ? userId.substring(0, 8) : userId}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
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
                const Spacer(),
                if (isUserFeedback)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
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
                width: double.infinity,
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
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _navigateToCreateFeedback() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateFeedbackPage()),
      );

      if (result == true && mounted) {
        await _refreshData();
      }
    } catch (e) {
      debugPrint('Error navigating to create feedback: $e');
      _showSnackBar('Unable to open feedback form', Colors.red);
    }
  }

  Future<void> _editFeedback(Map<String, dynamic> feedback) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateFeedbackPage(),
          settings: RouteSettings(arguments: feedback),
        ),
      );

      if (result == true && mounted) {
        await _refreshData();
      }
    } catch (e) {
      debugPrint('Error navigating to edit feedback: $e');
      _showSnackBar('Unable to edit feedback', Colors.red);
    }
  }

  Future<void> _deleteFeedback(String? feedbackId) async {
    if (feedbackId == null || feedbackId.isEmpty) {
      _showSnackBar('Invalid feedback ID', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text(
              'Are you sure you want to delete this review? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
    );

    try {
      await _feedbackService.deleteFeedback(feedbackId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Review deleted successfully', Colors.green);
        await _refreshData();
      }
    } catch (e) {
      debugPrint('Error deleting feedback: $e');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar(
          'Failed to delete review: ${_getErrorMessage(e)}',
          Colors.red,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action:
            color == Colors.red
                ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _refreshData(),
                )
                : null,
      ),
    );
  }
}
