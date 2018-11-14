part of '../main.dart';

class EntityColor {

  static const badgeColors = {
    "default": Color.fromRGBO(223, 76, 30, 1.0),
    "binary_sensor": Color.fromRGBO(3, 155, 229, 1.0)
  };

  static const _stateColors = {
    EntityState.on: Colors.amber,
    "auto": Colors.amber,
    EntityState.idle: Colors.amber,
    EntityState.playing: Colors.amber,
    "above_horizon": Colors.amber,
    EntityState.home:  Colors.amber,
    EntityState.open:  Colors.amber,
    EntityState.off: Color.fromRGBO(68, 115, 158, 1.0),
    EntityState.closed: Color.fromRGBO(68, 115, 158, 1.0),
    "below_horizon": Color.fromRGBO(68, 115, 158, 1.0),
    "default": Color.fromRGBO(68, 115, 158, 1.0),
    "heat": Colors.redAccent,
    "cool": Colors.lightBlue,
    EntityState.unavailable: Colors.black26,
    EntityState.unknown: Colors.black26,
  };

  static Color stateColor(String state) {
    return _stateColors[state] ?? _stateColors["default"];
  }

  static charts.Color chartHistoryStateColor(String state, int id) {
    Color c = _stateColors[state];
    if (c != null) {
      return charts.Color(
          r: c.red,
          g: c.green,
          b: c.blue,
          a: c.alpha
      );
    } else {
      double r = id.toDouble() % 10;
      return charts.MaterialPalette.getOrderedPalettes(10)[r.round()].shadeDefault;
    }
  }

  static Color historyStateColor(String state, int id) {
    Color c = _stateColors[state];
    if (c != null) {
      return c;
    } else {
      if (id > -1) {
        double r = id.toDouble() % 10;
        charts.Color c1 = charts.MaterialPalette.getOrderedPalettes(10)[r.round()].shadeDefault;
        return Color.fromARGB(c1.a, c1.r, c1.g, c1.b);
      } else {
        return _stateColors[EntityState.on];
      }
    }
  }

}