part of '../../main.dart';

class WeatherForecastWidget extends StatelessWidget {
  
  static const Map<String, String> weatherIcons = const {
      "clear-night": "mdi:weather-night",
      "cloudy": "mdi:weather-cloudy",
      "fog": "mdi:weather-fog",
      "hail": "mdi:weather-hail",
      "lightning": "mdi:weather-lightning",
      "lightning-rainy": "mdi:weather-lightning-rainy",
      "partlycloudy": "mdi:weather-partlycloudy",
      "pouring": "mdi:weather-pouring",
      "rainy": "mdi:weather-rainy",
      "snowy": "mdi:weather-snowy",
      "snowy-rainy": "mdi:weather-snowy-rainy",
      "sunny": "mdi:weather-sunny",
      "windy": "mdi:weather-windy",
      "windy-variant": "mdi:weather-windy-variant",
    };

  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    final WeatherEntity entity = entityModel.entityWrapper.entity;
    //TheLogger.debug("stop: ${entity.supportStop}, seek: ${entity.supportSeek}");
    return Column(
      children: <Widget>[
            Container (child: _buildState(entity), padding: const EdgeInsets.fromLTRB(0.0, Sizes.rowPadding, 0.0, Sizes.rowPadding)),
            Container (child: _buildForecast(entity), padding: const EdgeInsets.fromLTRB(0.0, Sizes.rowPadding, 0.0, Sizes.rowPadding)),
        ],
      );
  }

  Widget _buildState(WeatherEntity entity) {
    TextStyle style = TextStyle(
        fontSize: 12.0,
        color: Colors.black,
        fontWeight: FontWeight.normal,
        height: 1.2
    );
    
    List<Widget> states = [];
    states.add(Icon(
            MaterialDesignIcons.getIconDataFromIconName(weatherIcons[entity.state]),
            size: 75.0,
            color: EntityColor.defaultStateColor,
          )
    );

    states.add(Text(
      "${entity.attributes['temperature']}",
      style: style.apply(fontSizeDelta: 20.0, fontWeightDelta: 50),
    ));

    List<Widget> secondaryStates = [];

    if (entity.attributes['pressure'] != null) {
      secondaryStates.add(Text("Pressure: ${entity.attributes['pressure']}", style: style.apply(color: Colors.grey),));
    }
    if (entity.attributes['humidity'] != null) {
      secondaryStates.add(Text("Humidity: ${entity.attributes['humidity']}", style: style.apply(color: Colors.grey),));
    }
    if (entity.attributes['wind_speed'] != null) {
      secondaryStates.add(Text("Wind speed: ${entity.attributes['wind_speed']}", style: style.apply(color: Colors.grey),));
    }

    states.add(Column(
      children: secondaryStates,
    ));

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: states,
      );
  }

  Widget _buildForecast(WeatherEntity entity) {
    TextStyle style = TextStyle(
        fontSize: 12.0,
        color: Colors.black,
        fontWeight: FontWeight.normal,
        height: 1.2
    );

    if (entity.forecasts.length == 0)
      return null;

    List<Widget> wForecast = [];
    entity.forecasts.forEach((f){
      List<Widget> wForecastElements = [];
      if (f.dow != null) wForecastElements.add(
        Text(
          f.dow,
          style: style.apply(fontWeightDelta: 50),
        ));
      if (f.tod != null) wForecastElements.add(
        Text(
          f.tod,
          style: style.apply(fontWeightDelta: 50),
        ));
      if (f.condition != null) wForecastElements.add(
        Icon(
            MaterialDesignIcons.getIconDataFromIconName(weatherIcons[f.condition]),
            size: 30.0,
            color: EntityColor.defaultStateColor,
        ));
      if (f.temperature != null) wForecastElements.add(
        Text(
          f.temperature.toStringAsFixed(1),
          style: style.apply(fontSizeDelta: 0.0),
        ));
      if (f.temperatureLow != null) wForecastElements.add(
        Text(
          f.temperatureLow.toStringAsFixed(1),
          style: style.apply(fontSizeDelta: 0.0, color: Colors.grey),
        ));
      if (f.precipitation != null) wForecastElements.add(
        Text(
          f.precipitation.toStringAsFixed(1),
          style: style.apply(fontSizeDelta: 0.0, color: Colors.grey),
        ));
      wForecast.add(Column(children: wForecastElements));
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: wForecast,
    );

  }
}