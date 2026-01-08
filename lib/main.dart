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
import 'package:project_flutter_khmer25/providers/order_provider.dart';

import 'package:project_flutter_khmer25/screens/home_screen.dart';
import 'package:project_flutter_khmer25/screens/category_screen.dart';
import 'package:project_flutter_khmer25/screens/order_history_screen.dart';
import 'package:project_flutter_khmer25/screens/profile_screen.dart';
import 'package:project_flutter_khmer25/screens/product_list_screen.dart';
import 'package:project_flutter_khmer25/screens/category_product_screen.dart';
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

        // ✅ ProductProvider (pagination) => NO fetchProducts() here
        ChangeNotifierProvider(create: (_) => ProductProvider()),

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
            final String? token = auth.access;

            if (auth.isLoggedIn && token != null && token.isNotEmpty) {
              Future.microtask(() => cart!.fetchCart(accessToken: token));
            } else {
              cart!.clear();
            }
            return cart!;
          },
        ),

        // ✅ OrderProvider depends on auth token
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, orderProv) {
            orderProv ??= OrderProvider();
            final String? token = auth.access;

            if (auth.isLoggedIn && token != null && token.isNotEmpty) {
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
    const seed = Color(0xff2563EB);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khmer25',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: seed,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, primary: seed),
        fontFamily: 'Khmer',
        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black12,
          scrolledUnderElevation: 2,
          iconTheme: IconThemeData(color: Colors.black),
        ),
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
    final primary = Theme.of(context).primaryColor;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.86)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 46,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Khmer25 Mart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    title: 'ទំព័រដើម',
                    selected: _selectedIndex == tabHome,
                    onTap: () => _setTab(tabHome),
                  ),
                  _DrawerItem(
                    icon: Icons.category_outlined,
                    title: 'ប្រភេទ',
                    selected: _selectedIndex == tabCategory,
                    onTap: () => _setTab(tabCategory),
                  ),
                  _DrawerItem(
                    icon: Icons.history_outlined,
                    title: 'ប្រវត្តិការកម្មង់',
                    selected: _selectedIndex == tabHistory,
                    onTap: () => _setTab(tabHistory),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    title: 'គណនី',
                    selected: _selectedIndex == tabProfile,
                    onTap: () => _setTab(tabProfile),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const _DrawerSectionTitle(text: "ផលិតផល"),
                  const SizedBox(height: 8),
                  _DrawerItem(
                    icon: Icons.fiber_new_outlined,
                    title: 'ទំនិញថ្មីៗ',
                    selected: _selectedIndex == tabNewProducts,
                    onTap: () => _setTab(tabNewProducts),
                  ),
                  _DrawerItem(
                    icon: Icons.discount_outlined,
                    title: 'ទំនិញបញ្ចុះតម្លៃ',
                    selected: _selectedIndex == tabDiscountProducts,
                    onTap: () => _setTab(tabDiscountProducts),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.black.withOpacity(0.06)),
      ),
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

    // ✅ safety guard (avoid range error)
    if (_selectedIndex < 0 || _selectedIndex >= screens.length) {
      _selectedIndex = tabHome;
    }

    final bool isCategoryProducts = _selectedIndex == tabCategoryProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(showBack: isCategoryProducts),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: (_selectedIndex > 3) ? 0 : _selectedIndex,
        onTap: (index) => _setTab(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 6,
        selectedItemColor: const Color(0xff2563EB),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
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

/// ✅ Drawer item that looks like a “button”
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bg = selected
        ? primary.withOpacity(0.12)
        : Colors.grey.withOpacity(0.06);
    final border = selected
        ? primary.withOpacity(0.22)
        : Colors.grey.withOpacity(0.10);
    final iconColor = selected ? primary : Colors.grey.shade800;
    final textColor = selected ? Colors.black : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? primary.withOpacity(0.14) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  final String text;
  const _DrawerSectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: Colors.black.withOpacity(0.55),
      ),
    );
  }
}

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
