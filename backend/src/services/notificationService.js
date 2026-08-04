'use strict';

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You need to set GOOGLE_APPLICATION_CREDENTIALS in your environment,
// or initialize it explicitly here with a service account file.
try {
  if (!admin.apps.length) {
    admin.initializeApp(); // Assuming GOOGLE_APPLICATION_CREDENTIALS is set
    console.log('Firebase Admin SDK initialized successfully');
  }
} catch (error) {
  console.error('Failed to initialize Firebase Admin SDK:', error);
}

/**
 * Send a push notification to a specific token.
 * 
 * @param {string} token - The FCM device token.
 * @param {string} title - The notification title.
 * @param {string} body - The notification body.
 * @param {object} [data] - Optional custom data payload.
 * @returns {Promise<boolean>} True if successful, false otherwise.
 */
async function sendPushNotification(token, title, body, data = {}) {
  if (!token) return false;

  const message = {
    notification: {
      title,
      body,
    },
    data,
    token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return true;
  } catch (error) {
    console.error('Error sending message:', error);
    // You could optionally handle token removal here if error.code is 'messaging/registration-token-not-registered'
    return false;
  }
}

module.exports = {
  sendPushNotification,
};
