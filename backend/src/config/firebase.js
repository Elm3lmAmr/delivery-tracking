const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require(path.join(__dirname, '../../firebase-service-account.json'));

const app = initializeApp({
  credential: cert(serviceAccount)
});

module.exports = {
  auth: () => getAuth(app)
};
