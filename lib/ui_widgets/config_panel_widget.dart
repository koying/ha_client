part of '../main.dart';

class ConfigPanelWidget extends StatefulWidget {
  ConfigPanelWidget({Key key}) : super(key: key);

  @override
  _ConfigPanelWidgetState createState() => new _ConfigPanelWidgetState();
}

class ConfigurationItem {
  ConfigurationItem({ this.isExpanded: false, this.header, this.body });

  bool isExpanded;
  final String header;
  final Widget body;
}

class _ConfigPanelWidgetState extends State<ConfigPanelWidget> {

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
      ),
      ConfigurationItem(
          header: 'Mobile app',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("Registration", style: TextStyle(fontSize: Sizes.largeFontSize)),
                Container(height: Sizes.rowPadding,),
                Text("${HomeAssistant().userName}'s ${Device().model}, ${Device().osName} ${Device().osVersion}"),
                Container(height: 6.0,),
                Text("Reseting mobile app registration will not remove integration from Home Assistant but creates a new one with different device. If you want to reset mobile app registration completally you need to remove MobileApp from Configuretion -> Integrations of your Home Assistant."),
                Divider(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FlatButton(
                        onPressed: () => resetRegistration(),
                        child: Text("Reset registration")
                    ),
                    FlatButton(
                        onPressed: () => updateRegistration(),
                        child: Text("Update registration")
                    )
                  ],
                )
              ],
            ),
          )
      )
    ];
  }

  resetRegistration() {
    HomeAssistant().checkAppRegistration(forceRegister: true).then((_) {
      Navigator.of(context).pop();
      eventBus.fire(ShowDialogEvent(
        title: "App registered",
        body: "To start using notifications you need to restart your Home Assistant",
        positiveText: "Restart now",
        negativeText: "Later",
        onPositive: () {
          Connection().callService(domain: "homeassistant", service: "restart", entityId: null);
        },
      ));
    });
  }

  updateRegistration() {
    HomeAssistant().checkAppRegistration().then((_) {
      //Navigator.of(context).pop();
      /*eventBus.fire(ShowDialogEvent(
        title: "App registration updated",
        body: "To start using notifications you need to restart your Home Assistant",
        positiveText: "Restart now",
        negativeText: "Later",
        onPositive: () {
          Connection().callService(domain: "homeassistant", service: "restart", entityId: null);
        },
      ));*/
    });
  }

  @override
  Widget build(BuildContext context) {

    return ListView(
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
