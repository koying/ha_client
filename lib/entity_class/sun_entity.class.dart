part of '../main.dart';

class SunEntity extends Entity {
  SunEntity(Map rawData) : super(rawData);
}

class SliderEntity extends Entity {
  SliderEntity(Map rawData) : super(rawData);

  double get minValue => attributes["min"] ?? 0.0;
  double get maxValue => attributes["max"] ?? 100.0;
  double get valueStep => attributes["step"] ?? 1.0;
  double get doubleState => double.tryParse(state) ?? 0.0;

  @override
  Widget _buildStatePart(BuildContext context) {
    return Expanded(
      //width: 200.0,
      child: Row(
        children: <Widget>[
          SliderStateWidget(
            expanded: true,
          ),
          SimpleEntityState(),
        ],
      ),
    );
  }

  @override
  Widget _buildStatePartForPage(BuildContext context) {
    return SimpleEntityState();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return SliderStateWidget(
      expanded: false,
    );
  }
}