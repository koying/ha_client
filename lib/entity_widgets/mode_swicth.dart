part of '../main.dart';

class ModeSwitchWidget extends StatelessWidget {

  final String caption;
  final onChange;
  final double captionFontSize;
  final bool value;

  ModeSwitchWidget({
    Key key,
    @required this.caption,
    @required this.onChange,
    this.captionFontSize,
    this.value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            "$caption",
            style: TextStyle(
                fontSize: captionFontSize ?? Entity.stateFontSize
            ),
          ),
        ),
        Switch(
          onChanged: (value) => onChange(value),
          value: value ?? false,
        )
      ],
    );
  }

}