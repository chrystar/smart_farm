import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'subscription_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final isPremium = provider.isPremium;
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Your Plan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Feature')),
                  DataColumn(label: Text('Freemium')),
                  DataColumn(label: Text('Premium')),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('Batch Creation')),
                    DataCell(Text('1')),
                    DataCell(Text('Unlimited')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Creator Features')),
                    DataCell(Icon(Icons.close, color: Colors.red)),
                    DataCell(Icon(Icons.check, color: Colors.green)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Report Droppings')),
                    DataCell(Icon(Icons.close, color: Colors.red)),
                    DataCell(Icon(Icons.check, color: Colors.green)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Export Expense')),
                    DataCell(Icon(Icons.close, color: Colors.red)),
                    DataCell(Icon(Icons.check, color: Colors.green)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Export Data')),
                    DataCell(Icon(Icons.close, color: Colors.red)),
                    DataCell(Icon(Icons.check, color: Colors.green)),
                  ]),
                ],
              ),
              const SizedBox(height: 24),
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (isPremium)
                const Center(
                  child: Text(
                    'You are a Premium user!',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                )
              else if (provider.availablePackages.isEmpty)
                Center(
                  child: Column(
                    children: [
                      if (provider.isLoading)
                        const CircularProgressIndicator()
                      else
                        const Text('No plans available right now.'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.refreshOfferings(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: provider.availablePackages.map((package) {
                    final product = package.storeProduct;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(product.title),
                        subtitle: Text(product.description),
                        trailing: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  await provider.purchase(package);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(provider.isPremium
                                            ? 'Purchase successful!'
                                            : 'Purchase completed.'),
                                      ),
                                    );
                                  }
                                },
                          child: Text(product.priceString),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed:
                      provider.isLoading ? null : provider.restorePurchases,
                  child: const Text('Restore Purchases'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
