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

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  _loadLog() async {
    //
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
      ),
      body: TextField(
        maxLines: null,

        controller: TextEditingController(
            text: TheLogger.getLog()
        ),
      )
    );
  }
}