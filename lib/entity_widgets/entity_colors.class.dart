part of '../main.dart';

class EntityColors {
  static const _stateColors = {
    "on": Colors.amber,
    "auto": Colors.amber,
    "idle": Colors.amber,
    "playing": Colors.amber,
    "above_horizon": Colors.amber,
    "home":  Colors.amber,
    "open":  Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "closed": Color.fromRGBO(68, 115, 158, 1.0),
    "below_horizon": Color.fromRGBO(68, 115, 158, 1.0),
    "default": Color.fromRGBO(68, 115, 158, 1.0),
    "heat": Colors.redAccent,
    "cool": Colors.lightBlue,
    "closing": Colors.cyan,
    "opening": Colors.purple,
    "unavailable": Colors.black26,
    "unknown": Colors.black26,
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
      return charts.MaterialPalette.getOrderedPalettes(id+1)[id].shadeDefault;
    }
  }

  static Color historyStateColor(String state, int id) {
    Color c = _stateColors[state];
    if (c != null) {
      return c;
    } else {
      if (id > -1) {
        charts.Color c1 = charts.MaterialPalette.getOrderedPalettes(id + 1)[id].shadeDefault;
        return Color.fromARGB(c1.a, c1.r, c1.g, c1.b);
      } else {
        return _stateColors["default"];
      }
    }
  }

}