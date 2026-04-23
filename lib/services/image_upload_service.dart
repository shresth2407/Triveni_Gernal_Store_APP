import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

abstract class ImageUploadService {
  Future<String?> pickAndUploadImage({
    required String folder,
    required BuildContext context,
  });
}

class FirebaseImageUploadService implements ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String?> pickAndUploadImage({
    required String folder,
    required BuildContext context,
  }) async {
    try {
      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Read image bytes
      final imageBytes = await pickedFile.readAsBytes();
      
      // Show crop dialog
      if (!context.mounted) return null;
      
      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (context) => _ImageCropScreen(imageBytes: imageBytes),
        ),
      );

      if (croppedBytes == null) return null;

      // Upload to Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');
      
      await ref.putData(croppedBytes);
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}

// Crop screen widget
class _ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _ImageCropScreen({required this.imageBytes});

  @override
  State<_ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<_ImageCropScreen> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC143C),
        title: const Text('Crop Image', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                setState(() => _isCropping = true);
                _cropController.crop();
              },
            ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _cropController,
        onCropped: (croppedData) {
          Navigator.of(context).pop(croppedData);
        },
        aspectRatio: null, // Free aspect ratio
        initialSize: 0.8,
        withCircleUi: false,
        baseColor: Colors.black,
        maskColor: Colors.black.withOpacity(0.5),
        radius: 0,
        onMoved: (newRect) {},
        onStatusChanged: (status) {},
        cornerDotBuilder: (size, edgeAlignment) => const DotControl(color: Color(0xFFDC143C)),
      ),
    );
  }
}
