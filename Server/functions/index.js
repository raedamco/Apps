const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp({
  databaseURL: "https://theory-parking.firebaseio.com"
});

const stripe = require('stripe')("sk_test_CFsR0YQ2XzltRxt6pmRCxoOH00rs0xeJ3I");
var slack = require('slack-notify')('https://hooks.slack.com/services/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');
// var logging = require('@google-cloud/logging')();

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

// [START chargecustomer]
// Charge the Stripe customer whenever an amount is created in Cloud Firestore

exports.createStripeCharge = functions.firestore.document('stripe_customers/{userId}/charges/{id}').onCreate(async (snap, context) => {
      const val = snap.data();
      try {
        // Look up the Stripe customer id written in createStripeCustomer
        const snapshot = await admin.firestore().collection(`stripe_customers`).doc(context.params.userId).get()
        const snapval = snapshot.data();
        const customer = snapval.customer_id
        // Create a charge using the pushId as the idempotency key
        // protecting against double charges
        const amount = val.amount;
        const details = context.params.details;
        const idempotencyKey = context.params.id;
        const charge = {amount, currency, customer};
        if (val.source !== null) {
          charge.source = val.source;
        }
        const response = await stripe.charges.create(charge, {idempotency_key: idempotencyKey}, details);
        return snap.ref.set(response, { merge: true });
      } catch(error) {
        console.log(error);
        await snap.ref.set({error: userFacingMessage(error)}, { merge: true });
        return reportError(error, {user: context.params.userId});
      }
    });
// [END chargecustomer]]


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


exports.startPayment = functions.https.onCall((data, context) => {
    const UID = data.UID;
    const Location = data.Location;
    const Organization = data.Organization;
    const Floor = data.Floor;
    const Spot = data.Spot;
    const Rate = data.Rate;
    const TimerStart = new Date();

    try {
        admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).collection("History").doc().set({
            Data: {
                "Location": Location,
                "Organization": Organization,
                "Floor": Floor,
                "Spot": Spot,
                "Rate": Rate
            },
            Duration: {
                Begin: admin.firestore.Timestamp.fromDate(TimerStart)
            },
      }, {merge: true});
        return {Status: true}
    } catch(error) {
        console.log(error);
        return {Status: false}
    }
});


exports.createCharge = functions.https.onCall((data, context) => {
    try {
        completeTransaction(data)
    }catch(error){
        console.log(error);
    }
});

function completeTransaction(data){

    const TimerEnd = new Date();

    var UserData = {
        Name: String(),
        UID: data.UID,
        StripeID: String(),
    }

    var TransactionDetails = {
        Duration: String(),
        Rate: String(),
        Begin: String(),
        End: String(),
        Amount: String(),
        TransactionID: String(),
        DocumentID: String(),
        Organizaiton: String(),
        Location: String(),
    }

    //Get user data first
    admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).get().then(doc => {
        if (!doc.exists) {
            return console.log('No such document!');
        }else{
            UserData.StripeID = doc.data().StripeID
            UserData.Name = doc.data().Name
            return finalizeTransaction();
        }
    }).catch(err => {
        console.log('Error getting document', err);
    });

    function finalizeTransaction(){
        admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").orderBy('Duration.Begin', 'desc').limit(1).get().then(function(querySnapshot) {
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

    function updateDatabaseDocument(){
        TransactionDetails.End = admin.firestore.Timestamp.fromDate(TimerEnd)
        TransactionDetails.Duration = Math.floor(((TransactionDetails.End.toDate() - TransactionDetails.Begin.toDate())/1000)/60)
        TransactionDetails.Amount = (TransactionDetails.Duration * TransactionDetails.Rate)

        admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").doc(TransactionDetails.DocumentID).set({
            Duration: {
                End: TransactionDetails.End,
                Minutes: TransactionDetails.Duration,
            },
            Transaction: {
                Amount: TransactionDetails.Amount,
                TransactionID: "Placeholder"
            }
        }, {merge: true});
        //createStripeCharge();
    }

    return {
      Amount: TransactionDetails.Amount,
      Duration: TransactionDetails.Duration
    };
}
