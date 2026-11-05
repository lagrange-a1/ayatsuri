import 'dart:io';

import 'package:ayatsuri/proxies/country_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

/// A square "country" XX spanning lng [170, 190] (crossing the
/// antimeridian), lat [-10, 10], with a square hole [178, 182] x [-2, 2].
const _synthetic = '''
{"type": "FeatureCollection", "features": [{
  "type": "Feature",
  "properties": {"ADMIN": "Testland", "ISO_A2": "XX"},
  "geometry": {"type": "Polygon", "coordinates": [
    [[170, -10], [179, -10], [-179, -10], [-170, -10], [-170, 10], [-179, 10], [179, 10], [170, 10], [170, -10]],
    [[178, -2], [182, -2], [182, 2], [178, 2], [178, -2]]
  ]}
}]}
''';

void main() {
  test('synthetic: inside, antimeridian, hole, outside', () {
    final shapes = parseCountryShapes(_synthetic);
    expect(shapes.shapes, hasLength(1));
    expect(shapes.alpha2At(0, 175), 'XX');
    expect(shapes.alpha2At(0, -175), 'XX'); // across the antimeridian
    expect(shapes.alpha2At(0, 180), isNull); // inside the hole
    expect(shapes.alpha2At(-1, -179), isNull); // hole across the antimeridian
    expect(shapes.alpha2At(0, 185), 'XX'); // past the hole, still inside
    expect(shapes.alpha2At(5, 180), 'XX'); // above the hole
    expect(shapes.alpha2At(0, 0), null);
    expect(shapes.alpha2At(20, 175), null);
    final centroid = shapes.centroidFor('XX');
    expect(centroid, isNotNull);
    expect(shapes.centroidFor('ZZ'), isNull);
  });

  test('real bundled GeoJSON: known cities resolve', () {
    final text = File('assets/globe/countries.geojson').readAsStringSync();
    final shapes = parseCountryShapes(text);
    expect(shapes.shapes.length, greaterThanOrEqualTo(170));
    expect(shapes.alpha2At(35.68, 139.69), 'JP'); // Tokyo
    expect(shapes.alpha2At(48.85, 2.35), 'FR'); // Paris
    expect(shapes.alpha2At(40.71, -74.0), 'US'); // New York
    expect(shapes.alpha2At(21.3, -157.8), 'US'); // Honolulu
    expect(shapes.alpha2At(61.2, -149.9), 'US'); // Anchorage
    expect(shapes.alpha2At(-33.87, 151.21), 'AU'); // Sydney
    expect(shapes.alpha2At(55.75, 37.62), 'RU'); // Moscow
    expect(shapes.alpha2At(-26.2, 28.05), 'ZA'); // Johannesburg
    expect(shapes.alpha2At(0, -150), isNull); // Mid-Pacific ocean
    expect(shapes.alpha2At(30, -40), isNull); // Mid-Atlantic ocean
    // Every shape has a sane centroid.
    for (final shape in shapes.shapes) {
      expect(shape.centroidLat, inInclusiveRange(-85, 85));
      expect(shape.centroidLng, inInclusiveRange(-180, 180));
    }
  });
}
