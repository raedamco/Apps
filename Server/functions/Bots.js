//INITIALIZATION START
//HTTP packages
const express = require('express');
const cors = require('cors');
var bodyParser = require('body-parser');
const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended:true}));

//Firebase packages
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp({
  databaseURL: "https://theory-parking.firebaseio.com"
});

//Private keys
var slack = require('slack-notify')('https://hooks.slack.com/services/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');
//INITIALIZATION END

module.exports = {

}
