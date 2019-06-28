part of '../main.dart';

class WeatherForecast {
  String dow;
  String tod;
  double temperature;
  String condition;
  double temperatureLow;
  double precipitation;
}

class WeatherEntity extends Entity {

  static const Map<int, String> dow = const {
    DateTime.sunday: "Sun",
    DateTime.monday: "Mon",
    DateTime.tuesday: "Tue",
    DateTime.wednesday: "Wed",
    DateTime.thursday: "Thu",
    DateTime.friday: "Fri",
    DateTime.saturday: "Sat",
  };

  List<WeatherForecast> get forecasts => getForecasts();
  double get temperature => _getDoubleAttributeValue("temperature");
  int get humidity => _getIntAttributeValue("humidity");
  double get pressure => _getDoubleAttributeValue("pressure");
  double get windSpeed => _getDoubleAttributeValue("wind_speed");

  WeatherEntity(Map rawData, String webHost) : super(rawData, webHost)
  {
    //Logger.d("-- Weather: $rawData");
  }

  @override
  void update(Map rawData, String webHost) {
    super.update(rawData, webHost);

    Logger.d("-- Weather: $rawData");
  }

  List<WeatherForecast> getForecasts() {
    List<WeatherForecast> result = [];
    if (!(attributes['forecast'] != null && attributes['forecast'] is List && attributes['forecast'].isNotEmpty))
      return result;

    var time_formatter = new DateFormat('Hm');

    attributes["forecast"].forEach((f){
      WeatherForecast forecast = new WeatherForecast();
      var datetime = DateTime.tryParse(f["datetime"]);
      if (datetime != null)
      {
        forecast.dow = dow[datetime.toLocal().weekday];
        forecast.tod = datetime.hour != 0 ? time_formatter.format(datetime.toLocal()) : null;
      }
      forecast.temperature = f["temperature"]?.toDouble();
      forecast.condition = f["condition"];
      forecast.temperatureLow = f["templow"]?.toDouble();
      forecast.precipitation = f["precipitation"]?.toDouble();
      result.add(forecast);
    });
    return result;
  }

}
