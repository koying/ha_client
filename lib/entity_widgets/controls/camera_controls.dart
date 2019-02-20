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
    _getData();
  }

  http.Client client;
  http.StreamedResponse response;
  List<int> binaryImage = [];
  String cameraState = "Connecting...";
  bool timeToStop = false;
  Completer streamCompleter;

  void _getData() async {
    client = new http.Client(); // create a client to make api calls
    http.Request request = new http.Request("GET", Uri.parse(widget.url));  // create get request
    Logger.d("[Sending] ==> ${widget.url}");
    response = await client.send(request);
    setState(() {
      cameraState = "Starting...";
    });
    Logger.d("[Received] <== ${response.headers}");
    String frameBoundary = response.headers['content-type'].split('boundary=')[1];
    final int frameBoundarySize = frameBoundary.length;
    List<int> primaryBuffer=[];
    int imageSizeStart = 59;
    int imageSizeEnd = 0;
    int imageStart = 0;
    int imageSize = 0;
    String strBuffer = "";
    String contentType = "";
    streamCompleter = Completer();
    response.stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            primaryBuffer.addAll(data);
            imageStart = 0;
            imageSizeEnd = 0;
            if (primaryBuffer.length >= imageSizeStart + 10) {
              contentType = utf8.decode(
                  primaryBuffer.sublist(frameBoundarySize+16, imageSizeStart + 10), allowMalformed: true).split("\r\n")[0];
              Logger.d("$contentType");
              imageSizeStart = frameBoundarySize + 16 + contentType.length + 18;
              for (int i = imageSizeStart; i < primaryBuffer.length - 4; i++) {
                strBuffer = utf8.decode(
                    primaryBuffer.sublist(i, i + 4), allowMalformed: true);
                if (strBuffer == "\r\n\r\n") {
                  imageSizeEnd = i;
                  imageStart = i + 4;
                  break;
                }
              }
              if (imageSizeEnd > 0) {
                imageSize = int.tryParse(utf8.decode(
                    primaryBuffer.sublist(imageSizeStart, imageSizeEnd),
                    allowMalformed: true));
                Logger.d("content-length: $imageSize");
                if (imageSize != null &&
                    primaryBuffer.length >= imageStart + imageSize + 2) {
                  sink.add(
                      primaryBuffer.sublist(
                          imageStart, imageStart + imageSize));
                  primaryBuffer.removeRange(0, imageStart + imageSize + 2);
                }
              }
            }
            if (timeToStop) {
              sink?.close();
              streamCompleter.complete();
            }
          },
          handleError: (error, stack, sink) {
            Logger.e("Error parsing MJPEG stream: $error");
          },
          handleDone: (sink) {
            sink?.close();
          },
        )
    ).listen((d) {
      setState(() {
        binaryImage = d;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (binaryImage.isEmpty) {
      return Column(
        children: <Widget>[
          Text("$cameraState")
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Image.memory(Uint8List.fromList(binaryImage), gaplessPlayback: true),
        ],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    timeToStop = true;
    if (streamCompleter != null && !streamCompleter.isCompleted) {
      streamCompleter.future.then((_) {
        client?.close();
      });
    } else {
      client?.close();
    }
  }
}