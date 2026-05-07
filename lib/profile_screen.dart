import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _mainCropController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _profileRef {
    final user = _currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('farmers').doc(user.uid);
  }

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final user = _currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final ref = _profileRef;

    if (ref == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          _fullNameController.text = (data['fullName'] ?? '').toString();
          _phoneController.text = (data['phone'] ?? '').toString();
          _districtController.text = (data['district'] ?? '').toString();
          _municipalityController.text = (data['municipality'] ?? '')
              .toString();
          _mainCropController.text = (data['mainCrop'] ?? '').toString();
          _farmSizeController.text = (data['farmSize'] ?? '').toString();
        }
      }
    } catch (e) {
      _showMessage(
        AppLanguage.text(
          'Failed to load profile: $e',
          'प्रोफाइल लोड गर्न समस्या भयो: $e',
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _currentUser;
    final profileRef = _profileRef;
    final userRef = _userRef;

    if (user == null || profileRef == null || userRef == null) {
      _showMessage(
        AppLanguage.text('You must be logged in', 'तपाईं लगइन भएको हुनुपर्छ'),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fullName = _fullNameController.text.trim();

      final profileData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': fullName,
        'name': fullName,
        'displayName': fullName,
        'phone': _phoneController.text.trim(),
        'district': _districtController.text.trim(),
        'municipality': _municipalityController.text.trim(),
        'mainCrop': _mainCropController.text.trim(),
        'farmSize': _farmSizeController.text.trim(),
        'role': 'farmer',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await profileRef.set({
        ...profileData,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await userRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': fullName,
        'name': fullName,
        'displayName': fullName,
        'farmerName': fullName,
        'phone': _phoneController.text.trim(),
        'district': _districtController.text.trim(),
        'municipality': _municipalityController.text.trim(),
        'mainCrop': _mainCropController.text.trim(),
        'farmSize': _farmSizeController.text.trim(),
        'role': 'farmer',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showMessage(
        AppLanguage.text(
          'Profile saved successfully ✅',
          'प्रोफाइल सफलतापूर्वक सेभ भयो ✅',
        ),
      );
    } catch (e) {
      _showMessage(
        AppLanguage.text(
          'Failed to save profile: $e',
          'प्रोफाइल सेभ गर्न समस्या भयो: $e',
        ),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _mainCropController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentUser?.email ?? 'No email';

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Farmer Profile', 'किसान प्रोफाइल'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _profileHeader(email),
                        const SizedBox(height: 18),
                        _profileForm(),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _profileHeader(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
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
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.green, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text('Farm Owner Details', 'फार्म मालिक विवरण'),
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

  Widget _profileForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _textField(
              controller: _fullNameController,
              label: AppLanguage.text('Full Name', 'पूरा नाम'),
              icon: Icons.person,
              validatorText: AppLanguage.text(
                'Please enter your full name',
                'कृपया पूरा नाम लेख्नुहोस्',
              ),
            ),
            _textField(
              controller: _phoneController,
              label: AppLanguage.text('Phone Number', 'फोन नम्बर'),
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validatorText: AppLanguage.text(
                'Please enter your phone number',
                'कृपया फोन नम्बर लेख्नुहोस्',
              ),
            ),
            _textField(
              controller: _districtController,
              label: AppLanguage.text('District', 'जिल्ला'),
              icon: Icons.location_on,
              validatorText: AppLanguage.text(
                'Please enter your district',
                'कृपया जिल्ला लेख्नुहोस्',
              ),
            ),
            _textField(
              controller: _municipalityController,
              label: AppLanguage.text(
                'Municipality / Village',
                'पालिका / गाउँ',
              ),
              icon: Icons.home,
              validatorText: AppLanguage.text(
                'Please enter your municipality or village',
                'कृपया पालिका वा गाउँ लेख्नुहोस्',
              ),
            ),
            _textField(
              controller: _mainCropController,
              label: AppLanguage.text('Main Crop', 'मुख्य बाली'),
              icon: Icons.grass,
              validatorText: AppLanguage.text(
                'Please enter your main crop',
                'कृपया मुख्य बाली लेख्नुहोस्',
              ),
            ),
            _textField(
              controller: _farmSizeController,
              label: AppLanguage.text('Farm Size', 'फार्म आकार'),
              icon: Icons.landscape,
              hintText: AppLanguage.text(
                'Example: 2 ropani / 1 bigha',
                'उदाहरण: २ रोपनी / १ बिघा',
              ),
              validatorText: AppLanguage.text(
                'Please enter your farm size',
                'कृपया फार्म आकार लेख्नुहोस्',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? AppLanguage.text('Saving...', 'सेभ हुँदैछ...')
                      : AppLanguage.text(
                          'Save Profile',
                          'प्रोफाइल सेभ गर्नुहोस्',
                        ),
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
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorText,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return validatorText;
          }

          return null;
        },
      ),
    );
  }
}
