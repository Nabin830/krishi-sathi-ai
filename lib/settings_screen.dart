import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_language.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'No email';

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Settings', 'सेटिङ्स'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(email),
                const SizedBox(height: 18),

                _settingsTile(
                  icon: Icons.language,
                  title: AppLanguage.text('Language', 'भाषा'),
                  subtitle: AppLanguage.isNepali ? 'नेपाली' : 'English',
                  trailing: ElevatedButton(
                    onPressed: AppLanguage.toggleLanguage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLanguage.text('Change', 'बदल्नुहोस्')),
                  ),
                ),

                _settingsTile(
                  icon: Icons.info_outline,
                  title: AppLanguage.text('About App', 'एपको बारेमा'),
                  subtitle: AppLanguage.text(
                    'Krishi Sathi AI helps farmers check plant problems and manage crop selling.',
                    'कृषि साथी एआईले किसानलाई बिरुवा समस्या जाँच गर्न र बाली बेच्न सहयोग गर्छ।',
                  ),
                ),

                _settingsTile(
                  icon: Icons.verified_user,
                  title: AppLanguage.text('Account Type', 'खाता प्रकार'),
                  subtitle: AppLanguage.text(
                    'Farmer / Admin based on your role',
                    'तपाईंको भूमिकाको आधारमा किसान / एडमिन',
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      AppLanguage.text('Logout', 'लगआउट'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard(String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.settings, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('App Settings', 'एप सेटिङ्स'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
