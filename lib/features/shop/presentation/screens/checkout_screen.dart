import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/shop_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _deliveryAddressController = TextEditingController();
  final _contactEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadCheckoutData();
    });
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final provider = context.read<ShopProvider>();
    final email = _contactEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    if (provider.fulfillmentType == 'delivery' && provider.selectedDeliveryZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery zone')),
      );
      return;
    }

    final order = await provider.placeOrder(contactEmail: email);
    if (!mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: ${provider.error ?? "Unknown"}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      context.go('/shop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer<ShopProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pickupLocations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fulfillment Type', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Pickup'),
                  value: 'pickup',
                  groupValue: provider.fulfillmentType,
                  onChanged: (val) => provider.setFulfillmentType(val!),
                ),
                RadioListTile<String>(
                  title: const Text('Delivery'),
                  value: 'delivery',
                  groupValue: provider.fulfillmentType,
                  onChanged: (val) => provider.setFulfillmentType(val!),
                ),
                const Divider(height: 32),
                if (provider.fulfillmentType == 'pickup') ...[
                  const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...provider.pickupLocations.map((loc) => RadioListTile<String>(
                        title: Text(loc.locationName),
                        subtitle: Text('${loc.address}${loc.state != null ? " • ${loc.state}" : ""}'),
                        value: loc.id,
                        groupValue: provider.selectedPickupLocationId,
                        onChanged: (val) => provider.setPickupLocation(val!),
                      )),
                ] else ...[
                  const Text('Delivery Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: provider.selectedDeliveryZoneId,
                    items: provider.deliveryZones
                        .map((z) => DropdownMenuItem(
                              value: z.id,
                              child: Text('${z.stateName} - ₦${z.deliveryFee.toStringAsFixed(2)}'),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'State',
                    ),
                    onChanged: (val) => provider.setDeliveryZone(val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryAddressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Delivery Address',
                    ),
                    onChanged: provider.setDeliveryAddress,
                  ),
                ],
                const Divider(height: 32),
                const Text('Contact Email', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
                const Divider(height: 32),
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(provider.fulfillmentType == 'pickup' ? 'Cash on Pickup' : 'Online Payment',
                    style: const TextStyle(fontSize: 16)),
                const Divider(height: 32),
                const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Subtotal'),
                  Text('₦${provider.subtotal.toStringAsFixed(2)}'),
                ]),
                if (provider.fulfillmentType == 'delivery') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Delivery Fee'),
                    Text('₦${provider.deliveryFee.toStringAsFixed(2)}'),
                  ]),
                ],
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₦${provider.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _placeOrder,
                    child: provider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Place Order'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
