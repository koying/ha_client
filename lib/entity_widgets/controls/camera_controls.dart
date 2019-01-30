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

    _getData();
  }

  http.Client client;
  http.StreamedResponse response;
  List<int> binaryImage = [];

  void _getData() async {
    client = new http.Client(); // create a client to make api calls

    http.Request request = new http.Request("GET", Uri.parse(widget.url));  // create get request
    //Log.d
    Logger.d("==Sending");
    response = await client.send(request); // sends request and waits for response stream
    Logger.d("==Reading");
    int byteCount = 0;
    Logger.d("==${response.headers}");
    List<int> primaryBuffer=[];
    List<int> secondaryBuffer=[];
    int imageStart = 0;
    int imageEnd = 0;
    response.stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            primaryBuffer.addAll(data);
            Logger.d("== data recived: ${data.length}");
            Logger.d("== primary buffer size: ${primaryBuffer.length}");
            //Logger.d("${data.toString()}");
            for (int i = 0; i < primaryBuffer.length - 15; i++) {
              String startBoundary = utf8.decode(primaryBuffer.sublist(i, i+15),allowMalformed: true);
              if (startBoundary == "--frameboundary") {
                Logger.d("== START found at $i");
                imageStart = i;
                //secondaryBuffer.addAll(primaryBuffer.sublist(i));
                //Logger.d("== secondary.length=${secondaryBuffer.length}. clearinig primary");
                //primaryBuffer.clear();
                break;
              }
              /*String startBoundary = utf8.decode(primaryBuffer.sublist(i, i+4),allowMalformed: true);
              if (startBoundary == "\r\n\r\n") {
                Logger.d("==Binary image start found ($i). primary.length=${primaryBuffer.length}");
                secondaryBuffer.addAll(primaryBuffer.sublist(i+5));
                Logger.d("==secondary.length=${secondaryBuffer.length}. clearinig primary");
                primaryBuffer.clear();
                Logger.d("==secondary.length=${secondaryBuffer.length}");
                for (int j = 0; j < secondaryBuffer.length - 15; j++) {
                  String endBoundary = utf8.decode(secondaryBuffer.sublist(j, j+15),allowMalformed: true);
                  if (endBoundary == "--frameboundary") {
                    Logger.d("==Binary image end found");
                    sink.add(secondaryBuffer.sublist(0, j-1));
                    primaryBuffer.addAll(secondaryBuffer.sublist(j));
                    secondaryBuffer.clear();
                    break;
                  }
                }
                break;
              }*/
            }
            for (int i = imageStart+15; i < primaryBuffer.length - 15; i++) {
              String endBoundary = utf8.decode(primaryBuffer.sublist(i, i+15),allowMalformed: true);
              if (endBoundary == "--frameboundary") {
                Logger.d("==END found");
                imageEnd = i;
                sink.add(primaryBuffer.sublist(imageStart, imageEnd - 1));
                primaryBuffer = primaryBuffer.sublist(imageEnd);
                break;
              }
            }
            //byteCount += data.length;
            //Logger.d("$byteCount");

          },
          handleError: (error, stack, sink) {},
          handleDone: (sink) {
            sink.close();
          },
        )
    ).listen((d) {
      setState(() {
        binaryImage = d;
      });
      //Logger.d("==binary imagesize=${d.length}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.memory(Uint8List.fromList(binaryImage)),
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
    client.close();
    super.dispose();
  }
}