part of '../main.dart';

class EntityIcon extends StatefulWidget {

  final EdgeInsetsGeometry padding;
  final double size;
  final Color color;

  EntityIcon({Key key, this.padding: const EdgeInsets.fromLTRB(
      Sizes.leftWidgetPadding, 0.0, 12.0, 0.0), this.size: Sizes.iconSize, this.color}) : super(key: key);

  @override
  _EntityIconState createState() => _EntityIconState();
}

class _EntityIconState extends State<EntityIcon> {

  int getDefaultIconByEntityId(String entityId, String deviceClass, String state) {
    String domain = entityId.split(".")[0];
    String iconNameByDomain = MaterialDesignIcons.defaultIconsByDomains["$domain.$state"] ?? MaterialDesignIcons.defaultIconsByDomains["$domain"];
    String iconNameByDeviceClass;
    if (deviceClass != null) {
      iconNameByDeviceClass = MaterialDesignIcons.defaultIconsByDeviceClass["$domain.$deviceClass.$state"] ?? MaterialDesignIcons.defaultIconsByDeviceClass["$domain.$deviceClass"];
    }
    String iconName = iconNameByDeviceClass ?? iconNameByDomain;
    if (iconName != null) {
      return MaterialDesignIcons.iconsDataMap[iconName] ?? 0;
    } else {
      return 0;
    }
  }

  Widget buildIcon(HomeAssistantModel homeAssistantModel, EntityWrapper data, Color color) {
    if (data == null) {
      return Container(width: widget.size, height: widget.size,);
    }
    if ((data.entity.domain == "camera" || data.entity.domain == "media_player") && data.entity.thumbnailBase64 == null) {
      homeAssistantModel.homeAssistant.updateEntityThumbnail(data.entity);
    }
    if (data.entity.thumbnailBase64 != null) {
      return CircleAvatar(
        radius: widget.size/2,
        backgroundColor: Colors.white,
        backgroundImage: MemoryImage(
          Base64Codec().decode(data.entity.thumbnailBase64),
        )
      );
    } else if (data.entity.entityPicture != null && data.entity.domain != "camera" && data.entity.domain != "media_player") {
      return CircleAvatar(
        radius: widget.size/2,
        backgroundColor: Colors.white,
        backgroundImage: CachedNetworkImageProvider(
          "$homeAssistantWebHost${data.entity.entityPicture}",
        ),
      );
    } else {
      String iconName = data.icon;
      int iconCode = 0;
      if (iconName.length > 0) {
        iconCode = MaterialDesignIcons.getIconCodeByIconName(iconName);
      } else {
        iconCode = getDefaultIconByEntityId(data.entity.entityId,
            data.entity.deviceClass, data.entity.state); //
      }
      return Icon(
        IconData(iconCode, fontFamily: 'Material Design Icons'),
        size: widget.size,
        color: color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
    final HomeAssistantModel homeAssistantModel = HomeAssistantModel.of(context);
    return Padding(
      padding: widget.padding,
      child: buildIcon(
          homeAssistantModel,
          entityWrapper,
          widget.color ?? EntityColor.stateColor(entityWrapper.entity.state)
      ),
    );
  }
}