# Push Notifications Setup Guide

This guide explains how to set up Firebase Cloud Messaging (FCM) push notifications for admin order alerts.

## Prerequisites

1. Firebase project already configured
2. Node.js installed (v18 or higher)
3. Firebase CLI installed: `npm install -g firebase-tools`

## Setup Steps

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

This will install `firebase_messaging: ^15.0.0` which was added to `pubspec.yaml`.

### 2. Configure Android for FCM

Add the following to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<!-- FCM -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="order_notifications" />

<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.CLOUD_MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### 3. Initialize Firebase Cloud Functions

```bash
cd functions
npm install
```

### 4. Deploy Cloud Functions

Login to Firebase (if not already logged in):
```bash
firebase login
```

Deploy the function:
```bash
firebase deploy --only functions
```

Or from the functions directory:
```bash
npm run deploy
```

### 5. Test the Setup

1. **Run the admin app** and login as admin
2. **Check Firestore** - You should see a new document in the `admin_tokens` collection with the FCM token
3. **Place a test order** from the customer app
4. **Admin should receive** a push notification with order details

## How It Works

### Flutter App (Admin)

1. **FCM Initialization** (`lib/services/admin/fcm_service.dart`):
   - Requests notification permissions
   - Gets FCM token from device
   - Saves token to Firestore `admin_tokens` collection
   - Listens for token refresh

2. **Admin Dashboard** (`lib/screens/admin/admin_dashboard_screen.dart`):
   - Initializes FCM on login
   - Removes token on logout

### Cloud Function (`functions/index.js`)

1. **Trigger**: Listens for new documents in `orders` collection
2. **Process**:
   - Fetches all admin FCM tokens from `admin_tokens` collection
   - Sends push notification to all admin devices
   - Includes order details (ID, amount, item count)
   - Removes invalid/expired tokens automatically

### Notification Payload

```javascript
{
  title: "🔔 New Order Received!",
  body: "Order #abc12345 • ₹500 • 3 items",
  data: {
    orderId: "abc12345...",
    totalAmount: "500",
    itemCount: "3",
    route: "/admin/orders/abc12345..."
  }
}
```

## Firestore Collections

### `admin_tokens`
Stores FCM tokens for admin users:
```
{
  "adminUserId": {
    "token": "fcm_token_string",
    "updatedAt": timestamp
  }
}
```

## Troubleshooting

### No notifications received

1. **Check Firestore**: Verify token exists in `admin_tokens` collection
2. **Check Cloud Function logs**: `firebase functions:log`
3. **Verify permissions**: Ensure notification permissions are granted in device settings
4. **Test with Firebase Console**: Send a test notification from Firebase Console > Cloud Messaging

### Function deployment fails

1. **Check Node version**: Must be v18 or higher
2. **Verify Firebase project**: `firebase use --add`
3. **Check billing**: Cloud Functions require Blaze (pay-as-you-go) plan

### Token not saving

1. **Check Firestore rules**: Ensure admin can write to `admin_tokens`
2. **Check logs**: Look for errors in Flutter console
3. **Verify Firebase initialization**: Ensure Firebase is initialized before FCM

## Firestore Security Rules

Add these rules to allow admin token management:

```javascript
match /admin_tokens/{userId} {
  allow write: if request.auth != null && 
                  request.auth.token.admin == true;
  allow read: if request.auth != null && 
                 request.auth.token.admin == true;
}
```

## Cost Considerations

- **FCM**: Free (unlimited notifications)
- **Cloud Functions**: 
  - 2 million invocations/month free
  - After that: $0.40 per million invocations
  - Typical usage: ~1 invocation per order

## Production Checklist

- [ ] Deploy Cloud Functions to production
- [ ] Test notifications on physical devices
- [ ] Configure Firestore security rules
- [ ] Set up monitoring/alerts for function failures
- [ ] Test token refresh scenarios
- [ ] Verify notification sound and appearance
- [ ] Test with multiple admin devices

## Additional Features (Optional)

### Custom Notification Sound
Place custom sound file in `android/app/src/main/res/raw/` and update the Cloud Function:

```javascript
android: {
  notification: {
    sound: 'custom_sound.mp3',
  },
}
```

### Notification Actions
Add action buttons to notifications by updating the Cloud Function payload.

### Rich Notifications
Include images or expandable content in notifications.

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review Flutter console output
3. Verify Firestore data structure
4. Test with Firebase Console test messages
