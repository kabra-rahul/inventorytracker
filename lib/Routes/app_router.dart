//app_router.dart
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventorytracker/Functionality/Payment/Page/payment_page.dart';
import 'package:inventorytracker/Model/app_store_model.dart';
import 'package:inventorytracker/Provider/app_store_provider.dart';
import 'package:inventorytracker/Provider/auth_provider.dart';
import 'package:inventorytracker/Utils/go_router_refresh_stream.dart';
import 'package:inventorytracker/Provider/user_session_data_provider.dart';
import 'package:inventorytracker/Shared/Constants/role_constants.dart';

import 'package:inventorytracker/Functionality/Loading/Page/loading_page.dart';
import 'package:inventorytracker/Functionality/Splash/splash_page.dart';
import 'package:inventorytracker/Functionality/Login/Page/login_page.dart';
import 'package:inventorytracker/Functionality/Signup/Page/sign_up_page.dart';
import 'package:inventorytracker/Functionality/ForgotPassword/Page/forgot_password_page.dart';

import 'package:inventorytracker/Functionality/Category/Page/category_list_page.dart';
import 'package:inventorytracker/Functionality/Category/Page/category_edit_page.dart';
import 'package:inventorytracker/Functionality/Client/Page/client_list_page.dart';
import 'package:inventorytracker/Functionality/Client/Page/client_edit_page.dart';
import 'package:inventorytracker/Functionality/HSN/Page/hsn_list_page.dart';
import 'package:inventorytracker/Functionality/Hsn/Page/hsn_edit_page.dart';
import 'package:inventorytracker/Functionality/Product/Page/product_list_page.dart';
import 'package:inventorytracker/Functionality/Product/Page/product_edit_page.dart';
import 'package:inventorytracker/Functionality/Supplier/Page/supplier_list_page.dart';
import 'package:inventorytracker/Functionality/Supplier/Page/supplier_edit_page.dart';
import 'package:inventorytracker/Functionality/Stock/Page/stock_list_page.dart';
import 'package:inventorytracker/Functionality/Stock/Page/stock_details_page.dart';
import 'package:inventorytracker/Functionality/Units/Page/unit_list_page.dart';
import 'package:inventorytracker/Functionality/Units/Page/unit_edit_page.dart';
import 'package:inventorytracker/Functionality/User/Page/user_list_page.dart';
import 'package:inventorytracker/Functionality/User/Page/user_edit_page.dart';
import 'package:inventorytracker/Functionality/Warehouse/Page/warehouse_list_page.dart';
import 'package:inventorytracker/Functionality/Warehouse/Page/warehouse_edit_page.dart';
import 'package:inventorytracker/Functionality/ContactUs/Page/contact_me_page.dart';
import 'package:inventorytracker/Functionality/Dashboard/Page/dashboard_page.dart';
import 'package:inventorytracker/Functionality/Settings/Page/settings_page.dart';
import 'package:inventorytracker/Functionality/StockMovement/Page/inward_stock_page.dart';
import 'package:inventorytracker/Functionality/StockMovement/Page/outward_stock_page.dart';
import 'package:inventorytracker/Functionality/Transaction/Page/transaction_list_page.dart';

import 'package:inventorytracker/Functionality/Report/Page/reports_page.dart';
import 'package:inventorytracker/Functionality/Report/Page/batch_summary_report.dart';
import 'package:inventorytracker/Functionality/Report/Page/client_summary_report.dart';
import 'package:inventorytracker/Functionality/Report/Page/stock_summary_report_page.dart';
import 'package:inventorytracker/Functionality/Report/Page/supplier_summary_report.dart';
import 'package:inventorytracker/Functionality/Report/Page/transaction_report_page.dart';
import 'package:inventorytracker/Functionality/Report/Page/undo_transaction_report_page.dart';

import '../Shared/globals.dart' as globals;



class AppRoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/home';
  static const String loading = '/loading';
  static const String warehouseList = '/warehouses';
  static const String warehouseEdit = '/warehouse-edit';
  static const String productList = '/products';
  static const String productEdit = '/product-edit';
  static const String categoryList = '/categories';
  static const String categoryEdit = '/category-edit';
  static const String hsnList = '/hsn-codes';
  static const String hsnEdit = '/hsn-code-edit';
  static const String unitList = '/units';
  static const String unitEdit = '/unit-edit';
  static const String supplierList = '/suppliers';
  static const String supplierEdit = '/supplier-edit';
  static const String clientList = '/clients';
  static const String clientEdit = '/client-edit';
  static const String userList = '/users';
  static const String userEdit = '/user-edit';
  static const String stockList = '/stock-list';
  static const String stockDetail = '/stock-details';
  static const String payment = '/payment';
  static const String settings = '/settings';
  static const String inwardMovement = '/inward-movement';
  static const String outwardMovement = '/outward-movement';
  static const String transaction = '/transactions';
  static const String contactUs = '/contact-us';
  static const String unauthorized = '/unauthorized';
  static const String reportList = '/reports';
  static const String stockSummaryReport    = '/stock-summary-report';
  static const String batchSummaryReport    = '/batch-summary-report';
  static const String clientSummaryReport   = '/client-summary-report';
  static const String supplierSummaryReport = '/supplier-summary-report';
  static const String transactionReport     = '/transaction-report';
  static const String undoTransactionReport = '/undo-transaction-report';
}


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userSessionDataAsync = ref.watch(userSessionDataProvider);

  final AppStore? userSessionData = userSessionDataAsync.when(
    data: (userData) => userData,
    loading: () => null,
    error: (e, _) => null,
  );

  return GoRouter(
    initialLocation: AppRoutePaths.splash,

    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

    redirect: (context, state) {
      final bool isGoingToLogin = state.matchedLocation == AppRoutePaths.login;
      final bool isGoingToSignup = state.matchedLocation == AppRoutePaths.signup;
      final bool isGoingToForgotPassword = state.matchedLocation == AppRoutePaths.forgotPassword;
      final bool isGoingToSplash = state.matchedLocation == AppRoutePaths.splash;
      final bool isGoingToLoading = state.matchedLocation == AppRoutePaths.loading;

      final user = authState.value; // User from Firebase Auth
      final bool isLoggedIn = user != null;
//      final AppStore? loadedAppStore = userSessionDataAsync.value;

      if (!isLoggedIn) {
        // If not logged in, redirect to login/signup/forgot password unless already there
        return (isGoingToLogin || isGoingToSignup || isGoingToForgotPassword || isGoingToSplash) ? null : AppRoutePaths.login;
      }

      if (userSessionDataAsync.isLoading) {
        // If AppStore data is still loading, redirect to loading page
        return isGoingToLoading ? null : AppRoutePaths.loading;
      }

      /*
      if (userSessionDataAsync.hasError) {
        return isGoingToLogin ? null : AppRoutePaths.login; // Fallback to login
      }*/

      //final AppStore? loadedAppStore = userSessionData.;

      if (userSessionData == null || userSessionData.companyId.isEmpty) {
        return AppRoutePaths.login;
      }

      if (isGoingToLogin || isGoingToSignup || isGoingToSplash || isGoingToLoading || isGoingToForgotPassword) {
        return AppRoutePaths.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutePaths.splash,         builder: (context, state) => SplashPage()),
      GoRoute(path: AppRoutePaths.login,          builder: (context, state) => LoginPage()),
      GoRoute(path: AppRoutePaths.signup,         builder: (context, state) => SignupPage()),
      GoRoute(path: AppRoutePaths.forgotPassword, builder: (context, state) => ForgotPasswordPage()),
      GoRoute(path: AppRoutePaths.loading,        builder: (context, state) => LoadingPage()),
      GoRoute(path: AppRoutePaths.productList,    builder: (context, state) => ProductListPage()),
      GoRoute(path: AppRoutePaths.productEdit,    builder: (context, state) => ProductEditPage()),
      GoRoute(path: AppRoutePaths.categoryList,   builder: (context, state) => CategoryListPage()),
      GoRoute(path: AppRoutePaths.categoryEdit,   builder: (context, state) => CategoryEditPage()),
      GoRoute(path: AppRoutePaths.hsnList,        builder: (context, state) => HsnListPage()),
      GoRoute(path: AppRoutePaths.hsnEdit,        builder: (context, state) => HsnEditPage()),
      GoRoute(path: AppRoutePaths.unitList,       builder: (context, state) => UnitListPage()),
      GoRoute(path: AppRoutePaths.unitEdit,       builder: (context, state) => UnitEditPage()),
      GoRoute(path: AppRoutePaths.settings,       builder: (context, state) => SettingsPage()),
      GoRoute(path: AppRoutePaths.contactUs,      builder: (context, state) => ContactMePage()),
      GoRoute(path: AppRoutePaths.reportList,     builder: (context, state) => ReportsPage()),

      GoRoute(path: AppRoutePaths.clientList,     builder: (context, state) => ClientListPage()),

      GoRoute(
        path: AppRoutePaths.clientEdit,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => ClientEditPage(),
      ),

      GoRoute(path: AppRoutePaths.supplierList,   builder: (context, state) => SupplierListPage()),

      GoRoute(
        path: AppRoutePaths.supplierEdit,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => SupplierEditPage(),
      ),

      GoRoute(path: AppRoutePaths.warehouseList,  builder: (context, state) => WarehouseListPage()),

      GoRoute(
        path: AppRoutePaths.warehouseEdit,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => WarehouseEditPage(),
      ),

      GoRoute(
        path: AppRoutePaths.userList,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => UserListPage(),
      ),

      GoRoute(
        path: AppRoutePaths.userEdit,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => UserEditPage(),
      ),

      GoRoute(
        path: AppRoutePaths.payment,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => PaymentPage(),
      ),

      GoRoute(
        path: AppRoutePaths.stockList,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return StockListPage(
            warehouseId: extra['warehouseId'],
            productIds: extra['productIds'],
            mode: extra['mode'],
          );
        },
      ),

      GoRoute(
        path: AppRoutePaths.stockDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return StockDetailsPage(extra: extra);
        },
      ),

      GoRoute(
        path: AppRoutePaths.inwardMovement,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final DateTime? expiryDate = app?.planExpiry;

          if (expiryDate != null) {
            if(expiryDate.add(const Duration(days: 7)).isBefore(DateTime.now())){
              return '${AppRoutePaths.dashboard}?expired=true';
            }
          }
          return null;
        },
        builder: (context, state) {
          final app = ref.read(appStoreProvider).asData?.value;
          final extra = state.extra as Map<String, dynamic>;

          return InwardStockPage(
              companyId: app?.companyId ?? '',
              warehouseId: (extra['warehouseId'] as String?) ?? ''
          );
        },
      ),

      GoRoute(
        path: AppRoutePaths.outwardMovement,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final DateTime? expiryDate = app?.planExpiry;

          if (expiryDate != null) {
            if(expiryDate.add(const Duration(days: 7)).isBefore(DateTime.now())){
              return '${AppRoutePaths.dashboard}?expired=true';
            }
          }
          return null;
        },
        builder: (context, state) {
          final app = ref.read(appStoreProvider).asData?.value;
          final extra = state.extra as Map<String, dynamic>;
          return OutwardStockPage(
            companyId: app?.companyId ?? '',
            warehouseId: (extra['warehouseId'] as String?) ?? ''
          );
        },
      ),

      GoRoute(
          path: AppRoutePaths.dashboard,
        redirect: (context, state) {
          if (globals.initialExpiryCheckDone) {
              return null;
          } else {
            final app = ref.read(appStoreDataProvider);
            final DateTime? expiry = app?.planExpiry;
            final now = DateTime.now();

            if (expiry != null) {
              if (expiry.add(const Duration(days: 7)).isBefore(now)) {
                // Return the string path instead of context.go()
                return '${AppRoutePaths.dashboard}?expired=true';
              } else if (expiry.isBefore(now)) {
                return '${AppRoutePaths.dashboard}?grace_period=true';
              } else if (expiry.subtract(const Duration(days: 7)).isBefore(now)) {
                return '${AppRoutePaths.dashboard}?expiry_reminder=true';
              }
            }
          }
          // Mark it as done
          return null;
        },
          builder: (context, state) {
            return DashboardPage();
          },
      ),

      GoRoute(
        path: AppRoutePaths.transaction,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TransactionPage(warehouseId: extra['warehouseId']);
        },
      ),

      GoRoute(
        path: AppRoutePaths.stockSummaryReport,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => StockSummaryReportPage(),
      ),

      GoRoute(
        path: AppRoutePaths.batchSummaryReport,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => BatchDetailsReportPage(),
      ),

      GoRoute(
        path: AppRoutePaths.clientSummaryReport,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => ClientBuyReportPage(),
      ),

      GoRoute(
        path: AppRoutePaths.supplierSummaryReport,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => SupplierSellReportPage(),
      ),

      GoRoute(
        path: AppRoutePaths.transactionReport,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => TransactionReportPage(),
      ),

      GoRoute(
        path: AppRoutePaths.undoTransactionReport,
        redirect: (context, state) {
          final app = ref.read(appStoreDataProvider);
          final String? role = app?.role;
          if (role != RoleConstants.adminRole) {
            return AppRoutePaths.dashboard;
          }
          return null;
        },
        builder: (context, state) => UndoneTransactionReportPage(),
      )
    ],
  );
});