part of '../main.dart';

class SliderEntity extends Entity {
  SliderEntity(Map rawData) : super(rawData);

  double get minValue => _getDoubleAttributeValue("min") ?? 0.0;
  double get maxValue =>_getDoubleAttributeValue("max") ?? 100.0;
  double get valueStep => _getDoubleAttributeValue("step") ?? 1.0;

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