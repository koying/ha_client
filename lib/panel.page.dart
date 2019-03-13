part of 'main.dart';

class PanelPage extends StatefulWidget {
  PanelPage({Key key, this.title, this.panel}) : super(key: key);

  final String title;
  final Panel panel;

  @override
  _PanelPageState createState() => new _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {

  List<ConfigurationItem> _items;

  @override
  void initState() {
    super.initState();
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
      body: widget.panel.getWidget(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
