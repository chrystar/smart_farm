import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/payment_service.dart';
import '../../data/shop_service.dart';
import '../../models/cart_item.dart';
import '../../models/delivery_zone.dart';
import '../../models/order_detail.dart';
import '../../models/order_summary.dart';
import '../../models/pickup_location.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';

class ShopProvider extends ChangeNotifier {
  final ShopService _shopService;
  final PaymentService _paymentService;
  final SupabaseService _supabaseService;

  ShopProvider({
    required ShopService shopService,
    required PaymentService paymentService,
    required SupabaseService supabaseService,
  })  : _shopService = shopService,
        _paymentService = paymentService,
        _supabaseService = supabaseService;

  bool _isLoading = false;
  String? _error;
  List<ProductCategory> _categories = [];
  List<Product> _products = [];
  List<CartItem> _cart = [];
  List<PickupLocation> _pickupLocations = [];
  List<DeliveryZone> _deliveryZones = [];

  String? _selectedCategoryId;
  String _fulfillmentType = 'pickup';
  String _paymentMethod = 'cash';
  String? _selectedPickupLocationId;
  String? _selectedDeliveryZoneId;
  String? _deliveryAddress;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductCategory> get categories => _categories;
  List<Product> get products => _products;
  List<CartItem> get cart => _cart;
  List<PickupLocation> get pickupLocations => _pickupLocations;
  List<DeliveryZone> get deliveryZones => _deliveryZones;
  String? get selectedCategoryId => _selectedCategoryId;
  String get fulfillmentType => _fulfillmentType;
  String get paymentMethod => _paymentMethod;
  String? get selectedPickupLocationId => _selectedPickupLocationId;
  String? get selectedDeliveryZoneId => _selectedDeliveryZoneId;
  String? get deliveryAddress => _deliveryAddress;

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.price * item.quantity);

  double get deliveryFee {
    if (_fulfillmentType != 'delivery' || _selectedDeliveryZoneId == null) return 0;
    final zone = _deliveryZones.firstWhere(
      (z) => z.id == _selectedDeliveryZoneId,
      orElse: () => const DeliveryZone(
        id: '',
        stateName: '',
        deliveryFee: 0,
        estimatedDays: null,
        isActive: true,
      ),
    );
    return zone.deliveryFee;
  }

  double get total => subtotal + deliveryFee;

  Future<void> loadCatalog() async {
    _setLoading(true);
    try {
      _categories = await _shopService.fetchCategories();
      _products = await _shopService.fetchProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    _setLoading(true);
    try {
      _products = await _shopService.fetchProducts(categoryId: categoryId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      return await _shopService.fetchProductById(id);
    } catch (_) {
      return null;
    }
  }

  void addToCart(Product product, int quantity) {
    final existing = _cart.indexWhere((item) => item.productId == product.id);
    if (existing >= 0) {
      final current = _cart[existing];
      _cart[existing] = current.copyWith(quantity: current.quantity + quantity);
    } else {
      _cart.add(CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        unit: product.unit,
        quantity: quantity,
        imageUrl: product.images.isNotEmpty ? product.images.first : null,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _cart.indexWhere((item) => item.productId == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index] = _cart[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart = [];
    notifyListeners();
  }

  Future<void> loadCheckoutData() async {
    _setLoading(true);
    try {
      _pickupLocations = await _shopService.fetchPickupLocations();
      _deliveryZones = await _shopService.fetchDeliveryZones();
      if (_selectedPickupLocationId == null && _pickupLocations.isNotEmpty) {
        _selectedPickupLocationId = _pickupLocations.first.id;
      }
      if (_selectedDeliveryZoneId == null && _deliveryZones.isNotEmpty) {
        _selectedDeliveryZoneId = _deliveryZones.first.id;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setFulfillmentType(String value) {
    _fulfillmentType = value;
    if (_fulfillmentType == 'delivery') {
      _paymentMethod = 'online';
    } else {
      _paymentMethod = 'cash';
    }
    notifyListeners();
  }

  void setPickupLocation(String id) {
    _selectedPickupLocationId = id;
    notifyListeners();
  }

  void setDeliveryZone(String id) {
    _selectedDeliveryZoneId = id;
    notifyListeners();
  }

  void setDeliveryAddress(String value) {
    _deliveryAddress = value;
    notifyListeners();
  }

  Future<OrderSummary?> placeOrder({required String contactEmail}) async {
    if (_cart.isEmpty) return null;
    final userId = _supabaseService.currentUserId;
    if (userId == null) return null;

    _setLoading(true);
    try {
      String? paymentReference;
      if (_paymentMethod == 'online') {
        paymentReference = await _paymentService.startOnlinePayment(
          amount: total,
          email: contactEmail,
        );
      }

      final items = _cart
          .map((item) => {
                'product_id': item.productId,
                'product_name': item.name,
                'price_at_purchase': item.price,
                'quantity': item.quantity,
                'unit': item.unit,
              })
          .toList();

      final order = await _shopService.createOrder(
        userId: userId,
        fulfillmentType: _fulfillmentType,
        pickupLocationId: _fulfillmentType == 'pickup' ? _selectedPickupLocationId : null,
        deliveryZoneId: _fulfillmentType == 'delivery' ? _selectedDeliveryZoneId : null,
        deliveryAddress: _fulfillmentType == 'delivery' ? _deliveryAddress : null,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        totalAmount: total,
        paymentMethod: _paymentMethod,
        paymentReference: paymentReference,
        items: items,
      );
      clearCart();
      _error = null;
      return order;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<OrderSummary>> loadOrders() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return [];
    return _shopService.fetchOrders(userId);
  }

  Future<OrderDetail> loadOrderDetail(String orderId) {
    return _shopService.fetchOrderDetail(orderId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
