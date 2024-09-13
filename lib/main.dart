import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:galleryimage/galleryimage.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:quarrata_parks/models/park.dart';
import 'package:quarrata_parks/utils.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Quarrata's Parks",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: const Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  void fetchAndPush() {
    allParks().then((parks) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MainApp(parks: parks),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      });
    }).catchError((error) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Errore"),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  fetchAndPush();
                },
                child: const Text("Riprova"),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAndPush();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Image.asset(
            'assets/icon.png',
            width: 90,
            height: 90,
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  final List<Park> parks;
  const MainApp({super.key, required this.parks});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Mappa',
          ),
          NavigationDestination(
            icon: Icon(Icons.info),
            label: 'Informazioni',
          ),
        ],
      ),
      body: <Widget>[
        MapPage(parks: widget.parks),
        const About(),
      ][currentPageIndex],
    );
  }
}

class MapPage extends StatelessWidget {
  final List<Park> parks;
  const MapPage({
    super.key,
    required this.parks,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(
                43.8471,
                10.9772,
              ),
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: "flutter_map",
              ),
              MarkerLayer(
                markers: parks
                    .map(
                      (park) => Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(park.geo.latitude, park.geo.longitude),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParkDetail(park: park),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.location_on,
                            size: 30.0,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              )
            ],
          )
        ],
      ),
    );
  }
}

class ParkDetail extends StatelessWidget {
  final Park park;
  const ParkDetail({
    super.key,
    required this.park,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(park.name),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          MapsLauncher.launchCoordinates(park.geo.latitude, park.geo.longitude);
        },
        child: const Icon(Icons.directions),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          minimum: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 200.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey,
                ),
                clipBehavior: Clip.antiAlias,
                child: AbsorbPointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(park.geo.latitude, park.geo.longitude),
                      initialZoom: 16.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: "flutter_map",
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(park.geo.latitude, park.geo.longitude),
                            child: const Icon(
                              Icons.location_on,
                              size: 30.0,
                              color: Colors.red,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              const Text("Dettagli", style: TextStyle(fontSize: 20.0)),
              Text(park.description),
              const SizedBox(height: 10.0),
              if (park.dangers.isNotEmpty) ...[
                const Text("Pericoli trovati", style: TextStyle(fontSize: 20.0)),
                const SizedBox(height: 10.0),
                GalleryImage(
                  imageUrls: park.dangers.map((e) => '$cloudFlareR2URL/dangers/$e').toList(),
                  titleGallery: "Pericoli in ${park.name}",
                  numOfShowImages: park.dangers.length > 3 ? 3 : park.dangers.length,
                  showListInGalley: true,
                ),
              ],
              const SizedBox(height: 15.0),
            ],
          ),
        ),
      ),
    );
  }
}

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        child: SafeArea(
          minimum: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text("Quarrata's Parks", style: TextStyle(fontSize: 20.0)),
              SizedBox(height: 10.0),
              Text("Questa applicazione mostra i parchi di Quarrata e i pericoli che si possono trovare al loro interno."),
              SizedBox(height: 100.0),
              Text("Sviluppata da:"),
              SizedBox(height: 10.0),
              Text("Filippo Melani"),
              SizedBox(height: 10.0),
              Text("Iacopo Melani"),
              SizedBox(height: 10.0),
              Text("Claudio Melani"),
              SizedBox(height: 10.0),
              Text("Letizia Lunardi"),
              SizedBox(height: 50.0),
              Text("Versione 1.0.0"),
              SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
