import 'package:flutter/material.dart';
import 'dart:async';
import 'package:the_tumeric_papplication/services/feedback_services.dart';

class CreateFeedbackPage extends StatefulWidget {
  final Map<String, dynamic>? existingFeedback;

  const CreateFeedbackPage({Key? key, this.existingFeedback}) : super(key: key);

  @override
  State<CreateFeedbackPage> createState() => _CreateFeedbackPageState();
}

class _CreateFeedbackPageState extends State<CreateFeedbackPage> {
  final FeedbackService _feedbackService = FeedbackService();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _rating = 5.0;
  List<String> _selectedCategories = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _hasUnsavedChanges = false;
  Timer? _debounceTimer;

  static const List<String> _availableCategories = [
    'Food Quality',
    'Service',
    'Delivery Speed',
    'Packaging',
    'Value for Money',
    'Cleanliness',
    'Staff Behavior',
    'Order Accuracy',
  ];

  // Store original values for comparison
  late double _originalRating;
  late String _originalComment;
  late List<String> _originalCategories;

  // Cache rating colors for performance
  static const Map<String, Color> _ratingColors = {
    'poor': Colors.red,
    'fair': Colors.orange,
    'good': Colors.blue,
    'excellent': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingFeedback != null;

    if (_isEditMode) {
      _loadExistingFeedback();
    } else {
      _initializeDefaults();
    }

    _commentController.addListener(_onContentChanged);
  }

  void _initializeDefaults() {
    _originalRating = _rating;
    _originalComment = '';
    _originalCategories = [];
  }

  void _loadExistingFeedback() {
    try {
      final feedback = widget.existingFeedback!;

      _rating = _extractDouble(feedback['rating'], 5.0);
      _commentController.text = _extractString(feedback['comment'], '');
      _selectedCategories = _extractStringList(feedback['categories'], []);

      _originalRating = _rating;
      _originalComment = _commentController.text;
      _originalCategories = List<String>.from(_selectedCategories);
    } catch (e) {
      debugPrint('Error loading existing feedback: $e');
      _showSnackBar('Error loading feedback data', Colors.orange);
      _initializeDefaults();
    }
  }

  double _extractDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String _extractString(dynamic value, String defaultValue) {
    return value?.toString() ?? defaultValue;
  }

  List<String> _extractStringList(dynamic value, List<String> defaultValue) {
    if (value == null) return defaultValue;
    if (value is List) return value.map((e) => e.toString()).toList();
    return defaultValue;
  }

  void _onContentChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        final hasChanges = _hasContentChanged();
        if (hasChanges != _hasUnsavedChanges) {
          setState(() {
            _hasUnsavedChanges = hasChanges;
          });
        }
      }
    });
  }

  bool _hasContentChanged() {
    if (!_isEditMode) return true;

    return _rating != _originalRating ||
        _commentController.text.trim() != _originalComment.trim() ||
        !_listsEqual(_selectedCategories, _originalCategories);
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _commentController.removeListener(_onContentChanged);
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges || _isLoading,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_hasUnsavedChanges && !_isLoading) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isEditMode ? 'Edit Review' : 'Write a Review',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.orange,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (_isEditMode && _hasUnsavedChanges && !_isLoading)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _submitFeedback,
            tooltip: 'Save changes',
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildRatingCard(),
              const SizedBox(height: 20),
              _buildCategoriesCard(),
              const SizedBox(height: 20),
              _buildCommentCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildSubmitButton(),
    );
  }

  Future<bool> _showDiscardDialog() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to go back?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    return shouldPop ?? false;
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
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
            Icon(
              _isEditMode ? Icons.edit : Icons.rate_review,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditMode
                        ? 'Update Your Review'
                        : 'Share Your Experience',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditMode
                        ? 'Edit your feedback to help us improve'
                        : 'Your feedback helps us serve you better',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Overall Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(_rating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRatingColor(_rating)),
                  ),
                  child: Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRatingColor(_rating),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(_rating),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingStars(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getRatingColor(_rating),
                inactiveTrackColor: Colors.grey[300],
                thumbColor: _getRatingColor(_rating),
                overlayColor: _getRatingColor(_rating).withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: _rating,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                  _onContentChanged();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Semantics(
      label: 'Rating: ${_rating.toStringAsFixed(1)} out of 5 stars',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _rating = (index + 1).toDouble();
              });
              _onContentChanged();
            },
            child: Semantics(
              button: true,
              label: '${index + 1} star${index + 1 == 1 ? '' : 's'}',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    index < _rating.floor()
                        ? Icons.star
                        : index < _rating
                        ? Icons.star_half
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'What did you like/dislike?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select categories that apply to your experience (optional)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _availableCategories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                        _onContentChanged();
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.orange[600],
                      checkmarkColor: Colors.white,
                      elevation: isSelected ? 2 : 0,
                      pressElevation: 4,
                    );
                  }).toList(),
            ),
            if (_selectedCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_selectedCategories.length} ${_selectedCategories.length == 1 ? 'category' : 'categories'} selected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Additional Comments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Share more details about your experience (optional)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: _getCommentHint(),
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
                counterStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              validator: _validateComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _canSubmitFeedback();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading || !canSubmit ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isLoading
                  ? Colors.grey[400]
                  : canSubmit
                  ? Colors.orange[600]
                  : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canSubmit && !_isLoading ? 4 : 1,
        ),
        child:
            _isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditMode ? 'Updating...' : 'Submitting...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isEditMode ? Icons.update : Icons.send, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEditMode ? 'Update Review' : 'Submit Review',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  bool _canSubmitFeedback() {
    if (!_isEditMode) return true;
    return _hasUnsavedChanges;
  }

  String? _validateComment(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();
    if (trimmed.length > 500) {
      return 'Comment must be less than 500 characters';
    }

    return null;
  }

  bool _validateRating() {
    if (_rating < 1.0 || _rating > 5.0) {
      _showSnackBar(
        'Please select a rating between 1 and 5 stars',
        Colors.orange,
      );
      return false;
    }
    return true;
  }

  String _getCommentHint() {
    if (_rating <= 2.0) {
      return 'What could we improve? Your feedback helps us serve you better...';
    } else if (_rating >= 4.0) {
      return 'What did you enjoy most? Share what made your experience great...';
    } else {
      return 'Tell us about your experience...\n\nExample: The food was delicious and arrived hot. Great packaging and fast delivery!';
    }
  }

  String _getRatingText(double rating) {
    if (rating <= 1.5) return 'Poor';
    if (rating <= 2.5) return 'Fair';
    if (rating <= 3.5) return 'Good';
    if (rating <= 4.5) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2.0) return _ratingColors['poor']!;
    if (rating <= 3.0) return _ratingColors['fair']!;
    if (rating <= 4.0) return _ratingColors['good']!;
    return _ratingColors['excellent']!;
  }

  void _handleError(dynamic error, String operation) {
    String message = 'An error occurred';

    if (error.toString().contains('permission-denied')) {
      message = 'You don\'t have permission to perform this action';
    } else if (error.toString().contains('network-request-failed')) {
      message = 'Network error. Please check your connection';
    } else if (error.toString().contains('unavailable')) {
      message = 'Service temporarily unavailable. Please try again';
    } else if (error.toString().contains('timeout')) {
      message = 'Request timed out. Please try again';
    } else if (error.toString().contains('User not authenticated')) {
      message = 'Please log in to continue';
    } else {
      message = 'Failed to $operation. Please try again';
    }

    _showSnackBar(message, Colors.red);
  }

  Future<void> _submitFeedback() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate rating
    if (!_validateRating()) {
      return;
    }

    // Check authentication
    if (!_feedbackService.isAuthenticated) {
      _showSnackBar('Please log in to submit feedback', Colors.red);
      return;
    }

    // Show confirmation for low ratings
    if (_rating <= 2.0) {
      final shouldContinue = await _showLowRatingDialog();
      if (!shouldContinue) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final comment = _commentController.text.trim();

      if (_isEditMode) {
        final feedbackId = widget.existingFeedback?['id'];
        if (feedbackId == null || feedbackId.isEmpty) {
          throw Exception('Invalid feedback ID');
        }

        await _feedbackService.updateFeedback(
          feedbackId: feedbackId,
          rating: _rating,
          comment: comment,
          categories: _selectedCategories,
        );

        _showSnackBar('Review updated successfully!', Colors.green);
      } else {
        await _feedbackService.submitFeedback(
          rating: _rating,
          comment: comment,
          categories: _selectedCategories,
        );

        _showSnackBar('Review submitted successfully!', Colors.green);
      }

      // Update original values after successful submission
      _originalRating = _rating;
      _originalComment = comment;
      _originalCategories = List<String>.from(_selectedCategories);

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      _handleError(e, _isEditMode ? 'update review' : 'submit review');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showLowRatingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Low Rating'),
            content: const Text(
              'We\'re sorry to hear about your experience. Your feedback is valuable and helps us improve. Would you like to continue with this rating?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Let me reconsider'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: color == Colors.green ? 2 : 4),
        action:
            color == Colors.red
                ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _submitFeedback(),
                )
                : null,
      ),
    );
  }
}
