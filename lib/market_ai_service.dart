import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'app_language.dart';

class SellCropScreen extends StatefulWidget {
  const SellCropScreen({super.key});

  @override
  State<SellCropScreen> createState() => _SellCropScreenState();
}

class _SellCropScreenState extends State<SellCropScreen> {
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _cropNameNeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  bool _isPickingImage = false;

  Uint8List? _selectedImageBytes;

  String _selectedQuantityUnit = 'kg';
  String _selectedPriceUnit = 'kg';
  String _selectedQuality = 'Good';

  final List<String> _quantityUnits = [
    'kg',
    'quintal',
    'ton',
    'crate',
    'muri',
    'dozen',
    'piece',
  ];

  final List<String> _priceUnits = [
    'kg',
    'quintal',
    'ton',
    'crate',
    'muri',
    'dozen',
    'piece',
  ];

  final List<String> _qualityOptions = ['Excellent', 'Good', 'Average'];

  String _qualityNe(String quality) {
    if (quality == 'Excellent') return 'उत्कृष्ट';
    if (quality == 'Average') return 'सामान्य';
    return 'राम्रो';
  }

  double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String _formatNumber(String value) {
    final number = _toDouble(value);

    if (number == number.roundToDouble()) {
      return number.round().toString();
    }

    return number.toStringAsFixed(2);
  }

  String get _quantityText {
    if (_quantityController.text.trim().isEmpty) {
      return AppLanguage.text('Quantity not added', 'मात्रा थपिएको छैन');
    }

    return '${_formatNumber(_quantityController.text)} $_selectedQuantityUnit';
  }

  String get _priceText {
    if (_priceController.text.trim().isEmpty) {
      return AppLanguage.text('Price not added', 'मूल्य थपिएको छैन');
    }

    return 'Rs. ${_formatNumber(_priceController.text)}/$_selectedPriceUnit';
  }

  String get _cropDisplayName {
    if (AppLanguage.isNepali && _cropNameNeController.text.trim().isNotEmpty) {
      return _cropNameNeController.text.trim();
    }

    if (_cropNameController.text.trim().isNotEmpty) {
      return _cropNameController.text.trim();
    }

    return AppLanguage.text('Crop name', 'बालीको नाम');
  }

  Future<void> _pickCropImage(ImageSource source) async {
    if (!mounted) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      _showMessage(
        AppLanguage.text(
          'Failed to pick image: $e',
          'फोटो छान्न समस्या भयो: $e',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4F8F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLanguage.text('Preview crop photo', 'बालीको फोटो preview'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLanguage.text(
                    'Photo upload is currently turned off because Firebase Storage is not enabled.',
                    'Firebase Storage enable नभएकाले अहिले फोटो upload बन्द छ।',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 14),
                _sheetButton(
                  icon: Icons.camera_alt,
                  text: AppLanguage.text('Take Photo', 'फोटो खिच्नुहोस्'),
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickCropImage(ImageSource.camera);
                  },
                ),
                _sheetButton(
                  icon: Icons.photo_library,
                  text: AppLanguage.text(
                    'Choose from Gallery',
                    'ग्यालरीबाट छान्नुहोस्',
                  ),
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickCropImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImageBytes != null)
                  _sheetButton(
                    icon: Icons.delete_outline,
                    text: AppLanguage.text(
                      'Remove Preview',
                      'Preview हटाउनुहोस्',
                    ),
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImageBytes = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.45)),
          padding: const EdgeInsets.all(13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _uploadCropImage(String userId) async {
    return {'imageUrl': '', 'imagePath': ''};
  }

  Future<void> _saveListing() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        AppLanguage.text('You must be logged in', 'तपाईं लगइन भएको हुनुपर्छ'),
      );
      return;
    }

    final cropName = _cropNameController.text.trim();
    final cropNameNe = _cropNameNeController.text.trim();
    final quantityValue = _toDouble(_quantityController.text);
    final priceValue = _toDouble(_priceController.text);
    final location = _locationController.text.trim();
    final contact = _contactController.text.trim();
    final note = _noteController.text.trim();

    if (cropName.isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please enter crop name',
          'कृपया बालीको नाम लेख्नुहोस्',
        ),
      );
      return;
    }

    if (quantityValue <= 0) {
      _showMessage(
        AppLanguage.text(
          'Please enter valid quantity',
          'कृपया सही मात्रा लेख्नुहोस्',
        ),
      );
      return;
    }

    if (priceValue <= 0) {
      _showMessage(
        AppLanguage.text(
          'Please enter valid price',
          'कृपया सही मूल्य लेख्नुहोस्',
        ),
      );
      return;
    }

    if (location.isEmpty) {
      _showMessage(
        AppLanguage.text('Please enter location', 'कृपया स्थान लेख्नुहोस्'),
      );
      return;
    }

    if (contact.isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please enter contact number',
          'कृपया सम्पर्क नम्बर लेख्नुहोस्',
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imageData = await _uploadCropImage(user.uid);

      await FirebaseFirestore.instance.collection('cropListings').add({
        'userId': user.uid,
        'userEmail': user.email,

        'cropName': cropName,
        'cropNameNe': cropNameNe,
        'crop': cropName,
        'name': cropName,

        'quantityValue': quantityValue,
        'quantityUnit': _selectedQuantityUnit,
        'quantity':
            '${_formatNumber(_quantityController.text)} $_selectedQuantityUnit',

        'priceValue': priceValue,
        'priceUnit': _selectedPriceUnit,
        'unit': _selectedPriceUnit,
        'marketPrice': priceValue,
        'priceEn': priceValue.toString(),
        'price':
            'Rs. ${_formatNumber(_priceController.text)}/$_selectedPriceUnit',

        'location': location,
        'contact': contact,

        'quality': _selectedQuality,
        'qualityNe': _qualityNe(_selectedQuality),

        'note': note,

        'imageUrl': imageData['imageUrl'],
        'imagePath': imageData['imagePath'],

        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _cropNameController.clear();
      _cropNameNeController.clear();
      _quantityController.clear();
      _priceController.clear();
      _locationController.clear();
      _contactController.clear();
      _noteController.clear();

      if (!mounted) return;

      setState(() {
        _selectedQuantityUnit = 'kg';
        _selectedPriceUnit = 'kg';
        _selectedQuality = 'Good';
        _selectedImageBytes = null;
      });

      _showMessage(
        AppLanguage.text(
          'Crop listing saved successfully ✅',
          'बाली लिस्टिङ सफलतापूर्वक सेभ भयो ✅',
        ),
      );
    } catch (e) {
      _showMessage(
        AppLanguage.text(
          'Failed to save listing: $e',
          'लिस्टिङ सेभ गर्न समस्या भयो: $e',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    _cropNameController.dispose();
    _cropNameNeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _noteController.dispose();
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
              AppLanguage.text('Sell Crops', 'बाली बेच्नुहोस्'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  _quickHelpCard(),
                  const SizedBox(height: 16),
                  _formCard(),
                  const SizedBox(height: 16),
                  _previewCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard() {
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
            child: Icon(Icons.shopping_bag, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(
                    'Create Crop Listing',
                    'बाली लिस्टिङ बनाउनुहोस्',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLanguage.text(
                    'Add crop details so buyers can contact you directly.',
                    'बालीको विवरण थप्नुहोस् ताकि खरिदकर्ताले सिधै सम्पर्क गर्न सकून्।',
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

  Widget _quickHelpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderColor: Colors.orange.withOpacity(0.18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLanguage.text(
                'Photo upload is currently turned off. You can still create crop listings with crop name, price, quantity, location and contact details.',
                'अहिले फोटो upload बन्द छ। तपाईं अझै पनि बालीको नाम, मूल्य, मात्रा, स्थान र सम्पर्क विवरण राखेर लिस्टिङ बनाउन सक्नुहुन्छ।',
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.photo_camera,
            title: AppLanguage.text(
              'Crop photo preview optional',
              'बाली फोटो preview वैकल्पिक',
            ),
          ),
          const SizedBox(height: 12),
          _imagePickerBox(),
          const SizedBox(height: 18),
          _sectionTitle(
            icon: Icons.eco,
            title: AppLanguage.text('Crop details', 'बाली विवरण'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: _cropNameController,
            label: AppLanguage.text('Crop Name', 'बालीको नाम'),
            icon: Icons.eco,
            hintText: 'Tomato',
          ),
          _field(
            controller: _cropNameNeController,
            label: AppLanguage.text(
              'Crop Name in Nepali optional',
              'नेपालीमा बालीको नाम वैकल्पिक',
            ),
            icon: Icons.language,
            hintText: 'टमाटर',
          ),
          _field(
            controller: _quantityController,
            label: AppLanguage.text('Quantity', 'मात्रा'),
            icon: Icons.scale,
            keyboardType: TextInputType.number,
            hintText: '50',
          ),
          _dropdownField(
            label: AppLanguage.text('Quantity Unit', 'मात्राको एकाइ'),
            value: _selectedQuantityUnit,
            items: _quantityUnits,
            icon: Icons.straighten,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedQuantityUnit = value;
              });
            },
          ),
          _field(
            controller: _priceController,
            label: AppLanguage.text('Price', 'मूल्य'),
            icon: Icons.payments,
            keyboardType: TextInputType.number,
            hintText: '80',
          ),
          _dropdownField(
            label: AppLanguage.text('Price Per Unit', 'प्रति एकाइ मूल्य'),
            value: _selectedPriceUnit,
            items: _priceUnits,
            icon: Icons.scale,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedPriceUnit = value;
              });
            },
          ),
          _dropdownField(
            label: AppLanguage.text('Crop Quality', 'बाली गुणस्तर'),
            value: _selectedQuality,
            items: _qualityOptions,
            icon: Icons.verified,
            showNepaliQuality: true,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedQuality = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle(
            icon: Icons.place,
            title: AppLanguage.text('Seller details', 'बिक्रेता विवरण'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: _locationController,
            label: AppLanguage.text('Location', 'स्थान'),
            icon: Icons.location_on,
            hintText: 'Chitwan',
          ),
          _field(
            controller: _contactController,
            label: AppLanguage.text('Contact Number', 'सम्पर्क नम्बर'),
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            hintText: '98XXXXXXXX',
          ),
          _field(
            controller: _noteController,
            label: AppLanguage.text('Note optional', 'नोट वैकल्पिक'),
            icon: Icons.note_alt,
            hintText: AppLanguage.text(
              'Example: fresh crop, ready today',
              'उदाहरण: ताजा बाली, आज तयार छ',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 6),
          _infoBox(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveListing,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_business),
              label: Text(
                _isSaving
                    ? AppLanguage.text('Saving...', 'सेभ हुँदैछ...')
                    : AppLanguage.text('Create Listing', 'लिस्टिङ बनाउनुहोस्'),
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

  Widget _imagePickerBox() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _isPickingImage ? null : _showImagePickerSheet,
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withOpacity(0.18)),
        ),
        child: _selectedImageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    color: Colors.green.shade700,
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLanguage.text(
                      'Tap to preview crop photo',
                      'बालीको फोटो preview गर्न थिच्नुहोस्',
                    ),
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLanguage.text(
                      'Optional preview only',
                      'वैकल्पिक preview मात्र',
                    ),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.55),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _previewCard() {
    final qualityText = AppLanguage.text(
      _selectedQuality,
      _qualityNe(_selectedQuality),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        color: Colors.white,
        borderColor: Colors.green.withOpacity(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.visibility,
            title: AppLanguage.text('Listing Preview', 'लिस्टिङ पूर्वावलोकन'),
          ),
          const SizedBox(height: 12),
          if (_selectedImageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _selectedImageBytes!,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLanguage.text(
                'Photo is preview only and will not be uploaded.',
                'फोटो preview मात्र हो र upload हुँदैन।',
              ),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(Icons.eco, color: Colors.green.shade700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cropDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _priceText,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _previewLine(
            icon: Icons.scale,
            label: AppLanguage.text('Quantity', 'मात्रा'),
            value: _quantityText,
          ),
          _previewLine(
            icon: Icons.verified,
            label: AppLanguage.text('Quality', 'गुणस्तर'),
            value: qualityText,
          ),
          _previewLine(
            icon: Icons.place,
            label: AppLanguage.text('Location', 'स्थान'),
            value: _locationController.text.trim().isEmpty
                ? AppLanguage.text('Location not added', 'स्थान थपिएको छैन')
                : _locationController.text.trim(),
          ),
          _previewLine(
            icon: Icons.phone,
            label: AppLanguage.text('Contact', 'सम्पर्क'),
            value: _contactController.text.trim().isEmpty
                ? AppLanguage.text('Contact not added', 'सम्पर्क थपिएको छैन')
                : _contactController.text.trim(),
          ),
          if (_noteController.text.trim().isNotEmpty)
            _previewLine(
              icon: Icons.note_alt,
              label: AppLanguage.text('Note', 'नोट'),
              value: _noteController.text.trim(),
            ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      ],
    );
  }

  Widget _infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLanguage.text(
                'Your active listing will appear in Marketplace. Buyers can contact you directly.',
                'तपाईंको active लिस्टिङ Marketplace मा देखिनेछ। खरिदकर्ताले सिधै सम्पर्क गर्न सक्छन्।',
              ),
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black45, size: 18),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
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
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    bool showNepaliQuality = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
        items: items.map((item) {
          final display = showNepaliQuality
              ? AppLanguage.text(item, _qualityNe(item))
              : item;

          return DropdownMenuItem(
            value: item,
            child: Text(display, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: borderColor == null ? null : Border.all(color: borderColor),
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
