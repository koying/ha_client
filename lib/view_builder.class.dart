part of 'main.dart';

class ViewBuilder{

  EntityCollection entityCollection;
  List<View> _views;

  ViewBuilder({
    Key key,
    this.entityCollection
  }) {
    _compose();
  }

  Widget buildWidget(BuildContext context) {
    return ViewBuilderWidget(
      entities: _views
    );
  }

  void _compose() {
    TheLogger.log("Debug", "Rebuilding all UI...");
    _views = [];
    if (!entityCollection.hasDefaultView) {
      _views.add(_composeDefaultView());
    }
    _views.addAll(_composeViews());
  }

  View _composeDefaultView() {
    Map<String, List<String>> userGroupsList = entityCollection.getDefaultViewTopLevelEntities();
    List<Entity> entitiesForView = [];
    userGroupsList["userGroups"].forEach((groupId){
      Entity en = entityCollection.get(groupId);
      entitiesForView.add(en);
    });
    userGroupsList["notGroupedEntities"].forEach((entityId){
      entitiesForView.add(entityCollection.get(entityId));
    });
    return View(
      entities: entitiesForView,
      count: 0
    );
  }

  List<View> _composeViews() {
    List<View> result = [];
    int counter = 0;
    entityCollection.views.forEach((viewId, viewGroupEntity) {
      counter += 1;
      //try {
        result.add(View(
          count: counter,
          entities: viewGroupEntity.childEntities
        ));
      /*} catch (error) {
        TheLogger.log("Error","Error parsing view: $viewId");
      }*/
    });
    return result;
  }
}

class ViewBuilderWidget extends StatelessWidget {

  final List<View> entities;

  const ViewBuilderWidget({
    Key key,
    this.entities
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBarView(
        children: _buildChildren(context)
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    List<Widget> result = [];
    entities.forEach((View view){
      result.add(view.buildWidget(context));
    });
    return result;
  }

}