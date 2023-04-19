import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:codigo6_maps/utils/map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List data = [
    {
      "id": 1,
      "latitude": -8.123123,
      "longitude": -79.005954,
      "image": "https://cdn-icons-png.flaticon.com/512/3882/3882851.png"
    },
    {
      "id": 2,
      "latitude": -8.013920,
      "longitude": -79.005954,
      "image": "https://cdn-icons-png.flaticon.com/512/921/921079.png"
    },
    {
      "id": 3,
      "latitude": -8.113815,
      "longitude": -79.005876,
      "image":
          "https://www.shareicon.net/data/512x512/2016/07/10/119238_hospital_512x512.png"
    },
  ];

  getData() {
    data.forEach(
      (element) async {
        // Marker marker = Marker(
        //   markerId: MarkerId(
        //     myMarkers.length.toString(),
        //   ),
        //   position: LatLng(element["latitude"], element["longitude"]),
        //   icon: BitmapDescriptor.fromBytes(
        //     await getImageMarkerBytes(element["image"], fromInternet: true),
        //   ),
        // );
        // myMarkers.add(marker);
        getImageMarkerBytes(element["image"], fromInternet: true).then((value) {
          Marker marker = Marker(
            markerId: MarkerId(
              myMarkers.length.toString(),
            ),
            position: LatLng(element["latitude"], element["longitude"]),
            icon: BitmapDescriptor.fromBytes(value),
          );
          myMarkers.add(marker);
          setState(() {});
        });
      },
    );
  }

  Set<Marker> myMarkers = {
    Marker(
      markerId: MarkerId("m1"),
      position: LatLng(-8.114092, -79.005316),
    ),
    Marker(
      markerId: MarkerId("m2"),
      position: LatLng(-8.113420, -79.005860),
    ),
  };
  //Los set son una coleccion cuyos elementos no se repiten

  Future<Uint8List> getImageMarkerBytes(String path,
      {bool fromInternet = false, int width = 100}) async {
    late Uint8List bytes;

    if (fromInternet) {
      File file = await DefaultCacheManager().getSingleFile(path);
      bytes = await file.readAsBytes();
    } else {
      ByteData byteData = await rootBundle.load(path);
      bytes = byteData.buffer.asUint8List();
    }

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetHeight: 100,
      targetWidth: width,
    );

    ui.FrameInfo frame = await codec.getNextFrame();
    ByteData? myByteData =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List myBytes = myByteData!.buffer.asUint8List();

    return myBytes;
  }

  // Set<Polyline> myPolylines = {
  //   Polyline(
  //     polylineId: PolylineId("ruta1"),
  //     color: Colors.red,
  //     points: [
  //       LatLng(-8.113383, -79.005816),
  //       LatLng(-8.113689, -79.005787),
  //     ],
  //   ),
  // };

  Set<Polyline> myPolylines = {};
  List<LatLng> _points = [];
  StreamSubscription<Position>? positionStreamSubscription;

  late GoogleMapController googleMapController;

  getCurrentPosition() async {
    // Position position = await Geolocator.getCurrentPosition();
    // print(position);
    // Geolocator.getPositionStream().listen(
    //   (event) {
    //     print(event);
    //   },
    // );
    Polyline route1 = Polyline(
      polylineId: PolylineId("route1"),
      color: Colors.deepPurple,
      width: 3,
      points: _points,
    );
    myPolylines.add(route1);

    BitmapDescriptor myIcon = BitmapDescriptor.fromBytes(
      await getImageMarkerBytes(
        "https://freesvg.org/img/car_topview.png",
        fromInternet: true,
      ),
    );

    Position? positionTemp;
    positionStreamSubscription = Geolocator.getPositionStream().listen(
      (event) {
        LatLng point = LatLng(event.latitude, event.longitude);
        _points.add(point);

        double rotation = 0;

        if (positionTemp != null) {
          rotation = Geolocator.bearingBetween(
            positionTemp!.latitude,
            positionTemp!.longitude,
            event.latitude,
            event.longitude,
          );
        }

        Marker indicator = Marker(
          markerId: MarkerId("IndicatorPosition"),
          position: point,
          icon: myIcon,
          rotation: rotation,
        );
        myMarkers.add(indicator);

        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(point);
        googleMapController.animateCamera(cameraUpdate);

        positionTemp = event;
        setState(() {});
      },
    );
  }

  Future<LatLng> getCurrentPositionInitial() async {
    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
    getCurrentPosition();
  }

  @override
  void dispose() {
    super.dispose();
    positionStreamSubscription!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          CameraUpdate cameraUpdate =
              CameraUpdate.newLatLng(await getCurrentPositionInitial());
          googleMapController.animateCamera(cameraUpdate);
        },
        child: Icon(Icons.location_on),
      ),
      body: FutureBuilder(
        future: getCurrentPositionInitial(),
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.hasData) {
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: snap.data,
                zoom: 18,
              ),
              compassEnabled: true, //funciona con el gps
              myLocationEnabled:
                  false, //funciona con el gps, muestra punto azul de ubicacion
              myLocationButtonEnabled: true, //funciona con el gps

              mapType: MapType.normal, //tipo de mapa que se va a visualizar
              onMapCreated: (GoogleMapController controller) {
                googleMapController = controller;
                googleMapController.setMapStyle(json.encode(mapStyle));
              },
              zoomControlsEnabled: true, // iconos para zoom
              zoomGesturesEnabled: true,
              mapToolbarEnabled: false, // iconos de google maps y rutas
              markers: myMarkers,
              polylines: myPolylines,
              onTap: (LatLng position) async {
                Marker marker = Marker(
                  markerId: MarkerId(myMarkers.length.toString()),
                  position: position,
                  //icon: BitmapDescriptor.defaultMarkerWithHue(
                  //    BitmapDescriptor.hueGreen),
                  // icon: await BitmapDescriptor.fromAssetImage(
                  //   ImageConfiguration(),
                  //   "assets/images/location.png",
                  // ),
                  //icon: BitmapDescriptor.fromBytes(await getImageMarkerBytes("assets/images/location.png")),
                  icon: BitmapDescriptor.fromBytes(
                    await getImageMarkerBytes(
                      "https://cdn-icons-png.flaticon.com/512/1673/1673221.png",
                      fromInternet: true,
                      width: 140,
                    ),
                  ),
                  rotation: 0,
                  draggable: true, //Marcador puede o no ser arrastrado
                  onDrag: (LatLng newPosition) {
                    //Propiedad que controla lo que sucede cuando se arrastra
                    print(newPosition);
                  },
                );
                myMarkers.add(marker);
                setState(() {});
              },
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
