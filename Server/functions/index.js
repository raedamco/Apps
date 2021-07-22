 /* eslint-disable */
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
// PubSub = require(`@google-cloud/pubsub`);

//Private keys
const stripe = require('stripe')("sk_test_51H0FFyDtW0T37E4P27PEfuEPvDUyGvmkNhInroQ9mAH7sdKzeM0A2hqLEC3advWxPHO0oCMJtHKk7USLmMIqc4aW00RhpYqsgR"); //Secret Key
var slack = require('slack-notify')('https://hooks.slack.com/services/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');
var slackTransactionBot = require('slack-notify')('https://hooks.slack.com/services/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');
//INITIALIZATION END

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//ACCOUNT START
//When a user signs up for bet access, notify slack
exports.checkAccess = functions.https.onRequest(async (req, res) => {
  const Email = req.body.Email;

  try {
      const snapshot = await admin.firestore().collection("Users").doc("Commuters").collection("Users").where('Email', '==', Email).get();
      if (snapshot.empty) {
        console.log('No matching documents.');
        return res.status(200).send({Status: false})
      }

      snapshot.forEach(doc => {
        const betaAccess = doc.data()["Beta Access"];
        if (betaAccess == false) {
          return res.status(200).send({Status: false});
        }else{
          return res.status(200).send({Status: true})
        }
      });
  }catch(error){
      console.log(error)
      res.status(500).end()
  }
});

async function addBetaUser(email, date, res){
  admin.firestore().collection('UsersBeta').doc(email).set({
      Email: email,
      Joined: admin.firestore.Timestamp.fromDate(date),
  });
  slack.send({
      'username': 'User Activity Bot',
      'text': 'New Beta User Signup :tada:',
      'icon_emoji': ':tada:',
      'attachments': [{
        'color': '#6a0dad',
        'fields': [{
              'title': "Email: " + email,
              "value": "Joined: " + date.toUTCString(),
              'short': true
          }]
      }]
  })
  return res.status(200).send({Success: true, Text: "An email will be sent when you have beta access to the Raedam app!"})
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
          'fields': [{
                'title': 'Email: ' + user.email,
                'value': 'Joined: ' + date.toUTCString(),
                'short': true
            }]
        }]
    })

    return
});

// When a user deletes their account, clean up after them and notify slack
exports.removeUser = functions.auth.user().onDelete(async (user) => {
  const snapshot = await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(user.uid).get();
  const snapval = snapshot.data();
  var joined = snapval.Joined.toDate().toUTCString();

  await slack.send({
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

//Add vehicle data to user account upon call
exports.addVehicleData = functions.https.onRequest(async (req, res) => {
    const UID = req.body.UID;
    const VehicleData = req.body.VehicleData;

    try {
        const snapshot = await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).get();
        const snapval = snapshot.data();
        const databaseVehicles = snapval.Vehicles;
        //check if vehicle is already in database before adding, avoiding duplicates
        if (databaseVehicles.indexOf(VehicleData) > -1) {
            res.status(200).send({Success: false})
        } else {
            admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).set({
                Vehicles: admin.firestore.FieldValue.arrayUnion(VehicleData)
            }, {merge: true});
            res.status(200).send({Success: true})
        }
    }catch(error){
        console.log(error)
        res.status(500).end()
    }
});

//Add permit data to user account upon call
exports.addPermitData = functions.https.onRequest(async (req, res) => {
    const UID = req.body.UID;
    const Permit = req.body.PermitData;
    const PermitNumber = req.body.PermitNumber;

    try {
        admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).set({
            Permits: {
                Permit: PermitNumber
            }
        }, {merge: true});
        res.status(200).send({Success: true})
    }catch(error){
        console.log(error)
        res.status(500).end()
    }
});
//ACCOUNT END

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//ROUTE START
//Add permit data to user account upon call
/*
exports.findParking = functions.https.onRequest(async (req, res) => {
    const Occupant = req.body.UID

    var ParkingDetails = {
        Latitude: req.body.Latitude,
        Longitude: req.body.Longitude,
        Name: req.body.Name,
        Organization: req.body.Organization,
        AvailableSpot: [],
        DesigantedSpot: String(),
        Floor: "Floor 2"
    }


    try {
        //Get rest of data from provided data & designate that spot to that UID in the database & make sure that the spots designated meets the user's criteria
        const snapshot = await admin.firestore().collection(ParkingDetails.Organizaiton).doc(ParkingDetails.Name).collection("Floor 2").get().then(function(querySnapshot) {
            querySnapshot.forEach(function(doc) {
                const occupied = doc.data()["Occupancy"].Occupied
                //Get available parking spots
                if (occupied === false) {
                    ParkingDetails.AvailableSpot.push(doc.id);
                }
            });
            return
        }).catch(function(error) {
            console.log("Error getting documents: " + error);
        });
        //get first avaialble spot then update database to designate the spot to them
        ParkingDetails.DesigantedSpot = (ParkingDetails.AvailableSpot[0]).toString()
        // return updateDatabaseOccupant(ParkingDetails.Organizaiton, ParkingDetails.Name, ParkingDetails.Floor, ParkingDetails.DesigantedSpot, Occupant)
    }catch(error){
        console.log(error)
        res.status(500).end()
    }



    async function updateDatabaseOccupant(Organization, Location, Floor, Spot, Occupant){
        await admin.firestore().collection(Organization).doc(Location).collection(Floor).doc(Spot).set({
            Occupancy: {
                Occupant: Occupant
            }
        }, {merge: true});

        res.status(200).send({
            Organizaiton: Organizaiton,
            Location: Location,
            Floor: Floor,
            Spot: Spot
        })
    }
});

exports.cancelParkingRequest = functions.https.onRequest(async (req, res) => {
    const Occupant = req.body.UID

    var ParkingDetails = {
        Location: req.body.Location,
        Name: req.body.Name,
        Organization: req.body.Organization,
        Floor: req.body.Floor,
        Spot: req.body.Spot,
    }

    try {
        await admin.firestore().collection("PSU").doc("Parking Structure 1").collection("Floor 2").doc(ParkingDetails.Spot).set({
            Occupancy: {
                Occupant: String()
            },
        }, {merge: true});
        return res.status(200).send({Status: true})
    }catch(error){
        console.log(error)
        res.status(500).end()
    }

});

//ROUTE END
*/
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//PAYMENTS START
//Client request to start a server timer (Store data in database to start timer), if successful, allow client to start in app timer for user to keep track of cost and time
exports.startPayment = functions.https.onRequest(async (req, res) => {
    const UID = req.body.UID;
    const Lat = Number(req.body.Latitude);
    const Long = Number(req.body.Longitude);
    const Organization = req.body.Organization;
    const Floor = req.body.Floor;
    const Spot = req.body.Spot;
    const Rate = Number(req.body.Rate);
    const CompanyStripeID = req.body.CompanyStripeID
    const TimerStart = new Date();
    const StartLat = Number(req.body.StartLatitude);
    const StartLong = Number(req.body.StartLongitude);

    try {
        await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).collection("History").doc().set({
            Current: true,
            CompanyStripeID: CompanyStripeID,
            Data: {
                "Start Location": new admin.firestore.GeoPoint(StartLat, StartLong),
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

//Send transaction details to client when asking to complete transaction
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

//Final step in transaction: finalize database update and send charge to Stripe
exports.createCharge = functions.https.onRequest(async (req, res) => {
    const TimerEnd = new Date();

    var UserData = {
        Name: String(),
        UID: req.body.UID,
        StripeID: String(),
    }

    var TransactionDetails = {
        IdempotencyKey: req.body.IdempotencyKey,
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
        ClientSecret: String(),
        CompanyStripeID: String()
    }

    try {
        await completeTransaction()
        console.log("trasaction completed successfully")
        res.status(200).send({
            Completed: true,
            ClientSecret: TransactionDetails.ClientSecret
        })
    }catch(error){
        console.log("trasaction did not complete: ", error);
        res.status(500).end()
    }

    async function completeTransaction(){
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
                TransactionDetails.CompanyStripeID = doc.data().CompanyStripeID
            });
            return updateDatabaseDocument();
        }).catch(function(error) {
            console.log("Error getting documents: " + error);
        });
    }

    async function updateDatabaseDocument(){
        TransactionDetails.End = admin.firestore.Timestamp.fromDate(TimerEnd)
        TransactionDetails.Duration = Math.floor(((TransactionDetails.End.toDate() - TransactionDetails.Begin.toDate())/1000)/60)
        TransactionDetails.Amount = parseFloat((TransactionDetails.Duration * TransactionDetails.Rate) * 100)

        await admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").doc(TransactionDetails.DocumentID).set({
            Current: false,
            Duration: {
                End: TransactionDetails.End,
                Minutes: TransactionDetails.Duration,
            },
            Transaction: {
                Amount: (TransactionDetails.Amount/100)
            }
        }, {merge: true});
        return createStripeCharge();
    }

    async function createStripeCharge(){
        try {
            const paymentIntent = await stripe.paymentIntents.create({
              amount: TransactionDetails.Amount,
              currency: TransactionDetails.Currency,
              description: TransactionDetails.Details,
              customer: UserData.StripeID,
              application_fee_amount: parseInt(TransactionDetails.Amount * 0.07),
              transfer_data: {
                destination: TransactionDetails.CompanyStripeID,
              },
            });
            TransactionDetails.ClientSecret = paymentIntent.client_secret
            TransactionDetails.TransactionID = paymentIntent.id
            admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UserData.UID).collection("History").doc(TransactionDetails.DocumentID).set({
                Transaction: {
                    TransactionID: TransactionDetails.TransactionID
                }
            }, {merge: true});

            //Send slack message of new finalized transaction
            await slackTransactionBot.send({
                'username': 'Stripe Bot',
                'text': 'Finalized Transaction :tada:',
                'icon_emoji': ':tada:',
                'attachments': [{
                  'color': '#75FF33',
                  'fields': [{
                        'title': 'Transaction Information',
                        'value': "User ID: " + UserData.UID + "\nTime Finalized: " + TimerEnd.toUTCString() + "\nTransaction Amount: $" + (TransactionDetails.Amount/100) + "\nRevenue: $" + parseFloat((TransactionDetails.Amount * 0.07)/100).toFixed(2),
                        'short': false
                    }]
                }]
            })

        } catch(error) {
            return console.log(error);
        }
      }
    }
});
//PAYMENTS END

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//STRIPE START
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
//STRIPE END



// exports.pubsubcall = functions.pubsub.topic('particle').onPublish(async (message) => {
//   const messageData = Buffer.from(message.data, 'base64').toString();
//   var parsedStringData = messageData.split(",");
//
//   //Parsed values from main unit
//   var company = parsedStringData[0];
//   var location = parsedStringData[1];
//   var floor = parsedStringData[2];
//   var mainUnitNumber = parsedStringData[3];
//   var batteryLevel = parsedStringData[4];
//
//   //Update database from values
//   updateDatabase(company,location,floor,mainUnitNumber,batteryLevel);
// });

async function updateDatabase(company, location, floor, mainUnitNumber, batteryLevel){
  const snapshot = await db.collection('Companies').where("CUID", "==",company).get();
  var fieldName = "Main Units." + mainUnitNumber + ".Battery Level";
  if (snapshot) {
    db.collection("Companies").doc(snapshot.id).collection("Data").doc(location).update({
      fieldName: batteryLevel
    }).catch((err) => {
      console.log("Error updating battery level", err);
    });
  }
}
