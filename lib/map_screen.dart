import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lee_map_view/location.dart';

import 'progress_hud.dart';
import 'utils/google_place_util.dart';
import 'utils/map_util.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => new _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    implements ScreenListener, GooglePlacesListener {
  MapUtil mapUtil;
  String locationAddress = "Search destination";
  String myLocation = "";
  GooglePlaces googlePlaces;
  bool _isLoading = false;
  double _destinationLat;
  double _destinationLng;

  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14.4746,
  );
  Map<PolylineId, Polyline> polylines = {};
  Position _currentPosition;


  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();


  @override
  void initState() {
    super.initState();
    mapUtil = new MapUtil(this);
    mapUtil.init();
    googlePlaces = new GooglePlaces(this);
    _getCurrentLocation();
  }

  @override
  selectedLocation(double lat, double lng, String address) {
    setState(() {
      _destinationLat = lat;
      _destinationLng = lng;
      locationAddress = address;

    });
    _getPolyline();
  }

  _addPolyLine() {
    polylines.clear();
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var screenWidget = new Column(
      children: <Widget>[
        new GestureDetector(
          onTap: () {
            googlePlaces.findPlace(context);
          },
          child: new Container(
            alignment: FractionalOffset.center,
            margin: EdgeInsets.all(10.0),
            padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
            decoration: new BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 1.0),
              border: Border.all(color: const Color(0x33A6A6A6)),
              borderRadius: new BorderRadius.all(const Radius.circular(6.0)),
            ),
            child: new Row(
              children: <Widget>[
                new Icon(Icons.search),
                new Flexible(
                  child: new Container(
                    padding: new EdgeInsets.only(right: 13.0),
                    child: new Text(
                      locationAddress,
                      overflow: TextOverflow.ellipsis,
                      style: new TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        new Container(
          height: 230.0,
          child: new Stack(
            children: <Widget>[
              new   GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                myLocationEnabled: true,
                polylines: Set<Polyline>.of(polylines.values),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
              new GestureDetector(
                onTap: () => mapUtil.showMap(),
                child: new Center(
                  child: new Image.network(mapUtil.getStaticMap().toString()),
                ),
              ),
            ],
          ),
        ),
        new Container(
          margin: new EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
          padding: new EdgeInsets.only(top: 10.0),
          child: new Text(
            myLocation,
            style: new TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        new GestureDetector(
          onTap: () => getMapRoute(),
          child: new Container(
            margin: EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 0.0),
            padding: EdgeInsets.all(15.0),
            alignment: FractionalOffset.center,
            decoration: new BoxDecoration(
              color: const Color(0xFFFFD900),
              borderRadius: new BorderRadius.all(const Radius.circular(6.0)),
            ),
            child: Text(
              "Draw Route",
              style: new TextStyle(
                  color: const Color(0xFF28324E),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );

    return new Scaffold(
      backgroundColor: const Color(0xFFA6AFAA),
      appBar: AppBar(
        title: new Text(
          "Google maps route",
          textAlign: TextAlign.center,
          style: new TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ProgressHUD(
        child: new SingleChildScrollView(
          child: screenWidget,
        ),
        inAsyncCall: _isLoading,
        opacity: 0.0,
      ),
    );
  }

  Widget getTextField(
      String inputBoxName, TextEditingController inputBoxController) {
    var loginBtn = new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new TextFormField(
        controller: inputBoxController,
        decoration: new InputDecoration(
          hintText: inputBoxName,
        ),
      ),
    );

    return loginBtn;
  }

  Widget getButton(String buttonLabel, EdgeInsets margin) {
    var staticMapBtn = new Container(
      margin: margin,
      padding: EdgeInsets.all(8.0),
      alignment: FractionalOffset.center,
      decoration: new BoxDecoration(
        color: const Color(0xFF167F67),
        border: Border.all(color: const Color(0xFF28324E)),
        borderRadius: new BorderRadius.all(const Radius.circular(6.0)),
      ),
      child: new Text(
        buttonLabel,
        style: new TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: 20.0,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
        ),
      ),
    );
    return staticMapBtn;
  }

  updateStaticMap() {
    setState(() {});
  }

  @override
  updateScreen(Location location) {
    myLocation = "You are at: " +
        location.latitude.toString() +
        ", " +
        location.longitude.toString();
    googlePlaces.updateLocation(location.latitude, location.longitude);
    setState(() {});
  }

  getMapRoute() {
    setState(() {
      _isLoading = true;
    });
    mapUtil.getDirectionSteps(_destinationLat, _destinationLng);
  }

  @override
  dismissLoader() {
    setState(() {
      _isLoading = false;
    });
  }

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        _updatePosition(_currentPosition);
      });
    }).catchError((e) {
      print(e);
    });
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        "AIzaSyAPV3djPp_HceZIbgK4M4jRadHA-d08ECg",
        PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
        PointLatLng(_destinationLat, _destinationLng),
        travelMode: TravelMode.driving
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

  Future<void> _updatePosition(Position currentPosition) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(currentPosition.latitude, currentPosition.longitude),
      zoom: 14.4746,
    )));
    googlePlaces.updateLocation(currentPosition.latitude, currentPosition.longitude);
  }
}

abstract class ScreenListener {
  updateScreen(Location location);
  dismissLoader();
}
