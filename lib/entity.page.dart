part of 'main.dart';

class EntityViewPage extends StatefulWidget {
  EntityViewPage({Key key, @required this.entity, @required this.homeAssistant }) : super(key: key);

  final Entity entity;
  final HomeAssistant homeAssistant;

  @override
  _EntityViewPageState createState() => new _EntityViewPageState();
}

class _EntityViewPageState extends State<EntityViewPage> {
  String _title;
  StreamSubscription _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
      if (event.entityId == widget.entity.entityId) {
        setState(() {});
      }
    });
    _prepareData();
    _getHistory();
  }

  void _prepareData() async {
    _title = widget.entity.displayName;
  }

  void _getHistory() {
   /* widget.homeAssistant.getHistory(widget.entity.entityId).then((List history) {
      if (history != null) {
        
      }
    });*/
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
          child: widget.entity.buildEntityPageWidget(context)
      ),
    );
  }

  @override
  void dispose(){
    if (_stateSubscription != null) _stateSubscription.cancel();
    super.dispose();
  }
}