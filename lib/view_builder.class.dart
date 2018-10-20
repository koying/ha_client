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
    return ViewWrapperWidget(
      children: _views
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
      if (en.isGroup) {
        en.childEntities = entityCollection.getAll(en.childEntityIds);
      }
      entitiesForView.add(en);
    });
    userGroupsList["notGroupedEntities"].forEach((entityId){
      entitiesForView.add(entityCollection.get(entityId));
    });
    return View(
      childEntities: entitiesForView,
      count: 0
    );
  }

  List<View> _composeViews() {
    List<View> result = [];
    int counter = 0;
    entityCollection.viewList.forEach((viewId) {
      counter += 1;
      //try {
        Entity viewGroupEntity = entityCollection.get(viewId);
        List<Entity> entitiesForView = [];
        viewGroupEntity.childEntityIds.forEach((
            entityId) { //Each entity or group in view
          if (entityCollection.isExist(entityId)) {
            Entity en = entityCollection.get(entityId);
            if (en.isGroup) {
              en.childEntities = entityCollection.getAll(en.childEntityIds);
            }
            entitiesForView.add(en);
          } else {
            TheLogger.log("Warning", "Unknown entity inside view: $entityId");
          }
        });
        result.add(View(
          count: counter,
          childEntities: entitiesForView
        ));
      /*} catch (error) {
        TheLogger.log("Error","Error parsing view: $viewId");
      }*/
    });
    return result;
  }
}

class ViewWrapperWidget extends StatelessWidget {

  final List<View> children;

  const ViewWrapperWidget({
    Key key,
    this.children
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBarView(
        children: children
    );
  }

}