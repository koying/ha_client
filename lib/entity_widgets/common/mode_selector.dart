part of '../../main.dart';

class ModeSelectorWidget extends StatelessWidget {

  final String caption;
  final List<String> options;
  final String value;
  final double captionFontSize;
  final double valueFontSize;
  final double bottomPadding;
  final onChange;

  ModeSelectorWidget({
    Key key,
    this.caption,
    @required this.options,
    this.value,
    @required this.onChange,
    this.captionFontSize,
    this.valueFontSize,
    this.bottomPadding
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("$caption", style: TextStyle(
            fontSize: captionFontSize ?? Sizes.stateFontSize
        )),
        Row(
          children: <Widget>[
            Expanded(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  value: value,
                  iconSize: 30.0,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: valueFontSize ?? Sizes.largeFontSize,
                    color: Colors.black,
                  ),
                  hint: Text("Select ${caption.toLowerCase()}"),
                  items: options.map((String value) {
                    return new DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (mode) => onChange(mode),
                ),
              ),
            )
          ],
        ),
        Container(height: bottomPadding ?? Sizes.rowPadding,)
      ],
    );
  }
}