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

  void _getData() async {
    client = new http.Client(); // create a client to make api calls
    http.Request request = new http.Request("GET", Uri.parse(widget.url));  // create get request
    Logger.d("[Sending] ==> ${widget.url}");
    response = await client.send(request); // sends request and waits for response stream
    Logger.d("[Received] <== ${response.headers}");
    List<int> primaryBuffer=[];
    int imageSizeStart = 0;
    int imageSizeEnd = 0;
    int imageStart = 0;
    response.stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            primaryBuffer.addAll(data);
            if (primaryBuffer.length >= 40) {
              for (int i = 15; i < primaryBuffer.length - 16; i++) {
                String tmp1 = utf8.decode(
                    primaryBuffer.sublist(i, i + 16), allowMalformed: true);
                if (tmp1 == "Content-Length: ") {
                  imageSizeStart = i + 16;
                  break;
                }
              }
              for (int i = imageSizeStart; i < primaryBuffer.length - 4; i++) {
                String tmp1 = utf8.decode(
                    primaryBuffer.sublist(i, i + 4), allowMalformed: true);
                if (tmp1 == "\r\n\r\n") {
                  imageSizeEnd = i;
                  imageStart = i + 4;
                  break;
                }
              }
              int imageSize = int.tryParse(utf8.decode(
                  primaryBuffer.sublist(imageSizeStart, imageSizeEnd),
                  allowMalformed: true));
              //Logger.d("== imageSize=$imageSize");
              if (primaryBuffer.length >= imageStart + imageSize) {
                sink.add(
                    primaryBuffer.sublist(imageStart, imageStart + imageSize));
                primaryBuffer = primaryBuffer.sublist(imageStart + imageSize);
              }
            }
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (binaryImage.isEmpty) {
      return Text("Loading...");
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
    client.close();
    super.dispose();
  }
}