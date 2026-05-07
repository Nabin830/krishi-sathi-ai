import 'package:flutter/material.dart';

import 'app_language.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _locationController = TextEditingController();

  String _selectedLocation = 'Chitwan';
  String _weatherMessageEn =
      'Weather API will be connected later. For now this page is ready for design and testing.';
  String _weatherMessageNe =
      'मौसम API पछि जोडिनेछ। अहिले यो पेज डिजाइन र परीक्षणका लागि तयार छ।';

  void _checkWeather() {
    final location = _locationController.text.trim();

    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              'Please enter your district or city',
              'कृपया जिल्ला वा शहर लेख्नुहोस्',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = location;
      _weatherMessageEn =
          'Weather alert for $location will appear here after API connection.';
      _weatherMessageNe = '$location को मौसम अलर्ट API जोडिएपछि यहाँ देखिनेछ।';
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Weather Alerts', 'मौसम अलर्ट'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 18),
                _searchCard(),
                const SizedBox(height: 18),
                _weatherCard(),
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
            child: Icon(Icons.cloud, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('Farming Weather Alerts', 'खेती मौसम अलर्ट'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLanguage.text(
                    'Check farming weather updates by district or city.',
                    'जिल्ला वा शहर अनुसार खेती मौसम अपडेट हेर्नुहोस्।',
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: AppLanguage.text('District / City', 'जिल्ला / शहर'),
              hintText: AppLanguage.text(
                'Example: Chitwan, Pokhara, Kathmandu',
                'उदाहरण: चितवन, पोखरा, काठमाडौं',
              ),
              prefixIcon: Icon(Icons.location_on, color: Colors.green.shade700),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkWeather,
              icon: const Icon(Icons.cloud),
              label: Text(
                AppLanguage.text('Check Weather', 'मौसम जाँच गर्नुहोस्'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedLocation,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.wb_sunny, size: 48, color: Colors.orange.shade600),
              const SizedBox(width: 14),
              const Text(
                '--°C',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.isNepali ? _weatherMessageNe : _weatherMessageEn,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            AppLanguage.text('Future smart alerts', 'भविष्यका स्मार्ट अलर्ट'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _alertItem(AppLanguage.text('Rain warning', 'वर्षा चेतावनी')),
          _alertItem(
            AppLanguage.text('High temperature warning', 'धेरै गर्मी चेतावनी'),
          ),
          _alertItem(
            AppLanguage.text(
              'Crop disease weather risk',
              'मौसमका कारण बाली रोग जोखिम',
            ),
          ),
          _alertItem(AppLanguage.text('Irrigation reminder', 'सिँचाइ सम्झना')),
        ],
      ),
    );
  }

  Widget _alertItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
