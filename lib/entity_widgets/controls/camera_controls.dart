part of '../../main.dart';

class CameraControlsWidget extends StatefulWidget {

  final String url;

  CameraControlsWidget({Key key, @required this.url}) : super(key: key);

  @override
  _CameraControlsWidgetState createState() => _CameraControlsWidgetState();
}

class _CameraControlsWidgetState extends State<CameraControlsWidget> {

  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    Logger.d("Camera source: ${widget.url}");
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(widget.url);

    return Center(
      child: _controller.value.initialized
          ? AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      )
          : Container(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}