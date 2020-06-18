const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp({
  databaseURL: "https://theory-parking.firebaseio.com"
});

const express = require('express');
const cors = require('cors');
var bodyParser = require('body-parser');
const app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended:true
}));

const stripe = require('stripe')("sk_test_CFsR0YQ2XzltRxt6pmRCxoOH00rs0xeJ3I");
var slack = require('slack-notify')('https://hooks.slack.com/services/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');
// var logging = require('@google-cloud/logging')();


// [START reporterror]
function reportError(err, context = {}) {
  const logName = 'errors';
  const log = logging.log(logName);
  const metadata = {
    resource: {
      type: 'cloud_function',
      labels: {function_name: process.env.FUNCTION_NAME},
    },
  };
  const errorEvent = {
    message: err.stack,
    serviceContext: {
      service: process.env.FUNCTION_NAME,
      resourceType: 'cloud_function',
    },
    context: context,
  };
  return new Promise((resolve, reject) => {
    log.write(log.entry(metadata, errorEvent), (error) => {
      if (error) {
       return reject(error);
      }
      return resolve();
    });
  });
}
// [END reporterror]

function userFacingMessage(error) {
  return error.type ? error.message : 'An error occurred, developers have been alerted';
}


// Add a payment source (card) for a user by writing a stripe payment source token to Cloud Firestore
exports.addPaymentSource = functions.firestore.document('/stripe_customers/{userId}/tokens/{pushId}').onCreate(async (snap, context) => {
  const source = snap.data();
  const token = source.token;
  if (source === null){
    return null;
  }

  try {
    const snapshot = await admin.firestore().collection('stripe_customers').doc(context.params.userId).get();
    const customer =  snapshot.data().customer_id;
    const response = await stripe.customers.createSource(customer, {source: token});
    return admin.firestore().collection('stripe_customers').doc(context.params.userId).collection("sources").doc(response.fingerprint).set(response, {merge: true});
  } catch (error) {
    await snap.ref.set({'error':userFacingMessage(error)},{merge:true});
    return reportError(error, {user: context.params.userId});
  }
});

// When a user creates their account, set up their database log, stripe account, and notify slack
exports.addUser = functions.auth.user().onCreate(async (user) => {
    var date = new Date();
    const customer = await stripe.customers.create({email: user.email});

    admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).set({
        UUID: user.uid,
        Email: user.email,
        Joined: admin.firestore.Timestamp.fromDate(date),
        StripeID: customer.id
    }, {merge: true});

    await slack.send({
        'username': 'User Activity Bot',
        'text': 'New User Joined :tada:',
        'icon_emoji': ':tada:',
        'attachments': [{
          'color': '#30FCF1',
          'fields': [
            {
                'title': 'Joined On',
                'value': date.toUTCString(),
                'short': true
            }
          ]
        }]
    })
    return
});


// When a user deletes their account, clean up after them and notify slack
exports.removeUser = functions.auth.user().onDelete(async (user) => {
  const snapshot = await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).get();
  const snapval = snapshot.data();
  const joined = snapval.Joined;

  slack.send({
      'username': 'User Activity Bot',
      'text': 'User Deleted Account :disappointed:',
      'icon_emoji': ':x:',
      'attachments': [{
        'color': '#ff0000',
        'fields': [
          {
              'title': 'Member Since',
              'value': joined,
              'short': true
          },
        ]
      }]
  })

  await stripe.customers.del(snapval.StripeID);
  return admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).delete();
});

exports.addVehicleData = functions.https.onCall((data, context) => {
    const UID = data.UID;
    const VehicleData = data.VehicleData;

    try {
        admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).set({
            Vehicles: admin.firestore.FieldValue.arrayUnion(VehicleData)
        }, {merge: true});
    }catch(error){
        throw new functions.https.HttpsError('failed-precondition', 'Error adding data to database');
    }
});

exports.addPermitData = functions.https.onCall((data, context) => {
    const UID = data.UID;
    const PermitData = data.PermitData;
    const PermitNumer = data.PermitNumber;

    admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).set({
        Permits: {
            PermitData: PermitNumer
        }
    }, {merge: true});

    return
});

exports.startPayment = functions.https.onRequest(async (req, res) => {
    const UID = req.body.UID;
    const Lat = Number(req.body.Latitude);
    const Long = Number(req.body.Longitude);
    const Organization = req.body.Organization;
    const Floor = req.body.Floor;
    const Spot = req.body.Spot;
    const Rate = Number(req.body.Rate);
    const TimerStart = new Date();

    try {
        await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).collection("History").doc().set({
            Current: true,
            Data: {
                "Location": new admin.firestore.GeoPoint(Lat, Long),
                "Organization": Organization,
                "Floor": Floor,
                "Spot": Spot,
                "Rate": Rate
            },
            Duration: {
                Begin: admin.firestore.Timestamp.fromDate(TimerStart)
            },
      }, {merge: true});
        res.status(200).send({Status: true})
    } catch(error) {
        console.log(error);
        res.status(500).end()
    }
});


exports.createCharge = functions.https.onRequest(async (req, res) => {
    try {
        await completeTransaction(req.body)
        console.log("trasaction completed successfully")
        res.status(200).send({Completed: true})
    }catch(error){
        console.log("trasaction did not complete: ", error);
        res.status(500).end()
    }
});

async function completeTransaction(data){

    const TimerEnd = new Date();

    var UserData = {
        Name: String(),
        UID: data.UID,
        StripeID: String(),
    }

    var TransactionDetails = {
        IdempotencyKey: data.IdempotencyKey,
        Rate: Number(),
        Amount: Number(),
        Duration: String(),
        Begin: String(),
        End: String(),
        TransactionID: String(),
        DocumentID: String(),
        Organizaiton: String(),
        Location: String(),
        Source: String(),
        Currency: String("usd"),
        Details: String("details for charge"),
    }

    //Get user data first
    await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).get().then(doc => {
        if (!doc.exists) {
            return console.log('No such document!');
        }else{
            UserData.StripeID = String(doc.data().StripeID);
            UserData.Name = doc.data().Name
            UserData.Email = doc.data().Email
            return finalizeTransaction();
        }
    }).catch(err => {
        console.log('Error getting document', err);
    });

    async function finalizeTransaction(){
        await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").orderBy('Duration.Begin', 'desc').limit(1).get().then(function(querySnapshot) {
            querySnapshot.forEach(function(doc) {
                TransactionDetails.DocumentID = doc.id
                TransactionDetails.Begin = doc.data()["Duration"].Begin
                TransactionDetails.Rate = doc.data()["Data"].Rate
                TransactionDetails.Organizaiton = doc.data()["Data"].Organizaiton
                TransactionDetails.Location = doc.data()["Data"].Location
            });
            return updateDatabaseDocument();
        }).catch(function(error) {
            console.log("Error getting documents: " + error);
        });
    }

    async function updateDatabaseDocument(){
        TransactionDetails.End = admin.firestore.Timestamp.fromDate(TimerEnd)
        TransactionDetails.Duration = Math.floor(((TransactionDetails.End.toDate() - TransactionDetails.Begin.toDate())/1000)/60)
        TransactionDetails.Amount = parseInt((TransactionDetails.Duration * TransactionDetails.Rate) * 100)
        await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").doc(TransactionDetails.DocumentID).set({
            Current: false,
            Duration: {
                End: TransactionDetails.End,
                Minutes: TransactionDetails.Duration,
            },
            Transaction: {
                Amount: TransactionDetails.Amount
            }
        }, {merge: true});
        return createStripeCharge();
    }

    async function createStripeCharge(){
        try {
            // const paymentIntent = await stripe.paymentIntents.create({
            //     customer: UserData.StripeID,
            //     amount: TransactionDetails.Amount,
            //     currency: TransactionDetails.Currency,
            //     description: TransactionDetails.Details,
            //     payment_method_types: ['card'],
            // }
            stripe.charges.create({
                amount: 2000,
                customer: UserData.StripeID,
                currency: TransactionDetails.Currency,
                description: TransactionDetails.details,
            }, {
              idempotencyKey: TransactionDetails.IdempotencyKey
            }, function(err, charge) {
                console.log(err)
            });

            TransactionDetails.TransactionID = "transaction id placeholder" //response.id
            return updateDatabaseID(TransactionDetails.TransactionID)
        } catch(error) {
            return console.log(error);
        }
      }

      function updateDatabaseID(response) {
          admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").doc(TransactionDetails.DocumentID).set({
              Transaction: {
                  TransactionID: response
              }
          }, {merge: true});
      }
}

exports.getTotal = functions.https.onRequest(async (req, res) => {
    const TimerEnd = new Date();

    var TransactionDetails = {
        Duration: String(),
        Rate: Number(),
        Begin: String(),
        End: String(),
        Amount: Number(),
        Current: Boolean(),
        Document: String()
    }

    try{
        await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(req.body.UID).collection("History").orderBy('Duration.Begin', 'desc').limit(1).get().then(function(querySnapshot) {
        querySnapshot.forEach(function(doc) {
            TransactionDetails.Current = doc.data().Current
            TransactionDetails.Begin = doc.data()["Duration"].Begin
            TransactionDetails.Rate = doc.data()["Data"].Rate
            TransactionDetails.Document = doc.id
        });

            TransactionDetails.End = admin.firestore.Timestamp.fromDate(TimerEnd)
            TransactionDetails.Duration = Math.floor(((TransactionDetails.End.toDate() - TransactionDetails.Begin.toDate())/1000)/60)
            TransactionDetails.Amount = (TransactionDetails.Duration * TransactionDetails.Rate)
            return [TransactionDetails.Amount, TransactionDetails.Document,TransactionDetails.Current]

        }).catch(function(error) {
            console.log("Error getting documents: " + error);
        });

        if (TransactionDetails.Current){
            res.status(200).send({
                Amount: TransactionDetails.Amount,
                Document: TransactionDetails.Document,
                Current: TransactionDetails.Current
            })
        }else{
            res.status(500).send({
                Amount: TransactionDetails.Amount,
                Document: TransactionDetails.Document,
                Current: TransactionDetails.Current
            }).end()
        }

    }catch(error){
        console.log(error)
        return res.status(500).end()
    }
});




//STRIPE FUNCTIONS BEGIN//
exports.ephemeral_keys = functions.https.onRequest(async (req, res) => {
    try {
        let key = await stripe.ephemeralKeys.create(
          {customer: req.body.customer_id},
          {apiVersion: req.body.apiVersion}
        );
        let JSONResponse = JSON.stringify(key)
        res.status(200).send(JSONResponse)
    }catch(error){
        res.status(500).end()
    }
});

exports.create_setup_intent = functions.https.onRequest(async (req, res) => {
    try {
        const setupIntent = await stripe.setupIntents.create({
          customer: req.body.customer_id,
        });
        res.status(200).send({
          clientSecret: setupIntent.client_secret
        });
    }catch(error){
        res.status(500).end()
    }
});
//STRIPE FUNCTIONS END//
