import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenuecat_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._service);

  final RevenueCatService _service;

  bool _isPremium = false;
  bool _isLoading = false;
  String? _errorMessage;
  Offering? _currentOffering;
  List<Package> _packages = [];

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Offering? get currentOffering => _currentOffering;
  List<Package> get availablePackages => _packages;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _service.configure();
      await refreshOfferings();
      await refreshCustomerInfo();
    } catch (error) {
      _errorMessage = 'Failed to initialize subscriptions.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshOfferings() async {
    try {
      final offerings = await _service.fetchOfferings();
      _currentOffering = offerings.current;
      _packages = offerings.current?.availablePackages ?? [];
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to load subscription plans.';
      notifyListeners();
    }
  }

  Future<void> refreshCustomerInfo() async {
    try {
      final info = await _service.fetchCustomerInfo();
      _isPremium = _service.isPremium(info);
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to refresh subscription status.';
      notifyListeners();
    }
  }

  Future<void> purchase(Package package) async {
    _setLoading(true);
    try {
      final info = await _service.purchasePackage(package);
      _isPremium = _service.isPremium(info);
      _errorMessage = null;
    } on PurchasesErrorCode catch (_) {
      _errorMessage = 'Purchase failed. Please try again.';
    } catch (error) {
      _errorMessage = 'Purchase failed. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> restorePurchases() async {
    _setLoading(true);
    try {
      final info = await _service.restorePurchases();
      _isPremium = _service.isPremium(info);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Restore failed. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
