import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:kennzeichen/cache.dart';
import 'package:kennzeichen/database/model.dart';
import 'package:kennzeichen/database/model/gefunden.dart';
import 'package:kennzeichen/database/model/kennzeichen.dart';
import 'package:kennzeichen/main.dart';

class KennzeichenInfo extends StatefulWidget {

  final Kennzeichen kennzeichen;

  const KennzeichenInfo(this.kennzeichen, {super.key});

  @override
  State<StatefulWidget> createState() => _State();

}

class _State extends State<KennzeichenInfo> {

  final Completer<GoogleMapController> mapController = Completer<GoogleMapController>();
  final Completer<LatLng> coordsController = Completer<LatLng>();

  final ExpireCache<String, LatLng> geoCache = ExpireCache(expireDuration: const Duration(days: 1));

  Gefunden? gefunden;

  Kennzeichen get kennzeichen => widget.kennzeichen;

  Future<LatLng?> geocode(String query) async {
    if (geoCache.containsKey(query)) {
      final cached = await geoCache.get(query);
      if (cached != null) {
        return cached;
      }
    }

    final apiKey = dotenv.get("GOOGLE_MAPS_APIKEY");
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?key=$apiKey&address=${Uri.encodeComponent(query)}&language=de"
    );

    Map<String, String> headers = {};
    if (Platform.isAndroid) {
      headers = {
        "X-Android-Package": MyApp.get().platform.packageName,
        "X-Android-Cert": dotenv.get("SHA1_FINGERPRINT").replaceAll(":", ""),
      };
    } else if (Platform.isIOS) {
      headers = {
        "X-Ios-Bundle-Identifier": MyApp.get().platform.packageName,
      };
    }

    final response = await get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final geometry = data["results"][0]["geometry"]["location"];
      final latlng = LatLng(geometry["lat"], geometry["lng"]);

      await geoCache.set(query, latlng);

      return latlng;
    }

    return null;
  }

  Future<Gefunden?> findEntity() async {
    final list = await Model.find(Gefunden(), Gefunden.fromMap,
        where: "kennzeichen_id = ?",
        whereArgs: [kennzeichen.id]);

    return list.isNotEmpty ? list.first : null;
  }

  Future<void> loadCount() async {
    var entity = await findEntity();
    if (entity == null) {
      entity = Gefunden(
        Count: 0,
        KennzeichenId: kennzeichen.id!,
        Timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await Model.insert(entity);

      setState(() {
        findEntity().then((value) => gefunden = value);
      });
    } else {
      setState(() {
        gefunden = entity;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    loadCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(kennzeichen.Kuerzel!),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            nav.pop();

            if (mapController.isCompleted) {
              final controller = await mapController.future;
              controller.dispose();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pin_drop),
            tooltip: "Zu Marker zurückkehren",
            onPressed: () async {
              if (!mapController.isCompleted || !coordsController.isCompleted) {
                return;
              }

              final controller = await mapController.future;
              final latLng = await coordsController.future;
              controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                target: latLng,
                zoom: 11.4746,
              )));
            },
          )
        ],
      ),
      body: kennzeichen.Speziell == null ?
      Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(kennzeichen.Ort ?? kennzeichen.Speziell ?? '…', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(kennzeichen.Bundesland ?? '…'),
              ],
            ),
          ),
          FutureBuilder(
            future: geocode("${kennzeichen.Ort}, ${kennzeichen.Bundesland}, Deutschland"),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var latLng = snapshot.data!;
                if (!coordsController.isCompleted) {
                  coordsController.complete(latLng);
                }

                return SizedBox(
                  // FIXME: Expand ??
                  height: 500,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    compassEnabled: true,
                    trafficEnabled: false,
                    onMapCreated: (controller) => mapController.complete(controller),
                    initialCameraPosition: CameraPosition(
                      target: latLng,
                      zoom: 11.4746, // FIXME: Random?
                    ),
                    markers: {Marker(
                      markerId: const MarkerId("center"),
                      alpha: 1,
                      position: latLng,
                    )},
                  ),
                );
              }

              if (snapshot.hasError) {
                print(snapshot.error);
                return Text(snapshot.error.toString(),
                  style: const TextStyle(color: Colors.red));
              }

              return const LinearProgressIndicator();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Counter: ${gefunden?.Count}", textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  child: const Text("Gesehen!"),
                  onPressed: () {
                    setState(() {
                      gefunden?.Count = (gefunden?.Count ?? 0) + 1;
                      gefunden?.save(Gefunden.fromMap);
                    });

                    final scaffold = ScaffoldMessenger.of(context);
                    scaffold.clearSnackBars();
                    scaffold.showSnackBar(SnackBar(
                      content: Text("${kennzeichen.Kuerzel!} gesehen: ${gefunden?.Count} mal."),
                      duration: Durations.extralong4,
                    ));
                  },
                  onLongPress: () async {
                    final list = await Model.find(Gefunden(), Gefunden.fromMap,
                        where: "kennzeichen_id = ?",
                        whereArgs: [kennzeichen.id]);

                    final count = list.isEmpty ? 0 : list.first.Count;

                    if (context.mounted) {
                      final controller = TextEditingController();

                      controller.value = TextEditingValue(text: count.toString());

                      showAdaptiveDialog(
                        context: context,
                        builder: (context) => AlertDialog.adaptive(
                          icon: const Icon(Icons.edit),
                          title: const Text("Gesehen Counter bearbeiten"),
                          content: TextField(
                            keyboardType: TextInputType.number,
                            controller: controller,

                          ),
                          actions: [
                            TextButton(
                              child: const Text("Speichern"),
                              onPressed: () {},
                            )
                          ],
                        ),
                      ).then((_) => controller.dispose());
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ) :
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sonderkennzeichen", style: theme.textTheme.titleMedium),
            Text(kennzeichen.Speziell!)
          ],
        ),
      ),
    );
  }

}