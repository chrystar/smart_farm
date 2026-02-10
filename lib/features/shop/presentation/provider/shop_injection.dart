import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/payment_service.dart';
import '../../data/shop_service.dart';
import 'shop_provider.dart';

class ShopInjection {
  static final _supabaseService = SupabaseService();
  static final _shopService = ShopService(_supabaseService);
  static final _paymentService = PaymentService();

  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) => ShopProvider(
        shopService: _shopService,
        paymentService: _paymentService,
        supabaseService: _supabaseService,
      ),
    ),
  ];
}
