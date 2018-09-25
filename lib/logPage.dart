part of 'main.dart';

class LogViewPage extends StatefulWidget {
  LogViewPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LogViewPageState createState() => new _LogViewPageState();
}

class _LogViewPageState extends State<LogViewPage> {
  String _hassioDomain = "";
  String _hassioPort = "8123";
  String _hassioPassword = "";
  String _socketProtocol = "wss";
  String _authType = "access_token";
  String _logData;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  _loadLog() async {
    _logData = TheLogger.getLog();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          Navigator.pop(context);
        }),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: () {
              Clipboard.setData(new ClipboardData(text: _logData));
            },
          ),
          IconButton(
            icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:github-circle")),
            onPressed: () {
              String body = "```\n$_logData```";
              String encodedBody = "${Uri.encodeFull(body)}";
              haUtils.launchURL("https://github.com/estevez-dev/ha_client_pub/issues/new?body=$encodedBody");
            },
          ),
        ],
      ),
      body: TextField(
        maxLines: null,

        controller: TextEditingController(
            text: _logData
        ),
      )
    );
  }
}