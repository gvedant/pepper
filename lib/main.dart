// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter_app/submissionform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final Set<WordPair> _saved = Set<WordPair>();
  final TextStyle _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pepper',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal[300]
      ),

      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.access_time), text: 'Most Recent'),
                Tab(icon: Icon(Icons.directions_walk), text: 'Closest'),
                Tab(icon: Icon(Icons.star_border), text: 'Most Upvoted'),
              ],
            ),
            title: Text('pepper.', style: TextStyle(fontSize: 30.0),),
            centerTitle: true,
//            actions: <Widget>[
//            IconButton(icon: Icon(Icons.add), onPressed: _submitOffer),
//            ],
          ),
          body: TabBarView(
            children: [
              RandomWords(0),
              RandomWords(1),
              RandomWords(2),
            ],
          ),
        ),
      ),
    );
  }

//  void _submitOffer() {
//    Navigator.of(context).push(
//        MaterialPageRoute<void> (
//            builder: (BuildContext context) {
//              final Iterable<ListTile> tiles = _saved.map(
//                      (WordPair pair) {
//                    return ListTile(
//                        title: Text(
//                          pair.asPascalCase,
//                          style: _biggerFont,
//                        )
//                    );
//                  }
//              );
//              final List<Widget> divided = ListTile
//                  .divideTiles(
//                  context: context,
//                  tiles: tiles
//              )
//                  .toList();
//
//              return Scaffold(
//                  appBar: AppBar(
//                    title: Text('Submit an Offer'),
//                  ),
//                  body: SubmissionForm()
//              );
//            }
//        )
//    );
//  }
}

class RandomWords extends StatefulWidget {
  int state;
  RandomWords(int state) : state = state;

  @override
  RandomWordsState createState() => RandomWordsState(state);
}

class RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final Set<WordPair> _saved = Set<WordPair>();
  final TextStyle _biggerFont = const TextStyle(fontSize: 18.0);
  Location location = Location();
  Map<String, double> userLocation;
  int state;

  RandomWordsState(int state) : state = state;

  Widget _buildRow(WordPair pair) {
    final bool alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if(alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }

  Widget _buildListItem(BuildContext context, Offer offer, DateTime curr) {
    return Padding(
      key: ValueKey(offer.restaurant),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(offer.offer),
          subtitle: Text(offer.restaurant + "   " + offer.distance.toStringAsFixed(2) + " mi"),
          trailing: Text(offer.getTime(curr.difference(offer.dateTime).inSeconds)),
        ),
      ),
    );
  }

  Offer calc_distance(DocumentSnapshot sp) {
    if(userLocation == null) return Offer.fromSnapshot(sp, -1);
    print(userLocation['latitude']);
    print(userLocation['longitude']);
    final Distance distance = Distance(); // 36.143284, -86.805711
    final double miles = 0.000621371*distance(new LatLng(userLocation['latitude'], userLocation['longitude']),
        new LatLng(sp.data['latitute'], sp.data['longitude']));
    return Offer.fromSnapshot(sp, miles);
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<Offer> offers = snapshot.map((data) => calc_distance(data)).toList();
    if(state == 1) { // Want sorted by distance
      offers.sort((a,b) => a.distance.compareTo(b.distance));
    }

    final DateTime curr = DateTime.now();

    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: offers.map((data) => _buildListItem(context, data, curr)).toList(),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('offers').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents.reversed.toList());
      },
    );
  }

  void _submitOffer() {
    Navigator.of(context).push(
      MaterialPageRoute<void> (
        builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _saved.map(
              (WordPair pair) {
                return ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  )
                );
              }
          );
          final List<Widget> divided = ListTile
              .divideTiles(
                context: context,
                tiles: tiles
              )
              .toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('submit an offer'),
            ),
            body: SubmissionForm()
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    // update user's location when state changes
    _getLocation().then((value) {
        userLocation = value;
    });

    return Scaffold(
//      appBar: AppBar(
//        title: Text('pepper.'),
//        actions: <Widget>[
//          IconButton(icon: Icon(Icons.add), onPressed: _submitOffer),
//        ],
//      ),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add),
          onPressed: _submitOffer, backgroundColor: Colors.teal[300], foregroundColor: Colors.white),
      body: _buildBody(context),
    );
  }

  Future<Map<String, double>> _getLocation() async {
    var currentLocation;
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }
}

class Offer {
  final String restaurant;
  final String offer;
  final DateTime dateTime;
  final double distance;

  Offer.fromSnapshot(DocumentSnapshot snapshot, double d)
    : restaurant = snapshot.data['Restaurant'],
      offer = snapshot.data['Offer'],
      dateTime = snapshot.data['Timestamp'].toDate(),
      distance = d;

  String getTime(int seconds) {
    if (seconds < 60) {
      if (seconds < 1) {
        return "Just now";
      }
      else if (seconds == 1) {
        return "1 second";
      }
      return seconds.toString() + " seconds";
    }

    else if (seconds < 3600) {
      int min = (seconds / 60).round();
      if (min == 1) {
        return "1 minute";
      }
      return (seconds / 60).round().toString() + " minutes";
    }

    else if (seconds < 86400) {
      int hours = (seconds / 3600).round();
      if (hours == 1) {
        return "1 hour";
      }
      return (seconds / 3600).round().toString() + " hours";
    }

    else if (seconds < 1209600) {
      int days = (seconds / 86400).round();
      if (days == 1) {
        return "1 day";
      }
      return (seconds / 86400).round().toString() + " days";
    }

    else {
      return "14+ days";
    }
  }
}
