importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAQ2uisN34aKHiMpNjysOycupBUXW03PLY",
  appId: "1:879649532829:web:c8c6fbfc330d51d85add74",
  messagingSenderId: "879649532829",
  projectId: "delivery-app-79bf7",
  authDomain: "delivery-app-79bf7.firebaseapp.com",
  storageBucket: "delivery-app-79bf7.firebasestorage.app",
  measurementId: "G-66DW45LH0R"
});

const messaging = firebase.messaging();
