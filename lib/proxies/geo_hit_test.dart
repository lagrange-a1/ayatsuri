/*
 * Point-in-country lookup over the bundled Natural Earth 110m GeoJSON
 * (`assets/globe/countries.geojson`).
 *
 * The native 3D globe reports taps as (latitude, longitude); this module
 * resolves them to a country alpha-2 by testing the point against the
 * GeoJSON rings. Rings are longitude-unwrapped (consecutive edges wrapped
 * to [-180, 180]) so polygons crossing the antimeridian (Russia, Fiji,
 * USA/Alaska, ...) work, and each polygon uses the even-odd rule across its
 * outer ring + holes.
 */

import 'dart:convert';
import 'dart:math' as math;

import 'country_map.dart';

/// One tappable country: its alpha-2, display name, and label centroid.
class CountryShape {
  const CountryShape({
    required this.alpha2,
    required this.name,
    required this.polygons,
    required this.centroidLat,
    required this.centroidLng,
    required this.minLat,
    required this.maxLat,
  });

  final String alpha2;
  final String name;

  /// Polygons; each polygon is a list of rings (outer first, holes after);
  /// each ring is a list of (lng, lat) pairs with unwrapped longitudes.
  final List<List<List<(double, double)>>> polygons;
  final double centroidLat;
  final double centroidLng;
  final double minLat;
  final double maxLat;

  double get minLng {
    var m = double.infinity;
    for (final polygon in polygons) {
      for (final ring in polygon) {
        for (final p in ring) {
          if (p.$1 < m) m = p.$1;
        }
      }
    }
    return m;
  }

  double get maxLng {
    var m = -double.infinity;
    for (final polygon in polygons) {
      for (final ring in polygon) {
        for (final p in ring) {
          if (p.$1 > m) m = p.$1;
        }
      }
    }
    return m;
  }
}

/// All tappable country shapes parsed from [geojsonText].
class CountryShapes {
  const CountryShapes(this.shapes);

  final List<CountryShape> shapes;

  /// Alpha-2 of the country containing (lat, lng), or null over oceans.
  String? alpha2At(double lat, double lng) {
    if (lat < -90 || lat > 90) return null;
    for (final shape in shapes) {
      if (lat < shape.minLat || lat > shape.maxLat) continue;
      // The ring longitudes are unwrapped, so test the point at ±360 shifts.
      for (final shift in const [0.0, 360.0, -360.0]) {
        final testLng = lng + shift;
        if (testLng < shape.minLng || testLng > shape.maxLng) continue;
        if (_shapeContains(shape, testLng, lat)) return shape.alpha2;
      }
    }
    return null;
  }

  /// Centroid of the named country, for marker placement.
  (double, double)? centroidFor(String alpha2) {
    for (final shape in shapes) {
      if (shape.alpha2 == alpha2) {
        return (shape.centroidLat, shape.centroidLng);
      }
    }
    return null;
  }

  static bool _shapeContains(CountryShape shape, double lng, double lat) {
    for (final polygon in shape.polygons) {
      var containingRings = 0;
      for (final ring in polygon) {
        if (_ringContains(ring, lng, lat)) containingRings++;
      }
      // Even-odd across outer ring + holes.
      if (containingRings.isOdd) return true;
    }
    return false;
  }

  static bool _ringContains(List<(double, double)> ring, double x, double y) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].$1, yi = ring[i].$2;
      final xj = ring[j].$1, yj = ring[j].$2;
      if ((yi > y) != (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// Parse Natural Earth 110m countries GeoJSON text into [CountryShapes].
CountryShapes parseCountryShapes(String geojsonText) {
  final decoded = jsonDecode(geojsonText) as Map<String, dynamic>;
  final features = (decoded['features'] as List<dynamic>?) ?? const [];
  final shapes = <CountryShape>[];
  for (final feature in features) {
    final f = feature as Map<String, dynamic>;
    final props = (f['properties'] as Map<String, dynamic>?) ?? const {};
    final name = (props['ADMIN'] as String?) ?? '';
    final alpha2 = alpha2ForGlobeFeature(
      isoA2: (props['ISO_A2'] as String?) ?? '',
      name: name,
    );
    if (alpha2.isEmpty || alpha2 == '-99') continue;
    final geometry = (f['geometry'] as Map<String, dynamic>?) ?? const {};
    final type = geometry['type'] as String?;
    final coords = geometry['coordinates'] as List<dynamic>?;
    if (coords == null) continue;

    final polygons = <List<List<(double, double)>>>[];
    if (type == 'Polygon') {
      polygons.add(_parsePolygon(coords));
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        polygons.add(_parsePolygon(poly as List<dynamic>));
      }
    } else {
      continue;
    }
    if (polygons.isEmpty) continue;

    var minLat = double.infinity, maxLat = -double.infinity;
    for (final polygon in polygons) {
      for (final ring in polygon) {
        for (final p in ring) {
          if (p.$2 < minLat) minLat = p.$2;
          if (p.$2 > maxLat) maxLat = p.$2;
        }
      }
    }
    final centroid = _centroidOf(polygons);
    shapes.add(
      CountryShape(
        alpha2: alpha2,
        name: name,
        polygons: polygons,
        centroidLat: centroid.$1,
        centroidLng: centroid.$2,
        minLat: minLat,
        maxLat: maxLat,
      ),
    );
  }
  return CountryShapes(shapes);
}

List<List<(double, double)>> _parsePolygon(List<dynamic> rings) {
  final out = <List<(double, double)>>[];
  for (final ring in rings) {
    final points = <(double, double)>[];
    double? prevLng;
    for (final coord in (ring as List<dynamic>)) {
      final pair = coord as List<dynamic>;
      var lng = (pair[0] as num).toDouble();
      final lat = (pair[1] as num).toDouble();
      // Unwrap: keep each edge within ±180 of the previous longitude.
      if (prevLng != null) {
        while (lng - prevLng > 180) {
          lng -= 360;
        }
        while (lng - prevLng < -180) {
          lng += 360;
        }
      }
      prevLng = lng;
      points.add((lng, lat));
    }
    if (points.length >= 4) out.add(points);
  }
  return out;
}

/// Area-weighted centroid of the largest polygon's outer ring, in
/// (lat, lng); falls back to the largest ring's bounding-box center.
/// The lng is normalized back to [-180, 180].
(double, double) _centroidOf(List<List<List<(double, double)>>> polygons) {
  var bestRing = <(double, double)>[];
  var bestArea = -1.0;
  for (final polygon in polygons) {
    if (polygon.isEmpty) continue;
    final ring = polygon.first;
    final area = _ringArea(ring).abs();
    if (area > bestArea) {
      bestArea = area;
      bestRing = ring;
    }
  }
  if (bestRing.isEmpty) return (0, 0);
  var cx = 0.0, cy = 0.0, signedArea = 0.0;
  for (var i = 0; i < bestRing.length - 1; i++) {
    final cross =
        bestRing[i].$1 * bestRing[i + 1].$2 -
        bestRing[i + 1].$1 * bestRing[i].$2;
    signedArea += cross;
    cx += (bestRing[i].$1 + bestRing[i + 1].$1) * cross;
    cy += (bestRing[i].$2 + bestRing[i + 1].$2) * cross;
  }
  signedArea /= 2;
  double lng, lat;
  if (signedArea.abs() < 1e-9) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final p in bestRing) {
      minX = math.min(minX, p.$1);
      maxX = math.max(maxX, p.$1);
      minY = math.min(minY, p.$2);
      maxY = math.max(maxY, p.$2);
    }
    lng = (minX + maxX) / 2;
    lat = (minY + maxY) / 2;
  } else {
    lng = cx / (6 * signedArea);
    lat = cy / (6 * signedArea);
  }
  while (lng > 180) {
    lng -= 360;
  }
  while (lng < -180) {
    lng += 360;
  }
  return (lat.clamp(-85.0, 85.0), lng);
}

double _ringArea(List<(double, double)> ring) {
  var area = 0.0;
  for (var i = 0; i < ring.length - 1; i++) {
    area += ring[i].$1 * ring[i + 1].$2 - ring[i + 1].$1 * ring[i].$2;
  }
  return area / 2;
}
