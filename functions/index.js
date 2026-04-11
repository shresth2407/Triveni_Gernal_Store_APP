const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to send push notifications to admin when a new order is created
 */
exports.sendOrderNotificationToAdmin = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;

    try {
      // Get all admin FCM tokens
      const tokensSnapshot = await admin.firestore()
        .collection('admin_tokens')
        .get();

      if (tokensSnapshot.empty) {
        console.log('No admin tokens found');
        return null;
      }

      // Prepare notification payload
      const notification = {
        title: '🔔 New Order Received!',
        body: `Order #${orderId.substring(0, 8)} • ₹${order.totalAmount.toFixed(0)} • ${order.items.length} items`,
      };

      const data = {
        orderId: orderId,
        totalAmount: order.totalAmount.toString(),
        itemCount: order.items.length.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        route: `/admin/orders/${orderId}`,
      };

      // Send notification to all admin tokens
      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
      
      const message = {
        notification: notification,
        data: data,
        tokens: tokens,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'order_notifications',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMultitoken(message);
      
      console.log(`Successfully sent ${response.successCount} notifications`);
      if (response.failureCount > 0) {
        console.log(`Failed to send ${response.failureCount} notifications`);
        
        // Remove invalid tokens
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            invalidTokens.push(tokens[idx]);
          }
        });
        
        // Delete invalid tokens from Firestore
        const batch = admin.firestore().batch();
        tokensSnapshot.docs.forEach(doc => {
          if (invalidTokens.includes(doc.data().token)) {
            batch.delete(doc.ref);
          }
        });
        await batch.commit();
      }

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });
