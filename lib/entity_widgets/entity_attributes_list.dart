part of '../main.dart';

class EntityAttributesList extends StatelessWidget {
  EntityAttributesList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    List<Widget> attrs = [];
    if ((entityModel.entity.attributesToShow == null) ||
        (entityModel.entity.attributesToShow.contains("all"))) {
      entityModel.entity.attributes.forEach((name, value) {
        attrs.add(_buildSingleAttribute("$name", "$value"));
      });
    } else {
      entityModel.entity.attributesToShow.forEach((String attr) {
        String attrValue = entityModel.entity.getAttribute("$attr");
        if (attrValue != null) {
          attrs.add(
              _buildSingleAttribute("$attr", "$attrValue"));
        }
      });
    }
    return Column(
      children: attrs,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
    );
  }

  Widget _buildSingleAttribute(String name, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                Sizes.leftWidgetPadding, Sizes.rowPadding, 0.0, 0.0),
            child: Text(
              "$name",
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                0.0, Sizes.rowPadding, Sizes.rightWidgetPadding, 0.0),
            child: Text(
              "$value",
              textAlign: TextAlign.right,
            ),
          ),
        )
      ],
    );
  }
}