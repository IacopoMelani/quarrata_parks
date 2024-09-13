import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quarrata_parks/utils.dart';

class Park {
  final int id;
  final String name;
  final String address;
  final Geo geo;
  final String description;
  final List<String> dangers; // gestirlo come array di foto

  Park({
    required this.id,
    required this.name,
    required this.address,
    required this.geo,
    required this.description,
    required this.dangers,
  });

  factory Park.fromJson(Map<String, dynamic> json) {
    return Park(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      geo: Geo.fromJson(json['geo']),
      description: json['description'],
      dangers: List<String>.from(json['dangers']),
    );
  }
}

class Geo {
  final double latitude;
  final double longitude;

  Geo({
    required this.latitude,
    required this.longitude,
  });

  factory Geo.fromJson(Map<String, dynamic> json) {
    return Geo(
      latitude: json['lat'],
      longitude: json['lng'],
    );
  }
}

class ParksDTO {
  final List<Park> parks;

  ParksDTO({
    required this.parks,
  });

  factory ParksDTO.fromJson(Map<String, dynamic> json) {
    return ParksDTO(
      parks: List<Park>.from(json['parks'].map((park) => Park.fromJson(park))),
    );
  }
}

Future<List<Park>> allParks() async {
  var response = await http.get(Uri.parse("$cloudFlareR2URL/parks.json"), headers: {});
  if (response.statusCode == 200) {
    return ParksDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes))).parks;
  } else {
    throw ParkException(message: "Impossibile recuperare i parchi.");
  }
}

class ParkException implements Exception {
  final String message;

  ParkException({required this.message});

  @override
  String toString() {
    return message;
  }
}
