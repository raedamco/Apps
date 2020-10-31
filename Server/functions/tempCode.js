exports.createAccount = functions.https.onRequest(async (req, res) => {
    const Email = req.body.Email;
    const Password = req.body.Password;
    const UserName = req.body.Name;
    const Permits = req.body.Permits;
    const Vehicles = req.body.Vehicles;
    var date = new Date();
    var UID;
    var StripeID;

    try {
        await createAuthAccount()
        res.status(200).send({Success: true, UID: UID, Error: null})
    }catch(error){
        res.status(500).end({Success: true, UID: null, Error: error})
    }

    async function createAuthAccount(){
      admin.auth().createUser({
        email: Email,
        password: Password,
        disabled: false,
      }).then(function(user){
        UID = user.uid;
        return createStripeAccount();
      }).catch(function(error) {
        return console.log('Error creating new user:', error);
      });
    }

    try {
      const customer = await stripe.customers.create({
        email: Email,
        name: UserName
      });
      StripeID = customer.id;

      admin.firestore().collection('Users').doc('Commuters').collection('Users').doc(UID).set({
        UUID: UID,
        Email: Email,
        Joined: admin.firestore.Timestamp.fromDate(date),
        StripeID: StripeID,
        Name: UserName,
        Permits: Permits,
        Vehicles: Vehicles
      }, {merge: true});

      //Send slack message of new user
      await slack.send({
          'username': 'User Activity Bot',
          'text': 'New User Joined :tada:',
          'icon_emoji': ':tada:',
          'attachments': [{
            'color': '#30FCF1',
            'fields': [{
                  'title': 'Joined On',
                  'value': date.toUTCString(),
                  'short': true
              }]
          }]
      })

    } catch(error) {
        return console.log(error);
    }
});
