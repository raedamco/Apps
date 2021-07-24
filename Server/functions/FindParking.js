
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
