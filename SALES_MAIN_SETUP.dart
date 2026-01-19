// // Add this to your main.dart imports at the top:

// import 'package:smart_farm/features/sales/domain/usecases/sales_usecases.dart';
// import 'package:smart_farm/features/sales/data/datasources/sales_remote_datasource.dart';
// import 'package:smart_farm/features/sales/data/repository/sales_repository_impl.dart';
// import 'package:smart_farm/features/sales/presentation/provider/sales_provider.dart';

// // Then in your MultiProvider setup (usually in main() function):

// // Initialize Sales dependencies
// final supabaseClient = Supabase.instance.client;
// final salesRemoteDataSource = SalesRemoteDataSource(supabaseClient);
// final salesRepository = SalesRepositoryImpl(salesRemoteDataSource);

// // Add this to your MultiProvider list:
// ChangeNotifierProvider(
//   create: (_) => SalesProvider(
//     recordSaleUseCase: RecordSaleUseCase(salesRepository),
//     getSalesUseCase: GetSalesUseCase(salesRepository),
//     getBatchSalesUseCase: GetBatchSalesUseCase(salesRepository),
//     updatePaymentStatusUseCase: UpdatePaymentStatusUseCase(salesRepository),
//     deleteSaleUseCase: DeleteSaleUseCase(salesRepository),
//     createSaleGroupUseCase: CreateSaleGroupUseCase(salesRepository),
//   ),
// ),

// // Example of full MultiProvider:
// /*
// return MultiProvider(
//   providers: [
//     // ... existing providers ...
    
//     // Sales Module
//     ChangeNotifierProvider(
//       create: (_) => SalesProvider(
//         recordSaleUseCase: RecordSaleUseCase(salesRepository),
//         getSalesUseCase: GetSalesUseCase(salesRepository),
//         getBatchSalesUseCase: GetBatchSalesUseCase(salesRepository),
//         updatePaymentStatusUseCase: UpdatePaymentStatusUseCase(salesRepository),
//         deleteSaleUseCase: DeleteSaleUseCase(salesRepository),
//         createSaleGroupUseCase: CreateSaleGroupUseCase(salesRepository),
//       ),
//     ),
    
//     // ... other providers ...
//   ],
//   child: MaterialApp(
//     // your app config
//   ),
// );
// */

// // To use SalesListScreen in your navigation:
// import 'package:smart_farm/features/sales/presentation/pages/sales_list_screen.dart';

// // Then add to your navigation (e.g., bottom nav or menu):
// /*
// onTap: () => Navigator.push(
//   context,
//   MaterialPageRoute(builder: (_) => const SalesListScreen()),
// ),
// */
