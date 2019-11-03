import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Create a Form widget.
class SubmissionForm extends StatefulWidget {
  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

final _formKey = GlobalKey<FormState>();
const kGoogleApiKey = "AIzaSyDLSCo_z_aTAS4lz3tw4c9ME8aGjtF9MgE";
final databaseReference = Firestore.instance;

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);


// Create a corresponding State class.
// This class holds data related to the form.
class MyCustomFormState extends State<SubmissionForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.

  double lat;
  double lng;
  String restaurantName;
  final _restaurantController = TextEditingController();
  final _offerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
              children: <Widget>[ RaisedButton(
                  onPressed: () async {
                    Prediction p = await PlacesAutocomplete.show(
                        context: context, apiKey: kGoogleApiKey);
                    _restaurantController.text = p.description;
                    restaurantName = p.description.split(',')[0];
                    displayPrediction(p);
                  },

                  child: Text('search for a restaurant')
              ),
                TextField(
                  controller: _restaurantController,
                )
              ]
          ),
          TextFormField(
            decoration: new InputDecoration(hintText: 'Offer description'),
            controller: _offerController,
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: () {

                // Validate returns true if the form is valid, or false
                // otherwise.
                if (_formKey.currentState.validate()) {
                  // If the form is valid, display a Snackbar.
                  Scaffold.of(context)
                      .showSnackBar(SnackBar(content: Text('Sending Offer')));

                  createRecord();
                  _restaurantController.clear();
                  _offerController.clear();
                  Scaffold.of(context)
                      .showSnackBar(SnackBar(content: Text('Thanks!')));
                }
              },
              child: Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<Null> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail =
      await _places.getDetailsByPlaceId(p.placeId);

      var placeId = p.placeId;
      lat = detail.result.geometry.location.lat;
      lng = detail.result.geometry.location.lng;
    }
  }

  void createRecord() async {

    DocumentReference ref = await databaseReference.collection("offers")
        .add({
    'Offer': _offerController.text,
    'Restaurant': restaurantName,
    'Timestamp' : FieldValue.serverTimestamp(),
      'latitute' : lat,
      'longitude' : lng
    });
    print(ref.documentID);
  }
}


