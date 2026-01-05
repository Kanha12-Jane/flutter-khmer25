import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_flutter_khmer25/models/category_model.dart';

import 'package:project_flutter_khmer25/providers/auth_provider.dart';
import 'package:project_flutter_khmer25/providers/profile_provider.dart';
import 'package:project_flutter_khmer25/providers/banner_provider.dart';
import 'package:project_flutter_khmer25/providers/category_provider.dart';
import 'package:project_flutter_khmer25/providers/product_provider.dart';
import 'package:project_flutter_khmer25/providers/category_product_provider.dart';
import 'package:project_flutter_khmer25/providers/cart_provider.dart';
import 'package:project_flutter_khmer25/providers/order_provider.dart'; // ✅ NEW

import 'package:project_flutter_khmer25/screens/home_screen.dart';
import 'package:project_flutter_khmer25/screens/category_screen.dart';
import 'package:project_flutter_khmer25/screens/order_history_screen.dart';
import 'package:project_flutter_khmer25/screens/profile_screen.dart';
import 'package:project_flutter_khmer25/screens/product_list_screen.dart';
import 'package:project_flutter_khmer25/screens/category_product_screen.dart';

import 'package:project_flutter_khmer25/screens/favorite_screen.dart';
import 'package:project_flutter_khmer25/screens/cart_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()..loadBanners()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..fetchProducts(),
        ),

        // ✅ Auth
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadFromStorageAndMe(),
        ),

        ChangeNotifierProvider(create: (_) => CategoryProductProvider()),

        // ✅ Cart depends on auth token
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            cart ??= CartProvider();
            final String? token = auth.access; // must match AuthProvider
            if (auth.isLoggedIn && token != null && token.isNotEmpty) {
              Future.microtask(() => cart!.fetchCart(accessToken: token));
            } else {
              cart!.clear();
            }
            return cart!;
          },
        ),

        // ✅ NEW: OrderProvider depends on auth token (same style)
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, orderProv) {
            orderProv ??= OrderProvider();
            final String? token = auth.access;

            if (auth.isLoggedIn && token != null && token.isNotEmpty) {
              // Optional: auto load orders when login
              Future.microtask(
                () => orderProv!.fetchMyOrders(accessToken: token),
              );
            } else {
              orderProv!.clear();
            }
            return orderProv!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khmer25',
      theme: ThemeData(
        primaryColor: const Color(0xff2ecc71),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2ecc71)),
        fontFamily: 'Khmer',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  CategoryModel? _openCategory;

  // tabs
  static const int tabHome = 0;
  static const int tabCategory = 1;
  static const int tabHistory = 2;
  static const int tabProfile = 3;
  static const int tabNewProducts = 4;
  static const int tabDiscountProducts = 5;
  static const int tabCategoryProducts = 6;

  void _setTab(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop(); // close drawer if open
  }

  void _openCategoryProducts(CategoryModel cat) {
    setState(() {
      _openCategory = cat;
      _selectedIndex = tabCategoryProducts;
    });
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Khmer25 Mart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'សូមស្វាគមន៍មកកាន់ការទិញទំនិញ ក្នុងសម័យទំនើប',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // 👉 Drawer items
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('ទំព័រដើម'),
            selected: _selectedIndex == tabHome,
            selectedColor: Theme.of(context).primaryColor,
            onTap: () => _setTab(tabHome),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('ប្រភេទ'),
            selected: _selectedIndex == tabCategory,
            selectedColor: Theme.of(context).primaryColor,
            onTap: () => _setTab(tabCategory),
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('ប្រវត្តិការកម្មង់'),
            selected: _selectedIndex == tabHistory,
            selectedColor: Theme.of(context).primaryColor,
            onTap: () => _setTab(tabHistory),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('គណនី'),
            selected: _selectedIndex == tabProfile,
            selectedColor: Theme.of(context).primaryColor,
            onTap: () => _setTab(tabProfile),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fiber_new_outlined),
            title: const Text('ទំនិញថ្មីៗ'),
            selected: _selectedIndex == tabNewProducts,
            selectedColor: Theme.of(context).primaryColor,
            onTap: () => _setTab(tabNewProducts),
          ),
          ListTile(
            leading: const Icon(Icons.discount_outlined),
            title: const Text('ទំនិញបញ្ចុះតម្លៃ'),
            selected: _selectedIndex == tabDiscountProducts,
            selectedColor: Theme.of(context).primaryColor,
            onTap: () => _setTab(tabDiscountProducts),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar({required bool showBack}) {
    final cartQty = context.watch<CartProvider>().totalQty;

    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _setTab(tabHome),
            )
          : null,
      title: Row(
        children: [
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ],
      ),
      actions: [
        // IconButton(
        //   onPressed: () => Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (_) => const FavoriteScreen()),
        //   ),
        //   icon: const Icon(Icons.favorite_border),
        // ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          icon: _CartBadgeIcon(qty: cartQty),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        onOpenCategory: (cat) => _openCategoryProducts(cat),
        onOpenNew: () => _setTab(tabNewProducts),
        onOpenDiscount: () => _setTab(tabDiscountProducts),
      ),
      CategoryScreen(onOpenCategory: (cat) => _openCategoryProducts(cat)),
      const OrderHistoryScreen(),
      const ProfileTab(),
      ProductListScreen(
        type: ProductFilterType.newProducts,
        onBack: () => _setTab(tabHome),
      ),
      ProductListScreen(
        type: ProductFilterType.discountProducts,
        onBack: () => _setTab(tabHome),
      ),
      (_openCategory == null)
          ? const Center(child: Text("No category selected"))
          : CategoryProductScreen(initialParent: _openCategory!),
    ];

    final bool isCategoryProducts = _selectedIndex == tabCategoryProducts;

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: _buildAppBar(showBack: isCategoryProducts),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: (_selectedIndex > 3) ? 0 : _selectedIndex,
        onTap: (index) => _setTab(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff2ecc71),
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ទំព័រដើម',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'ប្រភេទ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'ប្រវត្តិការកម្មង់',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'គណនី',
          ),
        ],
      ),
    );
  }
}

// ✅ Badge widget
class _CartBadgeIcon extends StatelessWidget {
  final int qty;
  const _CartBadgeIcon({required this.qty});

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) return const Icon(Icons.shopping_cart_outlined);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart_outlined),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "$qty",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
