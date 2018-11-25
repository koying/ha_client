part of '../main.dart';

class ButtonEntityContainer extends StatelessWidget {

  ButtonEntityContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;

    return InkWell(
      onTap: () => entityWrapper.handleTap(),
      onLongPress: () => entityWrapper.handleHold(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FractionallySizedBox(
            widthFactor: 0.4,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: EntityIcon(
                padding: EdgeInsets.fromLTRB(2.0, 6.0, 2.0, 2.0),
                iconSize: Sizes.iconSize,
              )
            ),
          ),
          _buildName()
        ],
      ),
    );
  }

  Widget _buildName() {
    return EntityName(
      padding: EdgeInsets.fromLTRB(Sizes.buttonPadding, 0.0, Sizes.buttonPadding, Sizes.rowPadding),
      textOverflow: TextOverflow.ellipsis,
      maxLines: 3,
      wordsWrap: true,
      textAlign: TextAlign.center,
      fontSize: Sizes.nameFontSize,
    );
  }
}