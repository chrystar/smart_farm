import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/shop_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Your Cart')),
          body: provider.cart.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.cart.length,
                  itemBuilder: (context, index) {
                    final item = provider.cart[index];
                    return Card(
                      child: ListTile(
                        leading: item.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.inventory_2),
                        title: Text(item.name),
                        subtitle: Text('₦${item.price.toStringAsFixed(2)} • ${item.unit}'),
                        trailing: SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => provider.updateQuantity(item.productId, item.quantity - 1),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => provider.updateQuantity(item.productId, item.quantity + 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: provider.cart.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => context.push('/shop/checkout'),
                    child: Text('Checkout • ₦${provider.subtotal.toStringAsFixed(2)}'),
                  ),
                ),
        );
      },
    );
  }
}
