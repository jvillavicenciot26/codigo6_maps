import 'package:codigo6_maps/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionPage extends StatefulWidget {
  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  checkPermission(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        //Ir a la pagina de inicio
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        break;
      case PermissionStatus.denied:
      case PermissionStatus.limited:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        openAppSettings();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/location2.png",
              height: 220,
            ),
            const Text(
              "Para usar todas las funcionalidades del aplicativo debes de activar el GPS.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 12.0,
            ),
            OutlinedButton(
              onPressed: () async {
                //print(await Permission.location.status);
                PermissionStatus status = await Permission.location.request();
                //print(status);
                checkPermission(status);
              },
              child: const Text(
                "Activar GPS",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
