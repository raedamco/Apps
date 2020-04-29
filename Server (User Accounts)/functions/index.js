const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp({
  databaseURL: "https://theory-parking.firebaseio.com"
});
// var logging = require('@google-cloud/logging')();
const stripe = require('stripe')("sk_test_CFsR0YQ2XzltRxt6pmRCxoOH00rs0xeJ3I");

// When a user is created, register them with Stripe
exports.createStripeCustomer = functions.auth.user().onCreate(async (user) => {
  const customer = await stripe.customers.create({email: user.email});
  return admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).set({"StripeID": customer.id}, {merge: true});
});

// When a user deletes their account, clean up after them
exports.cleanupUser = functions.auth.user().onDelete(async (user) => {
  const snapshot = await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).get();
  const customer = snapshot.data();
  await stripe.customers.del(customer.customer_id);
  return admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).delete();
});

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
exports.createCharge = functions.https.onCall((data, context) => {
    const details = data.details;
    const amount = data.amount;
    const idempotencyKey = data.idempotencyKey;
    const currency = data.currency;
    const customer = data.customer;
    const source = data.source;
    const name = data.name;

    stripe.charges.create({
        amount: amount,
        customer: customer,
        currency: currency,
        description: details,
    },
    function(err, charge) {
        switch (err.type) {
          case 'StripeCardError':
            // A declined card error
            console.log(err.message); // => e.g. "Your card's expiration year is invalid."
            break;
          case 'StripeRateLimitError':
            // Too many requests made to the API too quickly
            console.log(err.message);
            break;
          case 'StripeInvalidRequestError':
            // Invalid parameters were supplied to Stripe's API
            console.log(err.message);
            break;
          case 'StripeAPIError':
            // An error occurred internally with Stripe's API
            console.log(err.message);
            break;
          case 'StripeConnectionError':
            // Some kind of error occurred during the HTTPS communication
            console.log(err.message);
            break;
          case 'StripeAuthenticationError':
            // You probably used an incorrect API key
            console.log(err.message);
            break;
          default:
            // Handle any other types of unexpected errors
            console.log(err.message);
            break;
        }
    });
});


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
        // If the result is successful, write it back to the database
        return snap.ref.set(response, { merge: true });
      } catch(error) {
        // We want to capture errors and render them in a user-friendly way, while
        // still logging an exception with StackDriver
        console.log(error);
        await snap.ref.set({error: userFacingMessage(error)}, { merge: true });
        return reportError(error, {user: context.params.userId});
      }
    });
// [END chargecustomer]]



// To keep on top of errors, we should raise a verbose error report with Stackdriver rather
// than simply relying on console.error. This will calculate users affected + send you email
// alerts, if you've opted into receiving them.
// [START reporterror]
function reportError(err, context = {}) {
  // This is the name of the StackDriver log stream that will receive the log
  // entry. This name can be any valid log stream name, but must contain "err"
  // in order for the error to be picked up by StackDriver Error Reporting.
  const logName = 'errors';
  const log = logging.log(logName);

  // https://cloud.google.com/logging/docs/api/ref_v2beta1/rest/v2beta1/MonitoredResource
  const metadata = {
    resource: {
      type: 'cloud_function',
      labels: {function_name: process.env.FUNCTION_NAME},
    },
  };

  // https://cloud.google.com/error-reporting/reference/rest/v1beta1/ErrorEvent
  const errorEvent = {
    message: err.stack,
    serviceContext: {
      service: process.env.FUNCTION_NAME,
      resourceType: 'cloud_function',
    },
    context: context,
  };

  // Write the error log entry
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

// Sanitize the error message for the user
function userFacingMessage(error) {
  return error.type ? error.message : 'An error occurred, developers have been alerted';
}
