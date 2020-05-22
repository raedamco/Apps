const functions = require('firebase-functions');
const admin = require('firebase-admin');
const firebase = require('firebase');

admin.initializeApp({
  databaseURL: "https://theory-parking.firebaseio.com"
});

var date = new Date();
console.log(admin.firestore.Timestamp.fromDate(date));
