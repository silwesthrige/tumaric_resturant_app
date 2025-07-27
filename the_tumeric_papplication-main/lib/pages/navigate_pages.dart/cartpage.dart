import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/data/food_details_data.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/models/promotion_model.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/services/cart_service.dart';
import 'package:the_tumeric_papplication/services/order_services.dart';
import 'package:the_tumeric_papplication/services/promotion_services.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
import 'package:the_tumeric_papplication/widgets/cart_add_card.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Store cart items with their quantities
  List<FoodDetailModel> cartItems = [];
  Map<String, int> itemQuantities = {};
  bool isLoading = true;
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final PromotionServices _promotionServices = PromotionServices();
  final TextEditingController _addressController = TextEditingController();
  bool isTouch = true;
  bool _isProcessingOrder = false;
  String _userAddress = "";

  // Offer-related variables
  ClaimedOffer? _selectedOffer;
  List<ClaimedOffer> _availableOffers = [];
  double _discountAmount = 0.0;
  bool _isLoadingOffers = false;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadUserAddress();
    _loadAvailableOffers();
  }

  // Load user's available offers
  Future<void> _loadAvailableOffers() async {
    try {
      setState(() {
        _isLoadingOffers = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final offersStream = _promotionServices.getUserClaimedOffers(user.uid);
        offersStream.listen((offers) {
          if (mounted) {
            final activeOffers =
                offers
                    .where(
                      (offer) =>
                          offer.isActive && !offer.isUsed && !offer.isExpired,
                    )
                    .toList();

            setState(() {
              _availableOffers = activeOffers;
              _isLoadingOffers = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading available offers: $e');
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  // Calculate discount based on selected offer
  void _calculateDiscount() {
    if (_selectedOffer != null) {
      setState(() {
        _discountAmount = _selectedOffer!.calculateDiscount(totalPrice);
      });
    } else {
      setState(() {
        _discountAmount = 0.0;
      });
    }
  }

  // Show offers selection dialog
  Future<void> _showOffersDialog() async {
    if (_availableOffers.isEmpty) {
      _showInfoDialog(
        'No Offers Available',
        'You don\'t have any active offers. Visit the offers page to claim some deals!',
        Icons.local_offer_outlined,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kMainOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            color: kMainOrange,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Select an Offer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availableOffers.length,
                        itemBuilder: (context, index) {
                          final offer = _availableOffers[index];
                          final discount = offer.calculateDiscount(totalPrice);
                          final isSelected = _selectedOffer?.id == offer.id;

                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isSelected
                                        ? kMainOrange
                                        : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color:
                                  isSelected
                                      ? kMainOrange.withOpacity(0.05)
                                      : Colors.white,
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? kMainOrange
                                          : Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_offer,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.green[600],
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                offer.discountText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? kMainOrange : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Save \$${discount.toStringAsFixed(2)}'),
                                  Text(
                                    'Expires in ${offer.daysUntilExpiry} days',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  isSelected
                                      ? Icon(
                                        Icons.check_circle,
                                        color: kMainOrange,
                                      )
                                      : null,
                              onTap: () {
                                setDialogState(() {
                                  if (isSelected) {
                                    // Deselect if already selected
                                    setState(() {
                                      _selectedOffer = null;
                                      _calculateDiscount();
                                    });
                                  } else {
                                    // Select this offer
                                    setState(() {
                                      _selectedOffer = offer;
                                      _calculateDiscount();
                                    });
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedOffer = null;
                                _calculateDiscount();
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('Clear Selection'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Apply Offer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  // Show info dialog
  void _showInfoDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(icon, color: kMainOrange),
                SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _loadUserAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userAddress = userData['address'] ?? '';
            _addressController.text = _userAddress;
          });
        }
      }
    } catch (e) {
      print('Error loading user address: $e');
    }
  }

  // Show address confirmation dialog
  Future<void> _showAddressConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.orange[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please confirm or update your delivery address:',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter your delivery address...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          setDialogState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please ensure your address is complete and accurate for successful delivery.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed:
                        _addressController.text.trim().isEmpty
                            ? null
                            : () {
                              Navigator.of(context).pop();
                              _processOrder();
                            },
                    child: const Text(
                      'Confirm & Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Process the order and save to Firebase
  Future<void> _processOrder() async {
    if (_isProcessingOrder) return;

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.orange[600]!,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing your order...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      // Convert cart items to order format with quantities
      List<Map<String, dynamic>> orderItems =
          cartItems.map((item) {
            final quantity = itemQuantities[item.foodId] ?? 1;
            return {
              'name': item.foodName ?? 'Unknown Item',
              'price': item.price ?? 0.0,
              'qty': quantity,
              'foodId': item.foodId ?? '',
            };
          }).toList();

      // Create order data with offer information
      Map<String, dynamic> orderData = {
        'items': orderItems,
        'deliveryAddress': _addressController.text.trim(),
        'status': 'pending',
        'subtotal': totalPrice,
        'tax': tax,
        'deliveryFee': deliveryFee,
        'discountAmount': _discountAmount,
        'finalTotal': finalTotal,
        'appliedOffer': _selectedOffer?.toJson(),
      };

      // Create order using OrderService
      String? orderId = await _orderService.createOrder(
        items: orderItems,
        deliveryAddress: _addressController.text.trim(),
        status: 'pending',
      );

      // If an offer was applied, mark it as used
      if (_selectedOffer != null && orderId != null) {
        await _promotionServices.useClaimedOffer(_selectedOffer!.id);
      }

      // Save address to user profile for future use
      await _saveUserAddress(_addressController.text.trim());

      // Close loading dialog
      Navigator.of(context).pop();

      if (orderId != null) {
        // Show success dialog
        _showOrderSuccessDialog(orderId, _discountAmount);

        // Clear cart from Firestore and local state
        await _clearCartAfterOrder();
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      _showErrorDialog('Failed to process order: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessingOrder = false;
      });
    }
  }

  // Clear cart after successful order
  Future<void> _clearCartAfterOrder() async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      await _cartService.clearCart(context, uid);

      setState(() {
        cartItems.clear();
        itemQuantities.clear();
        _selectedOffer = null;
        _discountAmount = 0.0;
      });
    } catch (e) {
      print('Error clearing cart after order: $e');
      // Don't show error for this as order was successful
    }
  }

  // Save user address to Firestore
  Future<void> _saveUserAddress(String address) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving address: $e');
    }
  }

  // Show order success dialog
  void _showOrderSuccessDialog(String orderId, double savedAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order ID: $orderId',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (savedAmount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.savings,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You saved \$${savedAmount.toStringAsFixed(2)}!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Your order has been placed and is pending confirmation. You will receive updates on the order status.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return HomePage();
                        },
                      ),
                    );
                  },
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text('Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Fixed: Load cart items using the existing CartService
  Future<void> _loadCartItems() async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      // Get user document to retrieve cart items with quantities
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        setState(() {
          cartItems = [];
          itemQuantities = {};
          isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> cartData = userData['cart'] ?? [];

      if (cartData.isEmpty) {
        setState(() {
          cartItems = [];
          itemQuantities = {};
          isLoading = false;
        });
        return;
      }

      // Convert cart data to CartItem objects and extract food IDs
      List<String> foodIds = [];
      Map<String, int> quantities = {};

      for (var item in cartData) {
        if (item is Map<String, dynamic>) {
          // New format with CartItem structure
          final cartItem = CartItem.fromJson(item);
          foodIds.add(cartItem.foodId);
          quantities[cartItem.foodId] = cartItem.quantity;
        } else if (item is String) {
          // Old format where cart items were just strings (food IDs)
          foodIds.add(item);
          quantities[item] = 1;
        }
      }

      // Use CartService to load food details from the correct collection
      List<DocumentSnapshot> foodDocs = await _cartService.getCartFoodDetails(
        foodIds,
      );

      // Convert documents to FoodDetailModel list
      List<FoodDetailModel> loadedCartItems = [];
      Map<String, int> loadedQuantities = {};

      for (DocumentSnapshot doc in foodDocs) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;

          // Create FoodDetailModel
          FoodDetailModel foodModel = FoodDetailModel.fromJsonFood(
            data,
            doc.id,
          );

          loadedCartItems.add(foodModel);
          loadedQuantities[doc.id] = quantities[doc.id] ?? 1;
        }
      }

      setState(() {
        cartItems = loadedCartItems;
        itemQuantities = loadedQuantities;
        isLoading = false;
      });

      // Calculate discount when cart is loaded
      _calculateDiscount();

      print("Loaded ${cartItems.length} cart items with quantities");
    } catch (e) {
      print("Error loading cart items: $e");

      setState(() {
        cartItems = [];
        itemQuantities = {};
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading cart items"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Remove item with proper type handling
  Future<void> _removeItem(int index) async {
    try {
      FoodDetailModel item = cartItems[index];
      String foodId = item.foodId ?? '';

      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Remove Item"),
              content: Text(
                "Are you sure you want to remove this item from your cart?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text("Remove"),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        // Remove from local state immediately
        setState(() {
          cartItems.removeAt(index);
          itemQuantities.remove(foodId);
        });

        // Recalculate discount
        _calculateDiscount();

        // Remove from Firestore
        await _cartService.removeFromCart(context, foodId);
      }
    } catch (e) {
      print("Error removing item: $e");
      _loadCartItems(); // Reload on error
    }
  }

  Future<void> _clearCart() async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      bool? confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Clear Cart"),
              content: Text(
                "Are you sure you want to remove all items from your cart?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text("Clear All"),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        setState(() {
          cartItems.clear();
          itemQuantities.clear();
          _selectedOffer = null;
          _discountAmount = 0.0;
        });

        await _cartService.clearCart(context, uid);
      }
    } catch (e) {
      print("Error clearing cart: $e");
      _loadCartItems();
    }
  }

  // Calculate totals with quantity consideration
  double get totalPrice {
    return cartItems.fold(0.0, (sum, item) {
      final price = (item.price ?? 0).toDouble();
      final quantity = itemQuantities[item.foodId] ?? 1;
      return sum + (price * quantity);
    });
  }

  double get tax {
    return totalPrice * 0.08; // 8% tax
  }

  double get deliveryFee {
    return cartItems.isEmpty ? 0 : 2.99;
  }

  double get finalTotal {
    return totalPrice + tax + deliveryFee - _discountAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "My Cart",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kmainBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 18,
                ),
              ),
              onPressed: _clearCart,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kMainOrange),
                  ),
                )
                : cartItems.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add some delicious items to get started!",
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return HomePage();
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Browse Menu",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    // Cart Items ListView
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final quantity = itemQuantities[item.foodId] ?? 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: CaertAddCard(
                              qty: quantity,
                              imageUrl: item.imageUrl,
                              title: item.foodName,
                              disc: item.shortDisc,
                              price: item.price,
                              onDelete: () {
                                CartService().removeFromCart(
                                  context,
                                  item.foodId!,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom checkout section
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Offers Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kMainOrange.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kMainOrange.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer,
                                        color: kMainOrange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedOffer != null
                                            ? 'Offer Applied'
                                            : 'Available Offers',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: kMainOrange,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_availableOffers.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kMainOrange,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${_availableOffers.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_selectedOffer != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedOffer!.discountText,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[600],
                                                  ),
                                                ),
                                                Text(
                                                  'You save ${_discountAmount.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedOffer = null;
                                                _calculateDiscount();
                                              });
                                            },
                                            child: Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: Colors.red[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    GestureDetector(
                                      onTap: _showOffersDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: kMainOrange.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              color: kMainOrange,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _availableOffers.isEmpty
                                                    ? 'No offers available'
                                                    : 'Tap to select an offer',
                                                style: TextStyle(
                                                  color:
                                                      _availableOffers.isEmpty
                                                          ? Colors.grey[600]
                                                          : kMainOrange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: kMainOrange,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Price breakdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Subtotal",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "${totalPrice.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kmainBlack,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tax (8%)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "${tax.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kmainBlack,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Delivery Fee",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "${deliveryFee.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kmainBlack,
                                  ),
                                ),
                              ],
                            ),

                            // Show discount if applied
                            if (_discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Discount",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                  Text(
                                    "${_discountAmount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),
                            Container(height: 1, color: Colors.grey[300]),
                            const SizedBox(height: 16),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: kmainBlack,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${finalTotal.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: kMainOrange,
                                      ),
                                    ),
                                    if (_discountAmount > 0)
                                      Text(
                                        "You saved ${_discountAmount.toStringAsFixed(2)}!",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Checkout button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kMainOrange, kmainGreen],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: kMainOrange.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap:
                                      _isProcessingOrder
                                          ? null
                                          : () {
                                            _showAddressConfirmationDialog();
                                          },
                                  child: Container(
                                    alignment: Alignment.center,
                                    child:
                                        _isProcessingOrder
                                            ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Proceed to Checkout",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
