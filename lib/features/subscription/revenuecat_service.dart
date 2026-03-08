import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:smart_farm/core/constants/revenuecat_constants.dart';

class RevenueCatService {
  Future<void> configure() async {
    final configuration = PurchasesConfiguration(RevenueCatConfig.apiKey);
    await Purchases.configure(configuration);
  }

  Future<Offerings> fetchOfferings() async {
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> fetchCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  bool isPremium(CustomerInfo info) {
    return info.entitlements.active[RevenueCatConfig.entitlementPro]?.isActive ??
        false;
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }
}
