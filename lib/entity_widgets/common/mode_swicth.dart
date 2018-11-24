part of '../../main.dart';

class ModeSwitchWidget extends StatelessWidget {

  final String caption;
  final onChange;
  final double captionFontSize;
  final bool value;
  final bool expanded;

  ModeSwitchWidget({
    Key key,
    @required this.caption,
    @required this.onChange,
    this.captionFontSize,
    this.value,
    this.expanded: true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildCaption(),
        Switch(
          onChanged: (value) => onChange(value),
          value: value ?? false,
        )
      ],
    );
  }

  Widget _buildCaption() {
    Widget captionWidget = Text(
      "$caption",
      style: TextStyle(
          fontSize: captionFontSize ?? Sizes.stateFontSize
      ),
    );
    if (expanded) {
      return Expanded(
        child: captionWidget,
      );
    }
    return captionWidget;
  }

}