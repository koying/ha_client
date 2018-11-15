part of '../main.dart';

class EntityName extends StatelessWidget {

  final EdgeInsetsGeometry padding;
  final TextOverflow textOverflow;
  final bool wordsWrap;
  final double fontSize;
  final TextAlign textAlign;

  const EntityName({Key key, this.padding: const EdgeInsets.only(right: 10.0), this.textOverflow: TextOverflow.ellipsis, this.wordsWrap: true, this.fontSize: Sizes.nameFontSize, this.textAlign: TextAlign.left}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: padding,
        child: Text(
          "${entityModel.entity.displayName}",
          overflow: textOverflow,
          softWrap: wordsWrap,
          style: TextStyle(fontSize: fontSize),
          textAlign: textAlign,
        ),
      ),
      onTap: () =>
      entityModel.handleTap
          ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
          : null,
    );
  }
}