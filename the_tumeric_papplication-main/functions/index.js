/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Send FCM notification when order status changes
exports.sendOrderStatusNotification = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      
      // Check if status actually changed
      if (before.status === after.status) {
        return null;
      }

      const orderId = context.params.orderId;
      const userId = after.userId;
      const newStatus = after.status;
      const orderTotal = after.total;

      try {
        // Get user's FCM token
        const userTokenDoc = await admin.firestore()
            .collection("user_tokens")
            .doc(userId)
            .get();

        if (!userTokenDoc.exists) {
          console.log(`No FCM token found for user: ${userId}`);
          return null;
        }

        const userToken = userTokenDoc.data().token;
        
        // Get notification content based on status
        const notificationContent = getOrderStatusNotification(
            newStatus, 
            orderId, 
            orderTotal
        );

        // Prepare FCM message
        const message = {
          token: userToken,
          notification: {
            title: notificationContent.title,
            body: notificationContent.message,
          },
          data: {
            type: "order_status",
            orderId: orderId,
            status: newStatus,
            orderTotal: orderTotal.toString(),
          },
          android: {
            notification: {
              channelId: "order_updates",
              priority: "high",
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send FCM message
        const response = await admin.messaging().send(message);
        console.log(`Successfully sent message: ${response}`);

        // Create notification record in Firestore
        await admin.firestore().collection("notifications").add({
          userId: userId,
          title: notificationContent.title,
          message: notificationContent.message,
          type: "order_status",
          orderId: orderId,
          orderStatus: newStatus,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          additionalData: {
            orderTotal: orderTotal.toString(),
            timestamp: new Date().toISOString(),
          },
        });

        return response;
      } catch (error) {
        console.error("Error sending notification:", error);
        return null;
      }
    });

// Send promotional notifications to all users
exports.sendPromotionalNotification = functions.https.onCall(
    async (data, context) => {
      // Check if request is from admin (you should implement proper auth)
      if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can send promotional notifications."
        );
      }

      const {title, message, imageUrl} = data;

      try {
        // Get all user tokens
        const userTokensSnapshot = await admin.firestore()
            .collection("user_tokens")
            .get();

        const messages = [];
        const notificationPromises = [];

        userTokensSnapshot.forEach((doc) => {
          const userData = doc.data();
          const userId = userData.userId;
          const token = userData.token;

          // Prepare FCM message
          messages.push({
            token: token,
            notification: {
              title: title,
              body: message,
              imageUrl: imageUrl || undefined,
            },
            data: {
              type: "promotion",
              timestamp: Date.now().toString(),
            },
            android: {
              notification: {
                channelId: "promotions",
                priority: "default",
                defaultSound: true,
              },
            },
          });

          // Create notification record
          notificationPromises.push(
              admin.firestore().collection("notifications").add({
                userId: userId,
                title: title,
                message: message,
                type: "promotion",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                additionalData: {
                  imageUrl: imageUrl || null,
                  timestamp: new Date().toISOString(),
                },
              })
          );
        });

        // Send all messages in batches
        const batchSize = 500;
        const results = [];

        for (let i = 0; i < messages.length; i += batchSize) {
          const batch = messages.slice(i, i + batchSize);
          const batchResponse = await admin.messaging().sendAll(batch);
          results.push(batchResponse);
        }

        // Create notification records
        await Promise.all(notificationPromises);

        const totalSent = results.reduce(
            (sum, result) => sum + result.successCount, 
            0
        );
        const totalFailed = results.reduce(
            (sum, result) => sum + result.failureCount, 
            0
        );

        return {
          success: true,
          totalSent: totalSent,
          totalFailed: totalFailed,
          message: `Sent ${totalSent} notifications successfully, ${totalFailed} failed`,
        };
      } catch (error) {
        console.error("Error sending promotional notifications:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send promotional notifications"
        );
      }
    });

// Clean up old notifications (run daily)
exports.cleanupOldNotifications = functions.pubsub
    .schedule("0 2 * * *") // Run daily at 2 AM
    .onRun(async (context) => {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      try {
        const oldNotificationsQuery = admin.firestore()
            .collection("notifications")
            .where("createdAt", "<", thirtyDaysAgo);

        const snapshot = await oldNotificationsQuery.get();
        
        if (snapshot.empty) {
          console.log("No old notifications to delete");
          return null;
        }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`Deleted ${snapshot.docs.length} old notifications`);

        return null;
      } catch (error) {
        console.error("Error cleaning up old notifications:", error);
        return null;
      }
    });

// Helper function to get notification content based on order status
function getOrderStatusNotification(status, orderId, orderTotal) {
  const shortOrderId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
  
  switch (status.toLowerCase()) {
    case "confirmed":
      return {
        title: "✅ Order Confirmed!",
        message: `Great! Your order #${shortOrderId} worth ₹${orderTotal} has been confirmed. We'll start preparing it soon.`,
      };
    case "preparing":
      return {
        title: "👨‍🍳 Kitchen is Preparing Your Order",
        message: `Our chefs are carefully preparing your order #${shortOrderId}. It will be ready soon!`,
      };
    case "out_for_delivery":
      return {
        title: "🚀 Order Out for Delivery",
        message: `Your order #${shortOrderId} is on its way! Expected delivery in 20-30 minutes.`,
      };
    case "delivered":
      return {
        title: "🎉 Order Delivered Successfully",
        message: `Your order #${shortOrderId} has been delivered successfully. Enjoy your meal! 🍽️`,
      };
    case "cancelled":
      return {
        title: "❌ Order Cancelled",
        message: `Your order #${shortOrderId} has been cancelled. If you have any questions, please contact support.`,
      };
    default:
      return {
        title: "📦 Order Status Updated",
        message: `Your order #${shortOrderId} status has been updated to ${status}.`,
      };
  }
}

// Send welcome notification to new users
exports.sendWelcomeNotification = functions.auth.user().onCreate(
    async (user) => {
      try {
        // Wait a bit for user registration to complete
        setTimeout(async () => {
          // Get user's FCM token (might not be available immediately)
          const userTokenDoc = await admin.firestore()
              .collection("user_tokens")
              .doc(user.uid)
              .get();

          // Create welcome notification record
          await admin.firestore().collection("notifications").add({
            userId: user.uid,
            title: "🎉 Welcome to The Turmeric!",
            message: "Thanks for joining us! Explore our delicious menu and place your first order to get started. Enjoy exclusive offers and fast delivery!",
            type: "general",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            additionalData: {
              isWelcome: true,
              timestamp: new Date().toISOString(),
            },
          });

          // If FCM token is available, send push notification
          if (userTokenDoc.exists) {
            const userToken = userTokenDoc.data().token;
            
            const welcomeMessage = {
              token: userToken,
              notification: {
                title: "🎉 Welcome to The Turmeric!",
                body: "Thanks for joining us! Explore our delicious menu and place your first order.",
              },
              data: {
                type: "welcome",
                timestamp: Date.now().toString(),
              },
            };

            await admin.messaging().send(welcomeMessage);
            console.log(`Welcome notification sent to user: ${user.uid}`);
          }
        }, 5000); // Wait 5 seconds

        return null;
      } catch (error) {
        console.error("Error sending welcome notification:", error);
        return null;
      }
    });

// package.json for functions
/*
{
  "name": "functions",
  "description": "Cloud Functions for Firebase",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^11.8.0",
    "firebase-functions": "^4.3.1"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0"
  },
  "private": true
}
*/