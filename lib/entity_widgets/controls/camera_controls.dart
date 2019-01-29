part of '../../main.dart';

class CameraControlsWidget extends StatefulWidget {

  final String url;

  CameraControlsWidget({Key key, @required this.url}) : super(key: key);

  @override
  _CameraControlsWidgetState createState() => _CameraControlsWidgetState();
}

class _CameraControlsWidgetState extends State<CameraControlsWidget> {

  @override
  void initState() {
    super.initState();
    Logger.d("Camera source: ${widget.url}");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.network(
            "${widget.url}",
        ),
        FlatButton(
          child: Text("VIEW"),
          onPressed: () {
            setState(() {

            });
          },
        )
      ],
    );
    return Image.network("${widget.url}");
    return FlatButton(
      child: Text("VIEW"),
      onPressed: () {
        HAUtils.launchURL(widget.url);
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}