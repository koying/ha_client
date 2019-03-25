part of '../main.dart';

class Panel {

  static const iconsByComponent = {
    "config": "mdi:settings",
    "history": "mdi:poll-box",
    "map": "mdi:tooltip-account",
    "logbook": "mdi:format-list-bulleted-type",
    "custom": "mdi:home-assistant"
  };

  final String id;
  final String type;
  final String title;
  final String urlPath;
  final Map config;
  String icon;
  bool isHidden = true;

  Panel({this.id, this.type, this.title, this.urlPath, this.icon, this.config}) {
    if (icon == null || !icon.startsWith("mdi:")) {
      icon = Panel.iconsByComponent[type];
    }
    isHidden = (type != "iframe" && type != "config");
  }

  void handleOpen(BuildContext context) {
    if (type == "iframe") {
      Logger.d("Launching custom tab with ${config["url"]}");
      HAUtils.launchURLInCustomTab(context, config["url"]);
    } else if (type == "config") {
      Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PanelPage(title: "$title", panel: this),
          )
      );
    } else {
      HomeAssistantModel haModel = HomeAssistantModel.of(context);
      String url = "${haModel.homeAssistant.connection.httpWebHost}/$urlPath";
      Logger.d("Launching custom tab with $url");
      HAUtils.launchURLInCustomTab(context, url);
    }
  }

  Widget getWidget() {
    switch (type) {
      case "config": {
        return ConfigPanelWidget();
      }

      default: {
        return Text("Unsupported panel component: $type");
      }
    }
  }

}