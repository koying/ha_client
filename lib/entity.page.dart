part of 'main.dart';

class EntityViewPage extends StatefulWidget {
  EntityViewPage({Key key, @required this.entityId, @required this.homeAssistant }) : super(key: key);

  final String entityId;
  final HomeAssistant homeAssistant;

  @override
  _EntityViewPageState createState() => new _EntityViewPageState();
}

class _EntityViewPageState extends State<EntityViewPage> {
  String _title;
  StreamSubscription _refreshDataSubscription;
  StreamSubscription _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
      Logger.d("State change event handled by entity page: ${event.entityId}");
      if (event.entityId == widget.entityId) {
        setState(() {});
      }
    });
    _refreshDataSubscription = eventBus.on<RefreshDataFinishedEvent>().listen((event) {
      setState(() {});
    });
    _prepareData();
  }

  void _prepareData() async {
    _title = widget.homeAssistant.entities.get(widget.entityId).displayName;
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
      body: HomeAssistantModel(
          homeAssistant: widget.homeAssistant,
          child: widget.homeAssistant.entities.get(widget.entityId).buildEntityPageWidget(context)
      ),
    );
  }

  @override
  void dispose(){
    if (_stateSubscription != null) _stateSubscription.cancel();
    if (_refreshDataSubscription != null) _refreshDataSubscription.cancel();
    super.dispose();
  }
}