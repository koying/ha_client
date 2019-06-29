part of '../main.dart';

class ButtonEntityContainer extends StatelessWidget {

  ButtonEntityContainer({
    Key key,
    @required this.showName,
    @required this.showIcon,
  }) : super(key: key);

  final bool showName;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
    if (entityWrapper.entity.statelessType == StatelessEntityType.MISSED) {
      return MissedEntityWidget();
    }
    if (entityWrapper.entity.statelessType > StatelessEntityType.MISSED) {
      return Container(width: 0.0, height: 0.0,);
    }
    
    List<Widget> widgets = [];
    if (showIcon){
      widgets.add(
          FractionallySizedBox(
            widthFactor: 0.4,
            child: FittedBox(
                fit: BoxFit.fitHeight,
                child: EntityIcon(
                  size: Sizes.iconSize,
                  padding: EdgeInsets.fromLTRB(2.0, 2.0, 2.0, 2.0),
                )
            ),
          )
      );
    }
    if (showName){
      widgets.add(_buildName(showIcon));
    }

    return InkWell(
      onTap: () => entityWrapper.handleTap(),
      onLongPress: () => entityWrapper.handleHold(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widgets
      ),
    );
  }

  Widget _buildName(bool showIcon) {
    return EntityName(
      padding: EdgeInsets.fromLTRB(Sizes.buttonPadding, showIcon ? 0.0 : Sizes.rowPadding, Sizes.buttonPadding, Sizes.rowPadding),
      textOverflow: TextOverflow.ellipsis,
      maxLines: 3,
      wordsWrap: true,
      textAlign: TextAlign.center,
      fontSize: Sizes.nameFontSize,
    );
  }
}