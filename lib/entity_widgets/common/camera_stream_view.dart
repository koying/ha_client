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
  String _webHost;

  http.Client client;
  http.StreamedResponse response;
  List<int> binaryImage = [];
  bool timeToStop = false;
  Completer streamCompleter;
  bool started = false;
  bool useSVG = false;

  void _connect() async {
    started = true;
    timeToStop = false;
    String streamUrl = '$_webHost/api/camera_proxy_stream/${_entity.entityId}?token=${_entity.attributes['access_token']}';
    client = new http.Client(); // create a client to make api calls
    http.Request request = new http.Request("GET", Uri.parse(streamUrl));  // create get request
    Logger.d("[Sending] ==> $streamUrl");
    response = await client.send(request);
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
              useSVG = contentType == "image/svg+xml";
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
                //Logger.d("content-length: $imageSize");
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
            Logger.d("Camera stream finished. Reconnecting...");
            sink?.close();
            streamCompleter?.complete();
            _reconnect();
          },
        )
    ).listen((d) {
      if (!timeToStop) {
        setState(() {
          binaryImage = d;
        });
      }
    });
  }

  void _reconnect() {
    disconnect().then((_){
      _connect();
    });
  }

  Future disconnect() {
    Completer disconF = Completer();
    timeToStop = true;
    if (streamCompleter != null && !streamCompleter.isCompleted) {
      streamCompleter.future.then((_) {
        client?.close();
        disconF.complete();
      });
    } else {
      client?.close();
      disconF.complete();
    }
    return disconF.future;
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      _entity = EntityModel
          .of(context)
          .entityWrapper
          .entity;
      _webHost = Connection().httpWebHost;
      _connect();
    }

    if (binaryImage.isEmpty) {
      return Column(
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(20.0),
              child: const CircularProgressIndicator()
          )
        ],
      );
    } else {
      if (useSVG) {
        return Column(
          children: <Widget>[
            SvgPicture.memory(
              Uint8List.fromList(binaryImage),
              placeholderBuilder: (BuildContext context) =>
              new Container(
                  padding: const EdgeInsets.all(20.0),
                  child: const CircularProgressIndicator()
              ),
            )
          ],
        );
      } else {
        return Column(
          children: <Widget>[
            Image.memory(
                Uint8List.fromList(binaryImage), gaplessPlayback: true),
          ],
        );
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}