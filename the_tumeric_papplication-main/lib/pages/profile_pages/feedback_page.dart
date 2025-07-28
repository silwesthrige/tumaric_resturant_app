import 'package:flutter/material.dart';

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

  final List<String> _availableCategories = [
    'Food Quality',
    'Service',
    'Delivery Speed',
    'Packaging',
    'Value for Money',
    'Cleanliness',
    'Staff Behavior',
    'Order Accuracy',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingFeedback != null;
    if (_isEditMode) {
      _loadExistingFeedback();
    }
  }

  void _loadExistingFeedback() {
    final feedback = widget.existingFeedback!;
    _commentController.text = feedback['comment'] ?? '';
    _rating = (feedback['rating'] ?? 5.0).toDouble();
    _selectedCategories = List<String>.from(feedback['categories'] ?? []);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 20),

              // Rating Card
              _buildRatingCard(),
              const SizedBox(height: 20),

              // Categories Card
              _buildCategoriesCard(),
              const SizedBox(height: 20),

              // Comment Card
              _buildCommentCard(),
              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
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
            const Icon(Icons.rate_review, color: Colors.white, size: 40),
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

  Widget _buildOrderDetailsCard() {
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
                Icon(Icons.receipt_long, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
              ],
            ),
            const SizedBox(height: 20),

            // Rating Display
            Center(
              child: Column(
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = (index + 1).toDouble();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rating Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.orange,
                inactiveTrackColor: Colors.orange[200],
                thumbColor: Colors.orange[600],
                overlayColor: Colors.orange.withOpacity(0.2),
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
                },
              ),
            ),
          ],
        ),
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
              'Select categories that apply to your experience',
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
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.orange[600],
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
            ),
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
              decoration: InputDecoration(
                hintText:
                    'Tell us about your experience...\n\nExample: The food was delicious and arrived hot. Great packaging and fast delivery!',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[600]!),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
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

  String _getRatingText(double rating) {
    if (rating <= 1.5) return 'Poor';
    if (rating <= 2.5) return 'Fair';
    if (rating <= 3.5) return 'Good';
    if (rating <= 4.5) return 'Very Good';
    return 'Excellent';
  }

  void _submitFeedback() async {
    if (_commentController.text.trim().isEmpty && _selectedCategories.isEmpty) {
      _showSnackBar('Please add a comment or select categories', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode) {
        await _feedbackService.updateFeedback(
          feedbackId: widget.existingFeedback!['id'],
          rating: _rating,
          comment: _commentController.text.trim(),
          categories: _selectedCategories,
        );
        _showSnackBar('Review updated successfully!', Colors.green);
      } else {
        await _feedbackService.submitFeedback(
          rating: _rating,
          comment: _commentController.text.trim(),
          categories: _selectedCategories,
        );
        _showSnackBar('Review submitted successfully!', Colors.green);
      }

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showSnackBar(
        'Failed to ${_isEditMode ? 'update' : 'submit'} review: $e',
        Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
