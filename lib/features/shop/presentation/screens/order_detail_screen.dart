import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_detail.dart';
import '../provider/shop_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShopProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<OrderDetail>(
        future: provider.loadOrderDetail(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error: ${snapshot.error ?? "Unknown"}'));
          }
          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.orderNumber}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(order.status)),
                    const SizedBox(width: 8),
                    Chip(label: Text(order.paymentStatus)),
                  ],
                ),
                const Divider(height: 32),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...order.items.map((item) => ListTile(
                      title: Text(item.productName),
                      subtitle: Text('${item.quantity} ${item.unit} @ ₦${item.priceAtPurchase.toStringAsFixed(2)}'),
                      trailing: Text('₦${(item.quantity * item.priceAtPurchase).toStringAsFixed(2)}'),
                    )),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Subtotal'),
                  Text('₦${order.subtotal.toStringAsFixed(2)}'),
                ]),
                if (order.deliveryFee > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Delivery'),
                    Text('₦${order.deliveryFee.toStringAsFixed(2)}'),
                  ]),
                ],
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₦${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const Divider(height: 32),
                const Text('Fulfillment', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(order.fulfillmentType == 'pickup' ? 'Pickup' : 'Delivery'),
                if (order.deliveryAddress != null) ...[
                  const SizedBox(height: 8),
                  Text(order.deliveryAddress!),
                ],
                const Divider(height: 32),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(order.paymentMethod == 'cash' ? 'Cash' : 'Online Payment'),
              ],
            ),
          );
        },
      ),
    );
  }
}
