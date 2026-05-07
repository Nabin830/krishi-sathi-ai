import 'package:flutter/material.dart';

import 'app_language.dart';
import 'backend_config.dart';

class BackendStatusScreen extends StatelessWidget {
  const BackendStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = BackendConfig.isBackendConnected;
    final baseUrl = BackendConfig.baseUrl;
    final endpoint = BackendConfig.scanPlantEndpoint;

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Backend Status', 'ब्याकएन्ड स्थिति'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 18),

                _statusBox(
                  icon: isConnected ? Icons.check_circle : Icons.warning_amber,
                  title: AppLanguage.text('Connection Status', 'जडान स्थिति'),
                  text: isConnected
                      ? AppLanguage.text(
                          'Backend URL is added.',
                          'ब्याकएन्ड URL थपिएको छ।',
                        )
                      : AppLanguage.text(
                          'Backend URL is not added yet.',
                          'ब्याकएन्ड URL अझै थपिएको छैन।',
                        ),
                  color: isConnected ? Colors.green : Colors.orange,
                ),

                const SizedBox(height: 12),

                _statusBox(
                  icon: Icons.link,
                  title: AppLanguage.text('Base URL', 'मुख्य URL'),
                  text: baseUrl.trim().isEmpty
                      ? AppLanguage.text('Empty for now', 'अहिले खाली छ')
                      : baseUrl,
                  color: Colors.blue,
                ),

                const SizedBox(height: 12),

                _statusBox(
                  icon: Icons.api,
                  title: AppLanguage.text('Scan Endpoint', 'स्क्यान Endpoint'),
                  text: endpoint.trim().isEmpty
                      ? AppLanguage.text('Empty for now', 'अहिले खाली छ')
                      : endpoint,
                  color: Colors.purple,
                ),

                const SizedBox(height: 18),

                _infoCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard() {
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
            child: Icon(Icons.cloud_sync, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLanguage.text('Backend AI Connection', 'ब्याकएन्ड एआई जडान'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.green.shade700),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              AppLanguage.text(
                'Later, when you build the backend, update only backend_config.dart. Then this page will show connected status.',
                'पछि ब्याकएन्ड बनाइसकेपछि backend_config.dart मात्र अपडेट गर्नुहोस्। त्यसपछि यो पेजमा connected स्थिति देखिनेछ।',
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBox({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
