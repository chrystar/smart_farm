import '../../../core/services/supabase_service.dart';
import '../models/delivery_zone.dart';
import '../models/order_detail.dart';
import '../models/order_item.dart';
import '../models/order_summary.dart';
import '../models/pickup_location.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class ShopService {
  final SupabaseService _supabaseService;

  ShopService(this._supabaseService);

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await _supabaseService.client
        .from('product_categories')
        .select()
        .eq('is_active', true)
        .order('display_order')
        .order('name');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(ProductCategory.fromJson)
        .toList();
  }

  Future<List<Product>> fetchProducts({String? categoryId}) async {
    final response = categoryId == null
        ? await _supabaseService.client
            .from('products')
            .select()
            .eq('is_active', true)
            .order('created_at', ascending: false)
        : await _supabaseService.client
            .from('products')
            .select()
            .eq('is_active', true)
            .eq('category_id', categoryId)
            .order('created_at', ascending: false);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<Product?> fetchProductById(String id) async {
    final response = await _supabaseService.client
        .from('products')
        .select()
        .eq('id', id)
        .single();
    return Product.fromJson(response);
  }

  Future<List<PickupLocation>> fetchPickupLocations() async {
    final response = await _supabaseService.client
        .from('pickup_locations')
        .select()
        .eq('is_active', true)
        .order('location_name');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(PickupLocation.fromJson)
        .toList();
  }

  Future<List<DeliveryZone>> fetchDeliveryZones() async {
    final response = await _supabaseService.client
        .from('delivery_zones')
        .select()
        .eq('is_active', true)
        .order('state_name');

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(DeliveryZone.fromJson)
        .toList();
  }

  Future<OrderSummary> createOrder({
    required String userId,
    required String fulfillmentType,
    String? pickupLocationId,
    String? deliveryZoneId,
    String? deliveryAddress,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    required String paymentMethod,
    String? paymentReference,
    required List<Map<String, dynamic>> items,
  }) async {
    final order = await _supabaseService.client
        .from('orders')
        .insert({
          'user_id': userId,
          'fulfillment_type': fulfillmentType,
          'pickup_location_id': pickupLocationId,
          'delivery_zone_id': deliveryZoneId,
          'delivery_address': deliveryAddress,
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'payment_status': paymentReference == null ? 'pending' : 'paid',
          'payment_reference': paymentReference,
        })
        .select()
        .single();

    final orderId = order['id'] as String;
    final orderItems = items
        .map((item) => {
              'order_id': orderId,
              'product_id': item['product_id'],
              'product_name': item['product_name'],
              'price_at_purchase': item['price_at_purchase'],
              'quantity': item['quantity'],
              'unit': item['unit'],
            })
        .toList();

    await _supabaseService.client.from('order_items').insert(orderItems);
    return OrderSummary.fromJson(order);
  }

  Future<List<OrderSummary>> fetchOrders(String userId) async {
    final response = await _supabaseService.client
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(OrderSummary.fromJson)
        .toList();
  }

  Future<OrderDetail> fetchOrderDetail(String orderId) async {
    final order = await _supabaseService.client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();

    final items = await _supabaseService.client
        .from('order_items')
        .select()
        .eq('order_id', orderId)
        .order('created_at');

    final parsedItems = (items as List)
        .cast<Map<String, dynamic>>()
        .map(OrderItem.fromJson)
        .toList();

    return OrderDetail.fromJson(order, parsedItems);
  }
}
