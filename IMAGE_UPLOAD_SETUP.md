# Image Upload Feature - Setup Guide

## Overview
The admin product manager now supports image upload with crop functionality. Images are stored in Firebase Storage and automatically integrated into product listings.

## Features
- Pick images from gallery
- Crop images with free aspect ratio
- Automatic upload to Firebase Storage
- Image preview before saving
- Change/replace images for existing products

## Dependencies Added
```yaml
image_picker: ^1.0.7        # Pick images from gallery
crop_your_image: ^1.0.2     # Crop images with UI
firebase_storage: ^12.0.0   # Store images in Firebase
```

## Android Configuration
The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Image picker permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.CAMERA" />
```

## Firebase Storage Setup
1. Go to Firebase Console → Storage
2. Click "Get Started"
3. Choose production mode or test mode
4. Images will be stored in `products/` folder

## Usage in Admin Panel
1. Open Product Manager
2. Click "Add Product" or edit existing product
3. Tap the image upload area
4. Select image from gallery
5. Crop image as needed (free aspect ratio)
6. Tap checkmark to confirm crop
7. Image uploads automatically
8. Preview shows uploaded image
9. Click "Change Image" to replace

## File Structure
- `lib/services/image_upload_service.dart` - Image upload service with crop screen
- `lib/screens/admin/product_manager_screen.dart` - Updated with image upload widget
- `lib/providers/service_providers.dart` - Service provider registration

## Image Specifications
- Max dimensions: 1920x1920
- Quality: 85%
- Format: JPEG
- Storage path: `products/{timestamp}.jpg`
- Crop: Free aspect ratio (user can crop to any size)

## Testing
1. Run the app: `flutter run`
2. Login as admin
3. Navigate to Product Manager
4. Test adding new product with image
5. Test editing existing product image
6. Verify images appear in product listings

## Troubleshooting

### Image picker not working
- Ensure permissions are granted in device settings
- Check Firebase Storage rules allow write access

### Crop screen not appearing
- Verify crop_your_image package is installed
- Check that context is mounted before navigation

### Upload fails
- Verify Firebase Storage is enabled
- Check internet connection
- Review Firebase Storage security rules

## Security Notes
- Images are public by default in Firebase Storage
- Consider adding authentication rules for production
- Implement image size limits server-side if needed

## Technical Notes
- Uses `crop_your_image` package instead of `image_cropper` for better compatibility
- Crop screen is a custom full-screen widget with red theme
- Images are uploaded as bytes directly to Firebase Storage
- No temporary files are created on device
