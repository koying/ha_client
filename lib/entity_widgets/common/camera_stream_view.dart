part of '../../main.dart';

class CameraStreamView extends StatefulWidget {

  CameraStreamView({Key key}) : super(key: key);

  @override
  _CameraStreamViewState createState() => _CameraStreamViewState();
}

class _CameraStreamViewState extends State<CameraStreamView> {

  @override
  void initState() {
    super.initState();
  }

  CameraEntity _entity;
  bool started = false;

  launchStream() {
    HAUtils.launchURLInCustomTab(context, '${Connection().httpWebHost}/api/camera_proxy_stream/${_entity
        .entityId}?token=${_entity.attributes['access_token']}');
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      _entity = EntityModel
          .of(context)
          .entityWrapper
          .entity;
      started = true;
    }
    return Column(
      children: <Widget>[
        Container(
            padding: const EdgeInsets.all(20.0),
            child: FlatButton(
              child: Text("View camera stream"),
              onPressed: () => launchStream(),
            )
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}