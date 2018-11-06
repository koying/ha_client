part of '../../main.dart';

class CoverControlWidget extends StatefulWidget {

  CoverControlWidget({Key key}) : super(key: key);

  @override
  _CoverControlWidgetState createState() => _CoverControlWidgetState();
}

class _CoverControlWidgetState extends State<CoverControlWidget> {

  double _tmpPosition = 0.0;
  double _tmpTiltPosition = 0.0;
  bool _changedHere = false;

  void _setNewPosition(CoverEntity entity, double position) {
    setState(() {
      _tmpPosition = position.roundToDouble();
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_cover_position", entity.entityId,{"position": _tmpPosition.round()}));
    });
  }

  void _setNewTiltPosition(CoverEntity entity, double position) {
    setState(() {
      _tmpTiltPosition = position.roundToDouble();
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_cover_tilt_position", entity.entityId,{"tilt_position": _tmpTiltPosition.round()}));
    });
  }

  void _resetVars(CoverEntity entity) {
    _tmpPosition = entity.currentPosition;
    _tmpTiltPosition = entity.currentTiltPosition;
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final CoverEntity entity = entityModel.entity;
    if (_changedHere) {
      _changedHere = false;
    } else {
      _resetVars(entity);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(Entity.leftWidgetPadding, Entity.rowPadding, Entity.rightWidgetPadding, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPositionControls(entity),
          _buildTiltControls(entity)
        ],
      ),
    );
  }

  Widget _buildPositionControls(CoverEntity entity) {
    if (entity.supportSetPosition) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
                0.0, Entity.rowPadding, 0.0, Entity.rowPadding),
            child: Text("Position", style: TextStyle(
                fontSize: Entity.stateFontSize
            )),
          ),
          Slider(
            value: _tmpPosition,
            min: 0.0,
            max: 100.0,
            divisions: 10,
            onChanged: (double value) {
              setState(() {
                _tmpPosition = value.roundToDouble();
                _changedHere = true;
              });
            },
            onChangeEnd: (double value) => _setNewPosition(entity, value),
          ),
          Container(height: Entity.rowPadding,)
        ],
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildTiltControls(CoverEntity entity) {
    List<Widget> controls = [];
    if (entity.supportCloseTilt || entity.supportOpenTilt || entity.supportStopTilt) {
      controls.add(
          CoverTiltControlsWidget()
      );
    }
    if (entity.supportSetTiltPosition) {
      controls.addAll(<Widget>[
        Slider(
          value: _tmpTiltPosition,
          min: 0.0,
          max: 100.0,
          divisions: 10,
          onChanged: (double value) {
            setState(() {
              _tmpTiltPosition = value.roundToDouble();
              _changedHere = true;
            });
          },
          onChangeEnd: (double value) => _setNewTiltPosition(entity, value),
        ),
        Container(height: Entity.rowPadding,)
      ]);
    }
    if (controls.isNotEmpty) {
      controls.insert(0, Padding(
        padding: EdgeInsets.fromLTRB(
            0.0, Entity.rowPadding, 0.0, Entity.rowPadding),
        child: Text("Tilt position", style: TextStyle(
            fontSize: Entity.stateFontSize
        )),
      ));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controls,
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

}

class CoverTiltControlsWidget extends StatelessWidget {
  void _open(CoverEntity entity) {
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "open_cover_tilt", entity.entityId, null));
  }

  void _close(CoverEntity entity) {
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "close_cover_tilt", entity.entityId, null));
  }

  void _stop(CoverEntity entity) {
    eventBus.fire(new ServiceCallEvent(
        entity.domain, "stop_cover_tilt", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final CoverEntity entity = entityModel.entity;
    List<Widget> buttons = [];
    if (entity.supportOpenTilt) {
      buttons.add(IconButton(
          icon: Icon(
            MaterialDesignIcons.createIconDataFromIconName(
                "mdi:arrow-top-right"),
            size: Entity.iconSize,
          ),
          onPressed: entity.canTiltBeOpened ? () => _open(entity) : null));
    } else {
      buttons.add(Container(
        width: Entity.iconSize + 20.0,
      ));
    }
    if (entity.supportStopTilt) {
      buttons.add(IconButton(
          icon: Icon(
            MaterialDesignIcons.createIconDataFromIconName("mdi:stop"),
            size: Entity.iconSize,
          ),
          onPressed: () => _stop(entity)));
    } else {
      buttons.add(Container(
        width: Entity.iconSize + 20.0,
      ));
    }
    if (entity.supportCloseTilt) {
      buttons.add(IconButton(
          icon: Icon(
            MaterialDesignIcons.createIconDataFromIconName(
                "mdi:arrow-bottom-left"),
            size: Entity.iconSize,
          ),
          onPressed: entity.canTiltBeClosed ? () => _close(entity) : null));
    } else {
      buttons.add(Container(
        width: Entity.iconSize + 20.0,
      ));
    }

    return Row(
      children: buttons,
    );
  }
}