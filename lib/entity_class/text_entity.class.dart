part of '../main.dart';

class TextEntity extends Entity {
  String tmpState;
  FocusNode _focusNode;
  bool validValue = false;

  int get valueMinLength => _attributes["min"] ?? -1;
  int get valueMaxLength => _attributes["max"] ?? -1;
  String get valuePattern => _attributes["pattern"] ?? null;
  bool get isTextField => _attributes["mode"] == "text";
  bool get isPasswordField => _attributes["mode"] == "password";

  TextEntity(Map rawData) : super(rawData) {
    _focusNode = FocusNode();
    //TODO possible memory leak generator
    _focusNode.addListener(_focusListener);
    //tmpState = state;
  }

  @override
  void sendNewState(newValue) {
    if (validate(newValue)) {
      eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,
          {"value": "$newValue"}));
    }
  }

  @override
  void update(Map rawData) {
    super.update(rawData);
    tmpState = _state;
  }

  bool validate(newValue) {
    if (newValue is String) {
      //TODO add pattern support
      validValue = (newValue.length >= this.valueMinLength) &&
          (this.valueMaxLength == -1 ||
              (newValue.length <= this.valueMaxLength));
    } else {
      validValue = true;
    }
    return validValue;
  }

  void _focusListener() {
    if (!_focusNode.hasFocus && (tmpState != state)) {
      sendNewState(tmpState);
      tmpState = state;
    }
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    if (this.isTextField || this.isPasswordField) {
      return Container(
        width: Entity.INPUT_WIDTH,
        child: TextField(
            focusNode: inCard ? _focusNode : null,
            obscureText: this.isPasswordField,
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: tmpState,
                    selection:
                    new TextSelection.collapsed(offset: tmpState.length))),
            onChanged: (value) {
              tmpState = value;
            }),
      );
    } else {
      TheLogger.log("Warning", "Unsupported input mode for $entityId");
      return super._buildActionWidget(inCard, context);
    }
  }
}