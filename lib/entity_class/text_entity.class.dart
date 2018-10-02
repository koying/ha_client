part of '../main.dart';

class _TextEntityWidgetState extends _EntityWidgetState {
  String _tmpValue;
  FocusNode _focusNode = FocusNode();
  bool validValue = false;

  int get valueMinLength => widget.entity._attributes["min"] ?? -1;
  int get valueMaxLength => widget.entity._attributes["max"] ?? -1;
  String get valuePattern => widget.entity._attributes["pattern"] ?? null;
  bool get isTextField => widget.entity._attributes["mode"] == "text";
  bool get isPasswordField => widget.entity._attributes["mode"] == "password";

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusListener);
    _tmpValue = widget.entity.state;
  }

  @override
  void setNewState(newValue) {
    if (validate(newValue)) {
      eventBus.fire(new ServiceCallEvent(widget.entity.domain, "set_value", widget.entity.entityId,
          {"value": "$newValue"}));
    } else {
      setState(() {
        _tmpValue = widget.entity.state;
      });
    }
  }

  bool validate(newValue) {
    if (newValue is String) {
      validValue = (newValue.length >= this.valueMinLength) &&
          (this.valueMaxLength == -1 ||
              (newValue.length <= this.valueMaxLength));
    } else {
      validValue = true;
    }
    return validValue;
  }

  void _focusListener() {
    if (!_focusNode.hasFocus && (_tmpValue != widget.entity.state)) {
      setNewState(_tmpValue);
    }
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    if (!_focusNode.hasFocus && (_tmpValue != widget.entity.state)) {
      _tmpValue = widget.entity.state;
    }
    if (this.isTextField || this.isPasswordField) {
      return Container(
        width: Entity.INPUT_WIDTH,
        child: TextField(
            focusNode: _focusNode,
            obscureText: this.isPasswordField,
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: _tmpValue,
                    selection:
                    new TextSelection.collapsed(offset: _tmpValue.length))),
            onChanged: (value) {
              _tmpValue = value;
            }),
      );
    } else {
      TheLogger.log("Warning", "Unsupported input mode for ${widget.entity.entityId}");
      return super._buildActionWidget(inCard, context);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    _focusNode.dispose();
    super.dispose();
  }

}