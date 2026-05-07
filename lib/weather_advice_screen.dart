import 'package:flutter/material.dart';
import 'weather_firestore_service.dart';
import 'app_language.dart';
import 'weather_service.dart';
import 'weather_ai_service.dart';

class WeatherAdviceScreen extends StatefulWidget {
  const WeatherAdviceScreen({super.key});

  @override
  State<WeatherAdviceScreen> createState() => _WeatherAdviceScreenState();
}

class _WeatherAdviceScreenState extends State<WeatherAdviceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customCropController = TextEditingController();

  bool _isSearching = false;
  bool _isLoadingWeather = false;
  bool _isLoadingAiSummary = false;

  String _errorMessage = '';
  String _aiErrorMessage = '';

  List<WeatherPlace> _searchResults = [];
  List<WeatherPlace> _savedPlaces = [];
  List<WeatherFarmProfile> _farmProfiles = [];
  List<WeatherAdviceHistory> _adviceHistory = [];

  WeatherPlace? _selectedPlace;
  WeatherResult? _weather;
  WeatherAiResult? _weatherAiResult;

  String _selectedCrop = 'Tomato';

  final List<Map<String, String>> _cropOptions = [
    {'en': 'Tomato', 'ne': 'टमाटर'},
    {'en': 'Rice', 'ne': 'धान'},
    {'en': 'Potato', 'ne': 'आलु'},
    {'en': 'Maize', 'ne': 'मकै'},
    {'en': 'Wheat', 'ne': 'गहुँ'},
    {'en': 'Vegetables', 'ne': 'तरकारी'},
    {'en': 'Other', 'ne': 'अन्य'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedWeather();
  }

  Future<void> _loadSavedWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _errorMessage = '';
      _aiErrorMessage = '';
      _weatherAiResult = null;
    });

    try {
      final savedPlaces = await WeatherService.getSavedPlaces();
      final profiles = await WeatherService.getFarmProfiles();
      final history = await WeatherService.getAdviceHistory();
      final selectedProfile = await WeatherService.getSelectedFarmProfile();
      final selectedPlace = await WeatherService.getSelectedPlace();

      setState(() {
        _savedPlaces = savedPlaces;
        _farmProfiles = profiles;
        _adviceHistory = history;
      });

      if (selectedProfile != null) {
        setState(() {
          _selectedCrop = _isCommonCrop(selectedProfile.cropEn)
              ? selectedProfile.cropEn
              : 'Other';

          if (_selectedCrop == 'Other') {
            _customCropController.text = selectedProfile.cropEn;
          }

          _selectedPlace = selectedProfile.place;
        });

        await _fetchWeatherForPlace(
          selectedProfile.place,
          savePlace: false,
          saveHistory: false,
        );
      } else if (selectedPlace != null) {
        setState(() {
          _selectedPlace = selectedPlace;
        });

        await _fetchWeatherForPlace(
          selectedPlace,
          savePlace: false,
          saveHistory: false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load saved weather: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  bool _isCommonCrop(String cropName) {
    return cropName == 'Tomato' ||
        cropName == 'Rice' ||
        cropName == 'Potato' ||
        cropName == 'Maize' ||
        cropName == 'Wheat' ||
        cropName == 'Vegetables';
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please type a city or place name',
          'कृपया शहर वा ठाउँको नाम लेख्नुहोस्',
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _aiErrorMessage = '';
      _searchResults = [];
      _weatherAiResult = null;
    });

    try {
      final results = await WeatherService.searchPlaces(query);

      setState(() {
        _searchResults = results;
      });

      if (results.isEmpty) {
        _showMessage(
          AppLanguage.text(
            'No place found. Try another name.',
            'ठाउँ भेटिएन। अर्को नाम प्रयास गर्नुहोस्।',
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _fetchWeatherForPlace(
    WeatherPlace place, {
    bool savePlace = true,
    bool saveHistory = true,
  }) async {
    setState(() {
      _isLoadingWeather = true;
      _errorMessage = '';
      _aiErrorMessage = '';
      _selectedPlace = place;
      _searchResults = [];
      _weatherAiResult = null;
    });

    try {
      final result = await WeatherService.fetchWeather(place);

      if (savePlace) {
        await WeatherService.savePlace(place);
      } else {
        await WeatherService.selectPlace(place);
      }

      final savedPlaces = await WeatherService.getSavedPlaces();

      setState(() {
        _weather = result;
        _savedPlaces = savedPlaces;
        _selectedPlace = place;
      });

      if (saveHistory) {
        await _saveAdviceHistorySnapshot();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Weather load failed: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _refreshCurrentWeather() async {
    final place = _selectedPlace;

    if (place == null) {
      _showMessage(
        AppLanguage.text(
          'Please search and select a place first',
          'कृपया पहिले ठाउँ खोजेर छान्नुहोस्',
        ),
      );
      return;
    }

    await _fetchWeatherForPlace(place, savePlace: false);

    _showMessage(AppLanguage.text('Weather refreshed ✅', 'मौसम अपडेट भयो ✅'));
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingWeather = true;
      _errorMessage = '';
      _aiErrorMessage = '';
      _searchResults = [];
      _weatherAiResult = null;
    });

    try {
      final place = await WeatherService.getCurrentLocationPlace();

      await _fetchWeatherForPlace(place, savePlace: true);

      _showMessage(
        AppLanguage.text(
          'Current location weather loaded ✅',
          'हालको स्थानको मौसम लोड भयो ✅',
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Current location failed: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _removeSavedPlace(WeatherPlace place) async {
    await WeatherService.removeSavedPlace(place);

    final saved = await WeatherService.getSavedPlaces();
    final selected = await WeatherService.getSelectedPlace();

    setState(() {
      _savedPlaces = saved;
      _selectedPlace = selected;
      _weatherAiResult = null;

      if (selected == null) {
        _weather = null;
      }
    });
  }

  Future<void> _saveFarmProfile() async {
    final place = _selectedPlace;

    if (place == null) {
      _showMessage(
        AppLanguage.text(
          'Please select a weather location first',
          'कृपया पहिले मौसम स्थान छान्नुहोस्',
        ),
      );
      return;
    }

    if (_activeCropEn == 'Crop' || _activeCropEn.trim().isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please type crop name',
          'कृपया बालीको नाम लेख्नुहोस्',
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: '${AppLanguage.text(_activeCropEn, _activeCropNe)} Farm',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLanguage.text(
              'Save farm weather profile',
              'फार्म मौसम प्रोफाइल सेभ गर्नुहोस्',
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: AppLanguage.text('Profile name', 'प्रोफाइल नाम'),
              hintText: AppLanguage.text(
                'Example: My Mango Farm',
                'उदाहरण: मेरो आँप फार्म',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLanguage.text('Cancel', 'रद्द गर्नुहोस्')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: Text(AppLanguage.text('Save', 'सेभ')),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;

    final profile = WeatherFarmProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileName: name.trim(),
      cropEn: _activeCropEn,
      cropNe: _activeCropNe,
      place: place,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await WeatherService.saveFarmProfile(profile);

    final profiles = await WeatherService.getFarmProfiles();

    setState(() {
      _farmProfiles = profiles;
    });

    _showMessage(
      AppLanguage.text(
        'Farm weather profile saved ✅',
        'फार्म मौसम प्रोफाइल सेभ भयो ✅',
      ),
    );
  }

  Future<void> _openFarmProfile(WeatherFarmProfile profile) async {
    setState(() {
      _selectedCrop = _isCommonCrop(profile.cropEn) ? profile.cropEn : 'Other';

      if (_selectedCrop == 'Other') {
        _customCropController.text = profile.cropEn;
      } else {
        _customCropController.clear();
      }

      _selectedPlace = profile.place;
      _weatherAiResult = null;
      _aiErrorMessage = '';
    });

    await WeatherService.selectFarmProfile(profile);

    await _fetchWeatherForPlace(profile.place, savePlace: false);
  }

  Future<void> _removeFarmProfile(WeatherFarmProfile profile) async {
    await WeatherService.removeFarmProfile(profile);

    final profiles = await WeatherService.getFarmProfiles();

    setState(() {
      _farmProfiles = profiles;
    });

    _showMessage(
      AppLanguage.text('Farm profile removed', 'फार्म प्रोफाइल हटाइयो'),
    );
  }

  Future<void> _saveAdviceHistorySnapshot() async {
    final weather = _weather;

    if (weather == null) return;

    final history = WeatherAdviceHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cropEn: _activeCropEn,
      cropNe: _activeCropNe,
      placeName: weather.place.displayName,
      alertEn: _farmAlertTitleEn,
      alertNe: _farmAlertTitleNe,
      actionOneEn: _mainActionOneEn,
      actionOneNe: _mainActionOneNe,
      actionTwoEn: _mainActionTwoEn,
      actionTwoNe: _mainActionTwoNe,
      cropAdviceEn: _cropAdviceEn,
      cropAdviceNe: _cropAdviceNe,
      createdAt: DateTime.now().toIso8601String(),
    );

    await WeatherService.saveAdviceHistory(history);

    final histories = await WeatherService.getAdviceHistory();

    if (mounted) {
      setState(() {
        _adviceHistory = histories;
      });
    }
  }

  Future<void> _saveAiAdviceHistorySnapshot(WeatherAiResult result) async {
    final weather = _weather;

    if (weather == null) return;

    final firstActionEn = result.aiWeatherActions.isNotEmpty
        ? result.aiWeatherActions.first
        : _mainActionOneEn;

    final firstActionNe = result.aiWeatherActionsNe.isNotEmpty
        ? result.aiWeatherActionsNe.first
        : _mainActionOneNe;

    final secondActionEn = result.aiWeatherActions.length > 1
        ? result.aiWeatherActions[1]
        : _mainActionTwoEn;

    final secondActionNe = result.aiWeatherActionsNe.length > 1
        ? result.aiWeatherActionsNe[1]
        : _mainActionTwoNe;

    final history = WeatherAdviceHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cropEn: _activeCropEn,
      cropNe: _activeCropNe,
      placeName: weather.place.displayName,
      alertEn: result.aiWeatherRisk,
      alertNe: result.aiWeatherRiskNe,
      actionOneEn: firstActionEn,
      actionOneNe: firstActionNe,
      actionTwoEn: secondActionEn,
      actionTwoNe: secondActionNe,
      cropAdviceEn: result.aiWeatherSummary,
      cropAdviceNe: result.aiWeatherSummaryNe,
      createdAt: DateTime.now().toIso8601String(),
    );

    await WeatherService.saveAdviceHistory(history);

    final histories = await WeatherService.getAdviceHistory();

    if (mounted) {
      setState(() {
        _adviceHistory = histories;
      });
    }
  }

  Future<void> _clearAdviceHistory() async {
    await WeatherService.clearAdviceHistory();

    setState(() {
      _adviceHistory = [];
    });

    _showMessage(
      AppLanguage.text(
        'Weather advice history cleared',
        'मौसम सुझाव इतिहास हटाइयो',
      ),
    );
  }

  Future<void> _getAiWeatherSummary() async {
    final weather = _weather;

    if (weather == null) {
      _showMessage(
        AppLanguage.text(
          'Please load weather first',
          'कृपया पहिले मौसम लोड गर्नुहोस्',
        ),
      );
      return;
    }

    if (_activeCropEn == 'Crop' || _activeCropEn.trim().isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please type crop name first',
          'कृपया पहिले बालीको नाम लेख्नुहोस्',
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAiSummary = true;
      _aiErrorMessage = '';
      _weatherAiResult = null;
    });

    try {
      final result = await WeatherAiService.getWeatherAiSummary(
        cropName: _activeCropEn,
        cropNameNe: _activeCropNe,
        weather: weather,
        mainAlert: _farmAlertMessageEn,
        localAdvice: _cropAdviceEn,
      );

      setState(() {
        _weatherAiResult = result;
      });

      await _saveAiAdviceHistorySnapshot(result);

      await WeatherFirestoreService.saveAiWeatherAdvice(
        cropName: _activeCropEn,
        cropNameNe: _activeCropNe,
        weather: weather,
        aiResult: result,
      );

      _showMessage(
        AppLanguage.text(
          'AI farming summary created and saved ✅',
          'एआई खेती सुझाव तयार भयो र सेभ भयो ✅',
        ),
      );
    } catch (e) {
      setState(() {
        _aiErrorMessage = 'AI weather summary failed: $e';
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingAiSummary = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color get _mainColor {
    final weather = _weather;

    if (weather == null) return Colors.green;
    if (weather.isRainy) return Colors.blue;
    if (weather.isHot) return Colors.orange;
    if (weather.isCold) return Colors.indigo;
    if (weather.isWindy) return Colors.teal;
    if (weather.isHumid) return Colors.deepOrange;

    return Colors.green;
  }

  IconData get _mainIcon {
    final weather = _weather;

    if (weather == null) return Icons.cloud;
    if (weather.weatherType == 'Clear') return Icons.wb_sunny;
    if (weather.isRainy) return Icons.water_drop;
    if (weather.isWindy) return Icons.air;
    if (weather.isCold) return Icons.ac_unit;
    if (weather.isHumid) return Icons.bug_report;

    return Icons.cloud;
  }

  String get _selectedCropNe {
    if (_selectedCrop == 'Tomato') return 'टमाटर';
    if (_selectedCrop == 'Rice') return 'धान';
    if (_selectedCrop == 'Potato') return 'आलु';
    if (_selectedCrop == 'Maize') return 'मकै';
    if (_selectedCrop == 'Wheat') return 'गहुँ';
    if (_selectedCrop == 'Vegetables') return 'तरकारी';
    if (_selectedCrop == 'Other') return 'अन्य';
    return 'बाली';
  }

  String get _activeCropEn {
    if (_selectedCrop == 'Other') {
      final typed = _customCropController.text.trim();
      return typed.isEmpty ? 'Crop' : typed;
    }

    return _selectedCrop;
  }

  String get _activeCropNe {
    if (_selectedCrop == 'Other') {
      final typed = _customCropController.text.trim();
      return typed.isEmpty ? 'बाली' : typed;
    }

    return _selectedCropNe;
  }

  String get _farmAlertTitleEn {
    final weather = _weather;

    if (weather == null) return 'No weather alert';
    if (weather.isRainy) return 'Rain Risk';
    if (weather.isHot) return 'Heat Risk';
    if (weather.isCold) return 'Cold Risk';
    if (weather.isWindy) return 'Wind Risk';
    if (weather.isHumid) return 'Disease Risk';

    return 'Normal Weather';
  }

  String get _farmAlertTitleNe {
    final weather = _weather;

    if (weather == null) return 'मौसम चेतावनी छैन';
    if (weather.isRainy) return 'पानी पर्ने जोखिम';
    if (weather.isHot) return 'गर्मी जोखिम';
    if (weather.isCold) return 'चिसो जोखिम';
    if (weather.isWindy) return 'हावाको जोखिम';
    if (weather.isHumid) return 'रोगको जोखिम';

    return 'सामान्य मौसम';
  }

  String get _farmAlertMessageEn {
    final weather = _weather;

    if (weather == null) {
      return 'Choose crop and search your farm location.';
    }

    if (weather.isRainy) {
      return 'Avoid spraying today. Check field drainage and protect young plants.';
    }

    if (weather.isHot) {
      return 'Water early morning or late afternoon. Check soil moisture.';
    }

    if (weather.isCold) {
      return 'Protect young seedlings and sensitive crops from cold.';
    }

    if (weather.isWindy) {
      return 'Avoid spraying. Support weak plants if needed.';
    }

    if (weather.isHumid) {
      return 'Check leaves for fungal signs like spots, white powder, or rot.';
    }

    return 'Weather is suitable for normal farm care.';
  }

  String get _farmAlertMessageNe {
    final weather = _weather;

    if (weather == null) {
      return 'बाली छानेर आफ्नो फार्मको स्थान खोज्नुहोस्।';
    }

    if (weather.isRainy) {
      return 'आज छर्कने काम नगर्नुहोस्। पानी निकास जाँच गर्नुहोस् र साना बिरुवालाई जोगाउनुहोस्।';
    }

    if (weather.isHot) {
      return 'बिहान वा साँझ पानी दिनुहोस्। माटोको चिस्यान जाँच गर्नुहोस्।';
    }

    if (weather.isCold) {
      return 'साना बिरुवा र संवेदनशील बालीलाई चिसोबाट जोगाउनुहोस्।';
    }

    if (weather.isWindy) {
      return 'छर्कने काम नगर्नुहोस्। कमजोर बिरुवालाई support दिनुहोस्।';
    }

    if (weather.isHumid) {
      return 'पातमा दाग, सेतो धुलो वा कुहिने लक्षण छ कि छैन जाँच गर्नुहोस्।';
    }

    return 'मौसम सामान्य खेती हेरचाहका लागि ठीक छ।';
  }

  IconData get _farmAlertIcon {
    final weather = _weather;

    if (weather == null) return Icons.info_outline;
    if (weather.isRainy) return Icons.water_drop;
    if (weather.isHot) return Icons.wb_sunny;
    if (weather.isCold) return Icons.ac_unit;
    if (weather.isWindy) return Icons.air;
    if (weather.isHumid) return Icons.bug_report;

    return Icons.check_circle;
  }

  Color get _farmAlertColor {
    final weather = _weather;

    if (weather == null) return Colors.green;
    if (weather.isRainy) return Colors.blue;
    if (weather.isHot) return Colors.orange;
    if (weather.isCold) return Colors.indigo;
    if (weather.isWindy) return Colors.teal;
    if (weather.isHumid) return Colors.deepOrange;

    return Colors.green;
  }

  String get _mainActionOneEn {
    final weather = _weather;

    if (weather == null) return 'Search location';
    if (weather.isRainy) return 'Do not spray today';
    if (weather.isHot) return 'Water early or late';
    if (weather.isCold) return 'Protect seedlings';
    if (weather.isWindy) return 'Avoid spraying';
    if (weather.isHumid) return 'Check leaf disease';

    return 'Continue normal care';
  }

  String get _mainActionOneNe {
    final weather = _weather;

    if (weather == null) return 'स्थान खोज्नुहोस्';
    if (weather.isRainy) return 'आज छर्कने काम नगर्नुहोस्';
    if (weather.isHot) return 'बिहान वा साँझ पानी दिनुहोस्';
    if (weather.isCold) return 'साना बिरुवा जोगाउनुहोस्';
    if (weather.isWindy) return 'छर्कने काम नगर्नुहोस्';
    if (weather.isHumid) return 'पातको रोग जाँच गर्नुहोस्';

    return 'सामान्य हेरचाह गर्नुहोस्';
  }

  String get _mainActionTwoEn {
    final weather = _weather;

    if (weather == null) return 'Choose crop';
    if (weather.isRainy) return 'Check drainage';
    if (weather.isHot) return 'Check soil moisture';
    if (weather.isCold) return 'Cover sensitive crops';
    if (weather.isWindy) return 'Support weak plants';
    if (weather.isHumid) return 'Improve airflow';

    return 'Monitor crop';
  }

  String get _mainActionTwoNe {
    final weather = _weather;

    if (weather == null) return 'बाली छान्नुहोस्';
    if (weather.isRainy) return 'पानी निकास जाँच गर्नुहोस्';
    if (weather.isHot) return 'माटोको चिस्यान जाँच गर्नुहोस्';
    if (weather.isCold) return 'संवेदनशील बाली छोप्नुहोस्';
    if (weather.isWindy) return 'कमजोर बिरुवा support गर्नुहोस्';
    if (weather.isHumid) return 'हावा चल्ने बनाउनुहोस्';

    return 'बाली जाँच गर्नुहोस्';
  }

  String get _cropAdviceEn {
    final weather = _weather;

    if (weather == null) {
      return 'Choose a crop and search your farm location.';
    }

    if (_selectedCrop == 'Tomato') {
      if (weather.isRainy || weather.isHumid) {
        return 'For tomato, wet weather can increase blight and fruit spot risk. Keep leaves dry and check fruits.';
      }
      if (weather.isHot) {
        return 'For tomato, heat can cause flower drop. Keep soil moisture even.';
      }
      return 'For tomato, keep watering even and check leaves and fruits.';
    }

    if (_selectedCrop == 'Rice') {
      if (weather.isRainy) {
        return 'For rice, rain can help, but check water level and protect young seedlings.';
      }
      if (weather.isHot) {
        return 'For rice, hot weather increases water need. Keep field moisture stable.';
      }
      return 'For rice, maintain proper field water level.';
    }

    if (_selectedCrop == 'Potato') {
      if (weather.isRainy || weather.isHumid) {
        return 'For potato, wet weather can increase blight risk. Check leaves and avoid waterlogging.';
      }
      if (weather.isHot) {
        return 'For potato, heat can stress plants. Keep soil moisture stable.';
      }
      return 'For potato, keep soil well-drained and check leaves.';
    }

    if (_selectedCrop == 'Maize') {
      if (weather.isWindy) {
        return 'For maize, strong wind can bend plants. Check field and support weak plants.';
      }
      if (weather.isHot) {
        return 'For maize, heat increases water need. Keep soil moisture stable.';
      }
      if (weather.isRainy) {
        return 'For maize, avoid waterlogging near roots.';
      }
      return 'For maize, monitor leaves, height, and soil moisture.';
    }

    if (_selectedCrop == 'Wheat') {
      if (weather.isRainy || weather.isHumid) {
        return 'For wheat, wet weather can increase fungal risk. Check leaves for rust-like spots.';
      }
      if (weather.isHot) {
        return 'For wheat, heat can stress crop. Maintain moisture if possible.';
      }
      return 'For wheat, monitor leaves and soil moisture.';
    }

    if (_selectedCrop == 'Vegetables') {
      if (weather.isRainy || weather.isHumid) {
        return 'For vegetables, wet weather can increase rot and fungal problems. Keep spacing and remove rotten parts.';
      }
      if (weather.isHot) {
        return 'For vegetables, heat can cause wilting. Water early or late.';
      }
      return 'For vegetables, keep regular watering and check pests.';
    }

    if (_selectedCrop == 'Other') {
      return 'For $_activeCropEn, follow the weather alert above. Use AI summary for more specific advice about this crop.';
    }

    return 'Weather looks manageable. Keep checking your crop.';
  }

  String get _cropAdviceNe {
    final weather = _weather;

    if (weather == null) {
      return 'बाली छानेर फार्मको स्थान खोज्नुहोस्।';
    }

    if (_selectedCrop == 'Tomato') {
      if (weather.isRainy || weather.isHumid) {
        return 'टमाटरमा चिसो मौसमले डढुवा र फलको दागको जोखिम बढाउन सक्छ। पात सुक्खा राख्नुहोस् र फल जाँच गर्नुहोस्।';
      }
      if (weather.isHot) {
        return 'टमाटरमा गर्मीले फूल झर्ने समस्या हुन सक्छ। माटोको चिस्यान एकनास राख्नुहोस्।';
      }
      return 'टमाटरमा पानी एकनास दिनुहोस् र पात तथा फल जाँच गर्नुहोस्।';
    }

    if (_selectedCrop == 'Rice') {
      if (weather.isRainy) {
        return 'धानका लागि पानीले सहयोग गर्छ, तर पानीको स्तर जाँच गर्नुहोस् र साना बेर्ना जोगाउनुहोस्।';
      }
      if (weather.isHot) {
        return 'धानमा गर्मीले पानीको आवश्यकता बढाउँछ। खेतको चिस्यान स्थिर राख्नुहोस्।';
      }
      return 'धानमा खेतको पानीको स्तर ठीक राख्नुहोस्।';
    }

    if (_selectedCrop == 'Potato') {
      if (weather.isRainy || weather.isHumid) {
        return 'आलुमा चिसो मौसमले ब्लाइट जोखिम बढाउन सक्छ। पात जाँच गर्नुहोस् र पानी जम्न नदिनुहोस्।';
      }
      if (weather.isHot) {
        return 'आलुमा गर्मीले बिरुवामा तनाव दिन सक्छ। माटोको चिस्यान स्थिर राख्नुहोस्।';
      }
      return 'आलुमा माटो राम्रो निकास हुने राख्नुहोस् र पात जाँच गर्नुहोस्।';
    }

    if (_selectedCrop == 'Maize') {
      if (weather.isWindy) {
        return 'मकैमा धेरै हावाले बोट ढलाउन सक्छ। खेत जाँच गर्नुहोस् र कमजोर बोटलाई support दिनुहोस्।';
      }
      if (weather.isHot) {
        return 'मकैमा गर्मीले पानीको आवश्यकता बढाउँछ। माटोको चिस्यान स्थिर राख्नुहोस्।';
      }
      if (weather.isRainy) {
        return 'मकैमा जराको वरिपरि पानी जम्न नदिनुहोस्।';
      }
      return 'मकैमा पात, बोटको उचाइ र माटोको चिस्यान जाँच गर्नुहोस्।';
    }

    if (_selectedCrop == 'Wheat') {
      if (weather.isRainy || weather.isHumid) {
        return 'गहुँमा चिसो मौसमले फंगल रोगको जोखिम बढाउन सक्छ। पातमा रस्ट जस्तो दाग जाँच गर्नुहोस्।';
      }
      if (weather.isHot) {
        return 'गहुँमा गर्मीले बालीमा तनाव दिन सक्छ। सम्भव भए चिस्यान राख्नुहोस्।';
      }
      return 'गहुँमा पात र माटोको चिस्यान जाँच गर्नुहोस्।';
    }

    if (_selectedCrop == 'Vegetables') {
      if (weather.isRainy || weather.isHumid) {
        return 'तरकारीमा चिसो मौसमले कुहिने र फंगल समस्या बढाउन सक्छ। दूरी राख्नुहोस् र कुहिएको भाग हटाउनुहोस्।';
      }
      if (weather.isHot) {
        return 'तरकारीमा गर्मीले ओइलाउने समस्या ल्याउन सक्छ। बिहान वा साँझ पानी दिनुहोस्।';
      }
      return 'तरकारीमा नियमित पानी दिनुहोस् र किरा जाँच गर्नुहोस्।';
    }

    if (_selectedCrop == 'Other') {
      return '$_activeCropNe का लागि माथिको मौसम चेतावनी पालना गर्नुहोस्। यो बालीबारे अझ विशेष सुझावका लागि एआई सारांश प्रयोग गर्नुहोस्।';
    }

    return 'मौसम सामान्य देखिन्छ। बाली नियमित जाँच गर्नुहोस्।';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customCropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final color = _mainColor;

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Weather Advice', 'मौसम सुझाव'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroCard(),
                const SizedBox(height: 14),
                _setupCard(),
                const SizedBox(height: 14),

                if (_farmProfiles.isNotEmpty) ...[
                  _farmProfilesCard(),
                  const SizedBox(height: 14),
                ],

                if (_savedPlaces.isNotEmpty) ...[
                  _savedPlacesCard(),
                  const SizedBox(height: 14),
                ],

                if (_errorMessage.trim().isNotEmpty) ...[
                  _errorCard(_errorMessage),
                  const SizedBox(height: 14),
                ],

                if (_isLoadingWeather)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (weather == null)
                  _emptyWeatherCard()
                else ...[
                  _farmAlertCard(),
                  const SizedBox(height: 14),
                  _weatherSummaryCard(weather, color),
                  const SizedBox(height: 14),
                  _farmerActionCard(),
                  const SizedBox(height: 14),
                  _aiWeatherButton(),
                  if (_aiErrorMessage.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _errorCard(_aiErrorMessage),
                  ],
                  if (_weatherAiResult != null) ...[
                    const SizedBox(height: 14),
                    _aiWeatherCard(_weatherAiResult!),
                  ],
                  const SizedBox(height: 14),
                  _saveProfileButton(),
                  const SizedBox(height: 14),
                  _forecastCard(weather.forecast),
                  if (_adviceHistory.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _historyCard(),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
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
                  AppLanguage.text('Farm Weather Guide', 'खेती मौसम गाइड'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLanguage.text(
                    'Choose common crop or type any crop name.',
                    'सामान्य बाली छान्नुहोस् वा कुनै पनि बालीको नाम लेख्नुहोस्।',
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

  Widget _setupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.agriculture,
            title: AppLanguage.text('1. Choose crop', '१. बाली छान्नुहोस्'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cropOptions.map((crop) {
              final english = crop['en'] ?? '';
              final nepali = crop['ne'] ?? '';
              final selected = _selectedCrop == english;

              return ChoiceChip(
                label: Text(AppLanguage.text(english, nepali)),
                selected: selected,
                selectedColor: Colors.green.shade700,
                backgroundColor: Colors.green.shade50,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCrop = english;
                    if (english != 'Other') {
                      _customCropController.clear();
                    }
                    _weatherAiResult = null;
                    _aiErrorMessage = '';
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedCrop == 'Other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customCropController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: AppLanguage.text(
                  'Type crop, fruit or vegetable name',
                  'बाली, फलफूल वा तरकारीको नाम लेख्नुहोस्',
                ),
                hintText: AppLanguage.text(
                  'Example: Mango, Onion, Chilli',
                  'उदाहरण: Mango, Onion, Chilli',
                ),
                prefixIcon: Icon(Icons.eco, color: Colors.green.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.green.shade700,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _weatherAiResult = null;
                  _aiErrorMessage = '';
                });
              },
            ),
          ],
          const SizedBox(height: 18),
          _sectionTitle(
            icon: Icons.place,
            title: AppLanguage.text(
              '2. Choose location',
              '२. स्थान छान्नुहोस्',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchPlaces(),
            decoration: InputDecoration(
              hintText: AppLanguage.text(
                'Search place, example Chitwan',
                'स्थान खोज्नुहोस्, जस्तै Chitwan',
              ),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchPlaces,
                  icon: _isSearching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(AppLanguage.text('Search', 'खोज्नुहोस्')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoadingWeather ? null : _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(AppLanguage.text('My Location', 'मेरो स्थान')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade300),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              AppLanguage.text(
                'Tap your correct place',
                'आफ्नो सही स्थान थिच्नुहोस्',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._searchResults.map((place) {
              return Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.green.shade100),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.place, color: Colors.green.shade700),
                  ),
                  title: Text(
                    place.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${place.latitude.toStringAsFixed(2)}, ${place.longitude.toStringAsFixed(2)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                  onTap: () => _fetchWeatherForPlace(place),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _farmProfilesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.home_work,
            title: AppLanguage.text(
              'Saved farm profiles',
              'सेभ गरिएका फार्म प्रोफाइल',
            ),
          ),
          const SizedBox(height: 10),
          ..._farmProfiles.map((profile) {
            return Card(
              elevation: 0,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.green.shade100),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: const Icon(Icons.agriculture, color: Colors.white),
                ),
                title: Text(
                  profile.profileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${AppLanguage.text(profile.cropEn, profile.cropNe)} • ${profile.place.displayName}',
                ),
                trailing: IconButton(
                  onPressed: () => _removeFarmProfile(profile),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onTap: () => _openFarmProfile(profile),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _savedPlacesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.bookmark,
            title: AppLanguage.text('Saved places', 'सेभ गरिएका स्थान'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _savedPlaces.map((place) {
              final selected =
                  _selectedPlace != null &&
                  _selectedPlace!.name == place.name &&
                  _selectedPlace!.country == place.country &&
                  _selectedPlace!.latitude == place.latitude &&
                  _selectedPlace!.longitude == place.longitude;

              return InputChip(
                selected: selected,
                label: Text(
                  place.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.green.shade800,
                  ),
                ),
                selectedColor: Colors.green.shade700,
                backgroundColor: Colors.green.shade50,
                avatar: Icon(
                  Icons.place,
                  size: 17,
                  color: selected ? Colors.white : Colors.green.shade700,
                ),
                onPressed: () => _fetchWeatherForPlace(place),
                onDeleted: () => _removeSavedPlace(place),
                deleteIconColor: selected ? Colors.white : Colors.red,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _farmAlertCard() {
    final alertColor = _farmAlertColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        color: alertColor.withOpacity(0.10),
        borderColor: alertColor.withOpacity(0.24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: alertColor,
            child: Icon(_farmAlertIcon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('Today’s Main Alert', 'आजको मुख्य चेतावनी'),
                  style: TextStyle(
                    color: alertColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLanguage.text(_farmAlertTitleEn, _farmAlertTitleNe),
                  style: TextStyle(
                    color: alertColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLanguage.text(_farmAlertMessageEn, _farmAlertMessageNe),
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherSummaryCard(WeatherResult weather, Color color) {
    final weatherTitle = AppLanguage.text(
      weather.weatherType,
      weather.weatherTypeNe,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: color.withOpacity(0.13),
                child: Icon(_mainIcon, color: color, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.place.displayName,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      weatherTitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isLoadingWeather ? null : _refreshCurrentWeather,
                icon: Icon(Icons.refresh, color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _weatherMiniTile(
                icon: Icons.thermostat,
                label: AppLanguage.text('Temp', 'तापक्रम'),
                value: weather.temperatureText,
                color: color,
              ),
              _weatherMiniTile(
                icon: Icons.water_drop,
                label: AppLanguage.text('Rain', 'पानी'),
                value: weather.rainChanceText,
                color: color,
              ),
              _weatherMiniTile(
                icon: Icons.opacity,
                label: AppLanguage.text('Humidity', 'आर्द्रता'),
                value: weather.humidityText,
                color: color,
              ),
              _weatherMiniTile(
                icon: Icons.air,
                label: AppLanguage.text('Wind', 'हावा'),
                value: weather.windText,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherMiniTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _farmerActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        color: Colors.green.withOpacity(0.07),
        borderColor: Colors.green.withOpacity(0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.checklist,
            title: AppLanguage.text(
              'What farmer should do',
              'किसानले के गर्ने',
            ),
          ),
          const SizedBox(height: 12),
          _actionLine(
            number: '1',
            text: AppLanguage.text(_mainActionOneEn, _mainActionOneNe),
          ),
          const SizedBox(height: 8),
          _actionLine(
            number: '2',
            text: AppLanguage.text(_mainActionTwoEn, _mainActionTwoNe),
          ),
          const SizedBox(height: 8),
          _actionLine(
            number: '3',
            text: AppLanguage.text(_cropAdviceEn, _cropAdviceNe),
          ),
        ],
      ),
    );
  }

  Widget _actionLine({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Colors.green.shade700,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _aiWeatherButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoadingAiSummary ? null : _getAiWeatherSummary,
        icon: _isLoadingAiSummary
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isLoadingAiSummary
              ? AppLanguage.text(
                  'Creating AI summary...',
                  'एआई सुझाव बनाउँदै...',
                )
              : AppLanguage.text(
                  'Get AI Farming Summary',
                  'एआई खेती सुझाव लिनुहोस्',
                ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _aiWeatherCard(WeatherAiResult result) {
    final title = AppLanguage.text(
      result.aiWeatherTitle,
      result.aiWeatherTitleNe,
    );

    final risk = AppLanguage.text(result.aiWeatherRisk, result.aiWeatherRiskNe);

    final summary = AppLanguage.text(
      result.aiWeatherSummary,
      result.aiWeatherSummaryNe,
    );

    final actions = AppLanguage.isNepali && result.aiWeatherActionsNe.isNotEmpty
        ? result.aiWeatherActionsNe
        : result.aiWeatherActions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        color: Colors.purple.withOpacity(0.07),
        borderColor: Colors.purple.withOpacity(0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLanguage.text('AI Farming Summary', 'एआई खेती सुझाव'),
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppLanguage.text('Risk', 'जोखिम')}: $risk',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLanguage.text('AI suggested actions', 'एआईले दिएको काम'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            ...actions
                .take(3)
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            action,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Text(
            AppLanguage.text(
              'AI advice is only guidance. For chemical use or serious crop problems, ask a local agriculture expert.',
              'एआई सुझाव केवल सामान्य मार्गदर्शन हो। रसायन प्रयोग वा गम्भीर बाली समस्यामा स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।',
            ),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saveFarmProfile,
        icon: const Icon(Icons.save),
        label: Text(
          AppLanguage.text(
            'Save this crop and place',
            'यो बाली र स्थान सेभ गर्नुहोस्',
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade300),
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _forecastCard(List<DailyWeather> forecast) {
    if (forecast.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Text(
          AppLanguage.text(
            '5-day forecast is not available right now.',
            '५ दिनको मौसम पूर्वानुमान अहिले उपलब्ध छैन।',
          ),
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.calendar_month,
            title: AppLanguage.text('Next 5 days', 'आउँदो ५ दिन'),
          ),
          const SizedBox(height: 12),
          ...forecast.map((day) => _simpleForecastTile(day)),
        ],
      ),
    );
  }

  Widget _simpleForecastTile(DailyWeather day) {
    final label = AppLanguage.text(day.dayLabel, day.dayLabelNe);
    final weatherType = AppLanguage.text(day.weatherType, day.weatherTypeNe);
    final advice = AppLanguage.text(day.farmerAdviceEn, day.farmerAdviceNe);

    Color color = Colors.green;
    IconData icon = Icons.cloud;

    if (day.isRainy) {
      color = Colors.blue;
      icon = Icons.water_drop;
    } else if (day.isHot) {
      color = Colors.orange;
      icon = Icons.wb_sunny;
    } else if (day.isCold) {
      color = Colors.indigo;
      icon = Icons.ac_unit;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label • $weatherType',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLanguage.text('High', 'उच्च')}: ${day.maxTempText}  •  ${AppLanguage.text('Low', 'कम')}: ${day.minTempText}  •  ${AppLanguage.text('Rain', 'पानी')}: ${day.rainChanceText}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(advice, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    final recentHistory = _adviceHistory.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  icon: Icons.history,
                  title: AppLanguage.text(
                    'Recent advice history',
                    'हालैको सुझाव इतिहास',
                  ),
                ),
              ),
              TextButton(
                onPressed: _clearAdviceHistory,
                child: Text(AppLanguage.text('Clear', 'हटाउनुहोस्')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentHistory.map((history) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLanguage.text(history.cropEn, history.cropNe)} • ${history.placeName}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLanguage.text(history.alertEn, history.alertNe),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLanguage.text(
                      history.cropAdviceEn,
                      history.cropAdviceNe,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.cloud_queue, color: Colors.green, size: 58),
          const SizedBox(height: 12),
          Text(
            AppLanguage.text('No weather selected', 'मौसम स्थान छानिएको छैन'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Choose crop and search your farm location.',
              'बाली छानेर आफ्नो फार्मको स्थान खोज्नुहोस्।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: borderColor == null ? null : Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
