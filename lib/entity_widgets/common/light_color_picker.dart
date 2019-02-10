part of '../../main.dart';

class LightColorPicker extends StatefulWidget {

  final HSVColor color;
  final onColorSelected;
  final double hueStep;
  final double saturationStep;
  final EdgeInsets padding;

  LightColorPicker({this.color, this.onColorSelected, this.hueStep: 15.0, this.saturationStep: 0.2, this.padding: const EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, 0.0)});

  @override
  LightColorPickerState createState() => new LightColorPickerState();
}

class LightColorPickerState extends State<LightColorPicker> {

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colors = [];
    Border border;
    Logger.d("Current colotfor picker: [${widget.color.hue}, ${widget.color.saturation}]");
    for (double saturation = 1.0; saturation >= (0.0 + widget.saturationStep); saturation = double.parse((saturation - widget.saturationStep).toStringAsFixed(2))) {
      List<Widget> rowChildren = [];
      Logger.d("$saturation");
      for (double hue = 0; hue <= (365 - widget.hueStep);
      hue += widget.hueStep) {
        if (widget.color.hue.round() >= hue && widget.color.hue.round() < (hue+widget.hueStep) && widget.color.saturation == saturation) {
          border = Border.all(
            width: 2.0,
            color: Colors.white,
          );
        } else {
          border = null;
        }
        HSVColor currentColor = HSVColor.fromAHSV(1.0, hue, double.parse(saturation.toStringAsFixed(2)), 1.0);
        rowChildren.add(
            Flexible(
                child: GestureDetector(
                  child: Container(
                    height: 40.0,
                    decoration: BoxDecoration(
                        color: currentColor.toColor(),
                        border: border,
                    ),
                  ),
                  onTap: () => widget.onColorSelected(currentColor),
                )
            )
        );
      }
      colors.add(
          Row(
            children: rowChildren,
          )
      );
    }
    colors.add(
        Flexible(
            child: GestureDetector(
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                    color: Colors.white
                ),
              ),
              onTap: () => widget.onColorSelected(HSVColor.fromAHSV(1.0, 30.0, 0.0, 1.0)),
            )
        )
    );
    return Padding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: colors,
      ),
      padding: widget.padding,
    );

  }
}