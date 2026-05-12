// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAaWK0XO_OJm8W5fhYu_jqbTb5weCAFp5M",
  authDomain: "alhawary-c4474.firebaseapp.com",
  projectId: "alhawary-c4474",
  storageBucket: "alhawary-c4474.firebasestorage.app",
  messagingSenderId: "284690570273",
  appId: "1:284690570273:web:cf2d472a491618e7dd9760",
});

const messaging = firebase.messaging();

// استقبال الإشعارات في الخلفية
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
  });
});