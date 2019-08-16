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
          header: 'Home Assistant Cloud',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/cloud/account");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Integrations',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/integrations/dashboard");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Users',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/users/picker");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'General',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/core");
                  },
                ),
                Container(height: Sizes.rowPadding,),
                Text("Server management", style: TextStyle(fontSize: Sizes.largeFontSize)),
                Container(height: Sizes.rowPadding,),
                Text("Control your Home Assistant server from HA Client."),
                Divider(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FlatButton(
                      child: Text('Restart', style: TextStyle(color: Colors.blue)),
                      onPressed: () => restart(),
                    ),
                    FlatButton(
                      child: Text("Stop", style: TextStyle(color: Colors.blue)),
                      onPressed: () => stop(),
                    ),
                  ],
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Persons',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/person");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Entity Registry',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/entity_registry");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Area Registry',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/area_registry");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Automation',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/automation");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Script',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/script");
                  },
                )
              ],
            ),
          )
      ),
      ConfigurationItem(
          header: 'Customization',
          body: Padding(
            padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, 0.0, Sizes.rightWidgetPadding, Sizes.rowPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Text('Open web version', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    HAUtils.launchURLInCustomTab(context: context, url: Connection().httpWebHost+"/config/customize");
                  },
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
                Text("Here you can manually check if HA Client integration with your Home Assistant works fine. As mobileApp integration in Home Assistant is still in development, this is not 100% correct check."),
                Divider(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FlatButton(
                        onPressed: () => updateRegistration(),
                        child: Text("Check registration", style: TextStyle(color: Colors.blue))
                    ),
                    FlatButton(
                        onPressed: () => resetRegistration(),
                        child: Text("Reset registration", style: TextStyle(color: Colors.red))
                    )
                  ],
                )
              ],
            ),
          )
      )
    ];
  }

  restart() {
    eventBus.fire(ShowDialogEvent(
      title: "Are you sure you want to restart Home Assistant?",
      body: "This will restart your Home Assistant server.",
      positiveText: "Sure. Make it so",
      negativeText: "What?? No!",
      onPositive: () {
        Connection().callService(domain: "homeassistant", service: "restart", entityId: null);
      },
    ));
  }

  stop() {
    eventBus.fire(ShowDialogEvent(
      title: "Are you sure you wanr to STOP Home Assistant?",
      body: "This will STOP your Home Assistant server. It means that your web interface as well as HA Client will not work untill you'll find a way to start your server using ssh or something.",
      positiveText: "Sure. Make it so",
      negativeText: "What?? No!",
      onPositive: () {
        Connection().callService(domain: "homeassistant", service: "stop", entityId: null);
      },
    ));
  }

  updateRegistration() {
    HomeAssistant().checkAppRegistration(showOkDialog: true);
  }

  resetRegistration() {
    eventBus.fire(ShowDialogEvent(
      title: "Waaaait",
      body: "If you don't whant to have duplicate integrations and entities in your HA for your current device, first you need to remove MobileApp integration from Integration settings in HA and restart server.",
      positiveText: "Done it already",
      negativeText: "Ok, I will",
      onPositive: () {
        HomeAssistant().checkAppRegistration(showOkDialog: true, forceRegister: true);
      },
    ));
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
