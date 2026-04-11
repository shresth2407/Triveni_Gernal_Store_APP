# Quick Start: Push Notifications

## 🚀 Deploy in 3 Steps

### Step 1: Install Dependencies
```bash
# Already done - firebase_messaging added to pubspec.yaml
flutter pub get
```

### Step 2: Deploy Cloud Function
```bash
cd functions
npm install
firebase login
firebase deploy --only functions
```

### Step 3: Configure Android
Add to `android/app/src/main/AndroidManifest.xml` inside `<application>` tag:

```xml
<!-- FCM Notification Channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="order_notifications" />
```

## ✅ That's It!

Now when a customer places an order:
1. Cloud Function automatically triggers
2. Sends push notification to all admin devices
3. Notification shows: Order ID, Amount, Item count
4. Tapping notification opens order details

## 📱 Test It

1. Login to admin app
2. Place order from customer app
3. Admin receives push notification! 🔔

## 🔧 Troubleshooting

**No notification?**
- Check `admin_tokens` collection in Firestore (should have your token)
- Check Cloud Function logs: `firebase functions:log`
- Ensure notification permissions granted on device

**Function won't deploy?**
- Ensure Firebase project is on Blaze (pay-as-you-go) plan
- Check Node.js version: `node --version` (need v18+)

## 📊 What Was Added

### Flutter App
- `lib/services/admin/fcm_service.dart` - FCM token management
- Updated `admin_dashboard_screen.dart` - Initialize FCM on login

### Cloud Function
- `functions/index.js` - Sends notifications when orders created
- Automatically cleans up invalid tokens

### Firestore
- New collection: `admin_tokens` - Stores FCM tokens for admins

## 💰 Cost
- FCM: **FREE** (unlimited)
- Cloud Functions: **FREE** for first 2M invocations/month
- Typical usage: 1 invocation per order = essentially free

## 🎯 Features
- ✅ Real-time push notifications
- ✅ Works even when app is closed
- ✅ Multiple admin devices supported
- ✅ Automatic token cleanup
- ✅ Order details in notification
- ✅ Direct navigation to order

See `PUSH_NOTIFICATIONS_SETUP.md` for detailed documentation.
