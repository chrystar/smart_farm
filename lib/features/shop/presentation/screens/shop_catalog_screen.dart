import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../provider/shop_provider.dart';

class ShopCatalogScreen extends StatefulWidget {
  const ShopCatalogScreen({super.key});

  @override
  State<ShopCatalogScreen> createState() => _ShopCatalogScreenState();
}

class _ShopCatalogScreenState extends State<ShopCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poultry Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/shop/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/shop/orders'),
          ),
        ],
      ),
      body: Consumer<ShopProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          return RefreshIndicator(
            onRefresh: provider.loadCatalog,
            child: Column(
              children: [
                _buildCategoryChips(provider),
                const Divider(height: 1),
                Expanded(child: _buildProductList(provider.products)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(ShopProvider provider) {
    final categories = provider.categories;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: provider.selectedCategoryId == null,
            onSelected: (_) => provider.selectCategory(null),
          ),
          const SizedBox(width: 8),
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category.name),
                  selected: provider.selectedCategoryId == category.id,
                  onSelected: (_) => provider.selectCategory(category.id),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: ListTile(
            leading: product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      product.images.first,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.inventory_2),
            title: Text(product.name),
            subtitle: Text('₦${product.price.toStringAsFixed(2)} • ${product.unit}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/shop/product/${product.id}'),
          ),
        );
      },
    );
  }
}
