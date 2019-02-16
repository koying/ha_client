part of 'main.dart';

class ConfigurationPage extends StatefulWidget {
  ConfigurationPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ConfigurationPageState createState() => new _ConfigurationPageState();
}

class ConfigurationItem {
  ConfigurationItem({ this.isExpanded: false, this.header, this.body });

  bool isExpanded;
  final String header;
  final Widget body;
}

class _ConfigurationPageState extends State<ConfigurationPage> {

  List<ConfigurationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = <ConfigurationItem>[
      ConfigurationItem(
          header: 'General',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("Server management", style: TextStyle(fontSize: Sizes.largeFontSize)),
                Container(height: Sizes.rowPadding,),
                Text("Control your Home Assistant server from HA Client."),
                Divider(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FlatServiceButton(
                      text: "Restart",
                      serviceName: "restart",
                      serviceDomain: "homeassistant",
                      entityId: null,
                    ),
                    FlatServiceButton(
                      text: "Stop",
                      serviceName: "stop",
                      serviceDomain: "homeassistant",
                      entityId: null,
                    ),
                  ],
                )
              ],
            ),
          )
      )
    ];
  }

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          Navigator.pop(context);
        }),
        title: new Text(widget.title),
      ),
      body: ListView(
        children: [
          new ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _items[index].isExpanded = !_items[index].isExpanded;
              });
            },
            children: _items.map((ConfigurationItem item) {
              return new ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return CardHeaderWidget(
                    name: item.header,
                  );
                },
                isExpanded: item.isExpanded,
                body: new Container(
                  child: item.body,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
