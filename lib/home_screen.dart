import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';
import 'settings_screen.dart';
import 'crop_disease_screen.dart';
import 'weather_advice_screen.dart';
import 'weather_ai_history_screen.dart';
import 'market_price_screen.dart';
import 'market_price_history_screen.dart';
import 'profile_screen.dart';
import 'sell_crop_screen.dart';
import 'buyer_market_screen.dart';
import 'my_listings_screen.dart';
import 'my_crop_reports_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_listings_screen.dart';
import 'backend_status_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _unreadNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  bool _isAdminFromSnapshot(
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> roleSnapshot,
  ) {
    if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
      return false;
    }

    final data = roleSnapshot.data!.data();
    final role = (data?['role'] ?? 'farmer').toString().toLowerCase().trim();

    return role == 'admin';
  }

  String _firstNameFromSnapshot({
    required User? user,
    required AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> roleSnapshot,
  }) {
    String firstName = '';

    if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
      final data = roleSnapshot.data!.data();

      final fullName =
          (data?['firstName'] ??
                  data?['name'] ??
                  data?['fullName'] ??
                  data?['displayName'] ??
                  data?['farmerName'] ??
                  '')
              .toString()
              .trim();

      if (fullName.isNotEmpty) {
        firstName = fullName.split(' ').first;
      }
    }

    if (firstName.isEmpty && user?.displayName != null) {
      final displayName = user!.displayName!.trim();

      if (displayName.isNotEmpty) {
        firstName = displayName.split(' ').first;
      }
    }

    if (firstName.isEmpty && user?.email != null) {
      firstName = user!.email!.split('@').first;
    }

    if (firstName.trim().isEmpty) {
      firstName = 'Farmer';
    }

    return firstName.trim();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Farmer';

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Krishi Sathi AI', 'कृषि साथी एआई'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: AppLanguage.toggleLanguage,
                icon: const Icon(Icons.language),
                tooltip: 'Change Language',
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _getUserRole(),
              builder: (context, roleSnapshot) {
                final isAdmin = _isAdminFromSnapshot(roleSnapshot);
                final firstName = _firstNameFromSnapshot(
                  user: user,
                  roleSnapshot: roleSnapshot,
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _heroCard(
                      email: email,
                      firstName: firstName,
                      isAdmin: isAdmin,
                    ),

                    if (roleSnapshot.connectionState ==
                        ConnectionState.waiting) ...[
                      const SizedBox(height: 14),
                      const Center(child: CircularProgressIndicator()),
                    ],

                    const SizedBox(height: 22),

                    _sectionTitle(
                      icon: Icons.health_and_safety,
                      title: AppLanguage.text('Crop Health', 'बाली स्वास्थ्य'),
                    ),
                    const SizedBox(height: 12),
                    _serviceGrid(
                      children: [
                        _dashboardCard(
                          context: context,
                          icon: Icons.camera_alt,
                          title: AppLanguage.text('Crop Check', 'बाली जाँच'),
                          subtitle: AppLanguage.text(
                            'Scan disease',
                            'रोग स्क्यान',
                          ),
                          onTap: () =>
                              _openPage(context, const CropDiseaseScreen()),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.assignment,
                          title: AppLanguage.text('My Reports', 'मेरो रिपोर्ट'),
                          subtitle: AppLanguage.text(
                            'Track reviews',
                            'समीक्षा हेर्नुहोस्',
                          ),
                          onTap: () =>
                              _openPage(context, const MyCropReportsScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      icon: Icons.cloud,
                      title: AppLanguage.text('Weather Support', 'मौसम सहयोग'),
                    ),
                    const SizedBox(height: 12),
                    _serviceGrid(
                      children: [
                        _dashboardCard(
                          context: context,
                          icon: Icons.cloud,
                          title: AppLanguage.text('Weather', 'मौसम'),
                          subtitle: AppLanguage.text(
                            'Farm alerts',
                            'खेती अलर्ट',
                          ),
                          onTap: () =>
                              _openPage(context, const WeatherAdviceScreen()),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.auto_awesome,
                          title: AppLanguage.text(
                            'Weather History',
                            'मौसम इतिहास',
                          ),
                          subtitle: AppLanguage.text(
                            'Saved advice',
                            'सेभ सुझाव',
                          ),
                          onTap: () => _openPage(
                            context,
                            const WeatherAiHistoryScreen(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      icon: Icons.storefront,
                      title: AppLanguage.text(
                        'Market & Selling',
                        'बजार र बिक्री',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _serviceGrid(
                      children: [
                        _dashboardCard(
                          context: context,
                          icon: Icons.store,
                          title: AppLanguage.text(
                            'Latest Prices',
                            'पछिल्लो मूल्य',
                          ),
                          subtitle: AppLanguage.text(
                            'Add today’s rate',
                            'आजको मूल्य थप्नुहोस्',
                          ),
                          onTap: () =>
                              _openPage(context, const MarketPriceScreen()),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.history,
                          title: AppLanguage.text(
                            'Price History',
                            'मूल्य इतिहास',
                          ),
                          subtitle: AppLanguage.text(
                            'Past market rates',
                            'पुराना बजार मूल्य',
                          ),
                          onTap: () => _openPage(
                            context,
                            const MarketPriceHistoryScreen(),
                          ),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.shopping_bag,
                          title: AppLanguage.text(
                            'Sell Crops',
                            'बाली बेच्नुहोस्',
                          ),
                          subtitle: AppLanguage.text(
                            'Create listing',
                            'लिस्टिङ बनाउनुहोस्',
                          ),
                          onTap: () =>
                              _openPage(context, const SellCropScreen()),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.shopping_cart,
                          title: AppLanguage.text('Marketplace', 'बजार'),
                          subtitle: AppLanguage.text(
                            'Buy crops',
                            'बाली किन्नुहोस्',
                          ),
                          onTap: () =>
                              _openPage(context, const BuyerMarketScreen()),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.list_alt,
                          title: AppLanguage.text(
                            'My Listings',
                            'मेरो लिस्टिङ',
                          ),
                          subtitle: AppLanguage.text(
                            'Manage posts',
                            'पोस्ट व्यवस्थापन',
                          ),
                          onTap: () =>
                              _openPage(context, const MyListingsScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle(
                      icon: Icons.person,
                      title: AppLanguage.text('Account & App', 'खाता र एप'),
                    ),
                    const SizedBox(height: 12),
                    _serviceGrid(
                      children: [
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _unreadNotificationsStream(),
                          builder: (context, notificationSnapshot) {
                            final unreadCount =
                                notificationSnapshot.data?.docs.length ?? 0;

                            return _dashboardCard(
                              context: context,
                              icon: Icons.notifications,
                              badgeCount: unreadCount,
                              title: unreadCount > 0
                                  ? AppLanguage.text(
                                      'Notifications ($unreadCount)',
                                      'सूचनाहरू ($unreadCount)',
                                    )
                                  : AppLanguage.text(
                                      'Notifications',
                                      'सूचनाहरू',
                                    ),
                              subtitle: unreadCount > 0
                                  ? AppLanguage.text(
                                      '$unreadCount new update',
                                      '$unreadCount नयाँ अपडेट',
                                    )
                                  : AppLanguage.text(
                                      'App updates',
                                      'एप अपडेटहरू',
                                    ),
                              onTap: () => _openPage(
                                context,
                                const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.person,
                          title: AppLanguage.text('Profile', 'प्रोफाइल'),
                          subtitle: AppLanguage.text(
                            'Farm details',
                            'फार्म विवरण',
                          ),
                          onTap: () =>
                              _openPage(context, const ProfileScreen()),
                        ),
                        _dashboardCard(
                          context: context,
                          icon: Icons.settings,
                          title: AppLanguage.text('Settings', 'सेटिङ्स'),
                          subtitle: AppLanguage.text(
                            'Language & account',
                            'भाषा र खाता',
                          ),
                          onTap: () =>
                              _openPage(context, const SettingsScreen()),
                        ),
                      ],
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 24),
                      _sectionTitle(
                        icon: Icons.admin_panel_settings,
                        title: AppLanguage.text('Admin Panel', 'एडमिन प्यानल'),
                      ),
                      const SizedBox(height: 12),
                      _adminTile(
                        context: context,
                        icon: Icons.admin_panel_settings,
                        title: AppLanguage.text(
                          'Admin Reports',
                          'एडमिन रिपोर्ट',
                        ),
                        subtitle: AppLanguage.text(
                          'Review crop disease reports',
                          'बाली रोग रिपोर्ट समीक्षा गर्नुहोस्',
                        ),
                        onTap: () =>
                            _openPage(context, const AdminReportsScreen()),
                      ),
                      _adminTile(
                        context: context,
                        icon: Icons.manage_search,
                        title: AppLanguage.text(
                          'Admin Listings',
                          'एडमिन लिस्टिङ',
                        ),
                        subtitle: AppLanguage.text(
                          'Manage crop sale listings',
                          'बाली बिक्री लिस्टिङ व्यवस्थापन',
                        ),
                        onTap: () =>
                            _openPage(context, const AdminListingsScreen()),
                      ),
                      _adminTile(
                        context: context,
                        icon: Icons.cloud_sync,
                        title: AppLanguage.text('Backend', 'ब्याकएन्ड'),
                        subtitle: AppLanguage.text(
                          'Check AI connection',
                          'एआई जडान जाँच गर्नुहोस्',
                        ),
                        onTap: () =>
                            _openPage(context, const BackendStatusScreen()),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _heroCard({
    required String email,
    required String firstName,
    required bool isAdmin,
  }) {
    final greetingName = firstName.trim().isEmpty
        ? AppLanguage.text('Farmer', 'किसान')
        : firstName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdmin
              ? [Colors.orange.shade800, Colors.orange.shade400]
              : [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isAdmin ? Colors.orange : Colors.green).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.agriculture,
              size: 34,
              color: isAdmin ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin
                      ? AppLanguage.text('Namaste Admin 👋', 'नमस्ते एडमिन 👋')
                      : AppLanguage.text(
                          'Namaste $greetingName 👨‍🌾',
                          'नमस्ते $greetingName 👨‍🌾',
                        ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? AppLanguage.text(
                          'Manage reports, listings and backend',
                          'रिपोर्ट, लिस्टिङ र ब्याकएन्ड व्यवस्थापन गर्नुहोस्',
                        )
                      : AppLanguage.text(
                          'Smart farming support for Nepal',
                          'नेपालका किसानका लागि स्मार्ट खेती सहयोग',
                        ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green.shade800, size: 19),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _serviceGrid({required List<Widget> children}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: children,
    );
  }

  Widget _dashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: badgeCount > 0 ? Colors.green.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badgeCount > 0
                ? Colors.red.withOpacity(0.35)
                : Colors.green.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: Icon(icon, color: Colors.green.shade700),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _adminTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(icon, color: Colors.orange.shade800),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
