part of 'main.dart';

class EntityViewPage extends StatefulWidget {
  EntityViewPage({Key key, this.entity}) : super(key: key);

  Entity entity;

  @override
  _EntityViewPageState createState() => new _EntityViewPageState();
}

class _EntityViewPageState extends State<EntityViewPage> {
  String _title;
  Entity _entity;

  @override
  void initState() {
    super.initState();
    _entity = widget.entity;
    _prepareData();
  }

  _prepareData() async {
    _title = _entity.displayName;
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
        title: new Text(_title),
      ),
      body: Padding(
          padding: EdgeInsets.all(10.0),
          child: ListView(
            children: <Widget>[
              _entity.buildExtendedWidget()
            ],
          ),
      ),
    );
  }
}