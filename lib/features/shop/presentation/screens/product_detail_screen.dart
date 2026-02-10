import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../provider/shop_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShopProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/shop/cart'),
          ),
        ],
      ),
      body: FutureBuilder<Product?>(
        future: provider.getProductById(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Unable to load product.'));
          }
          final product = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.images.first,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: const Icon(Icons.inventory_2, size: 64),
                  ),
                const SizedBox(height: 16),
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('₦${product.price.toStringAsFixed(2)} / ${product.unit}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if ((product.description ?? '').isNotEmpty)
                  Text(product.description!, style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ShopProvider>().addToCart(product, _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Add to cart'),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
