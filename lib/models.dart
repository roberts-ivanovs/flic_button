import 'dart:convert';

enum Flic2ButtonConnectionState {
  disconnected,
  connecting,
  // ignore: constant_identifier_names
  connecting_starting,
  // ignore: constant_identifier_names
  connected_ready,
}

class Flic2Button {
  /// the unique ID of this button - a long ugly string
  final String uuid;

  /// the bluetooth address of this button
  final String buttonAddr;

  /// the time at which this button became ready last (not iOS)
  final int readyTimestamp;

  /// the friendly name of this button
  final String name;

  /// the serial number of this button
  final String serialNo;

  /// is this button connected etc
  final Flic2ButtonConnectionState connectionState;

  /// the firmware version
  final int firmwareVersion;

  /// the state of the battery % so from 0 - 100
  final int? battPercentage;

  /// the timestamp the batter data was stored (not iOS)
  final int? battTimestamp;

  /// the current voltage of the battery
  final double? battVoltage;

  /// a global counter of how often this button has been clicked
  final int pressCount;

  /// constructor
  const Flic2Button({
    required this.uuid,
    required this.buttonAddr,
    required this.readyTimestamp,
    required this.name,
    required this.serialNo,
    required this.connectionState,
    required this.firmwareVersion,
    required this.battPercentage,
    required this.battTimestamp,
    required this.battVoltage,
    required this.pressCount,
  });
}

class BaseClickEvent {
  /// the button
  final Flic2Button button;

  /// was this click stored in the queue, button comes back into range and sends it's cache
  final bool wasQueued;

  /// is this click the last in the queue
  final bool lastQueued;

  /// the timestamp of this click from the button (not in iOS)
  final int timestamp;

  /// constructor
  const BaseClickEvent({
    required this.wasQueued,
    required this.lastQueued,
    required this.timestamp,
    required this.button,
  });
}

class BaseButtonHold {
  /// was this a long hold of the button
  final bool isHold;

  /// constructor
  const BaseButtonHold({
    required this.isHold,
  });
}

class BaseSingleOrDoubleClick {
  /// was this a long hold of the button
  final bool isSingleClick;
  final bool isDoubleClick;

  /// constructor
  const BaseSingleOrDoubleClick({
    required this.isSingleClick,
    required this.isDoubleClick,
  });
}

class Flic2ButtonSingleOrDoubleClickOrHold {
  final BaseClickEvent baseClickEvent;
  final BaseButtonHold baseButtonHold;
  final BaseSingleOrDoubleClick baseSingleOrDoubleClick;

  /// constructor
  const Flic2ButtonSingleOrDoubleClickOrHold({
    required this.baseClickEvent,
    required this.baseButtonHold,
    required this.baseSingleOrDoubleClick,
  });
}

class Flic2ButtonUpOrDown {
  final BaseClickEvent baseClickEvent;
  final bool isUp;
  final bool isDown;

  /// constructor
  const Flic2ButtonUpOrDown({
    required this.baseClickEvent,
    required this.isUp,
    required this.isDown,
  });
}

class Flic2ButtonClickOrHold {
  final BaseClickEvent baseClickEvent;
  final BaseButtonHold baseButtonHold;

  /// constructor
  const Flic2ButtonClickOrHold({
    required this.baseClickEvent,
    required this.baseButtonHold,
  });
}

class Flic2ButtonSingleOrDoubleClick {
  final BaseClickEvent baseClickEvent;
  final BaseSingleOrDoubleClick baseSingleOrDoubleClick;

  /// constructor
  const Flic2ButtonSingleOrDoubleClick({
    required this.baseClickEvent,
    required this.baseSingleOrDoubleClick,
  });
}

Map<String, dynamic> parseObject(String data) {
  // create a button from this json data
  Map<String, dynamic> json;
  if (data is String) {
    // from string data, let's get the map of data
    json = jsonDecode(data);
  } else {
    throw ('data $data is not a string or a map');
  }

  return json;
}

Flic2Button? createFlic2ButtonFromData(String data) {
  try {
    var json = parseObject(data);
    return _createFlic2ButtonFromData(json);
  } catch (error) {
    return null;
  }
}

Flic2Button? _createFlic2ButtonFromData(Map<String, dynamic> json) {
  try {
    return Flic2Button(
      uuid: json['uuid'],
      buttonAddr: json['bdAddr'],
      readyTimestamp: json['readyTime'],
      name: json['name'],
      serialNo: json['serialNo'],
      connectionState: _connectionStateFromChannelCode(json['connection']),
      firmwareVersion: json['firmwareVer'],
      battPercentage: json['battPerc'],
      battTimestamp: json['battTime'],
      battVoltage: json['battVolt'],
      pressCount: json['pressCount'],
    );
  } catch (error) {
    return null;
  }
}

BaseClickEvent? _createBaseClickEvent(Map<String, dynamic> json) {
  try {
    var button = _createFlic2ButtonFromData(json["button"]);
    if (button == null) {
      return null;
    }
    return BaseClickEvent(
      wasQueued: json['wasQueued'],
      lastQueued: json['lastQueued'],
      timestamp: json['timestamp'],
      button: button,
    );
  } catch (error) {
    return null;
  }
}

BaseButtonHold? _createBaseButtonHoldEvent(Map<String, dynamic> json) {
  try {
    return BaseButtonHold(
      isHold: json['isHold'],
    );
  } catch (error) {
    return null;
  }
}

BaseSingleOrDoubleClick? _createBaseSingleOrDoubleClickEvent(
    Map<String, dynamic> json) {
  try {
    return BaseSingleOrDoubleClick(
      isDoubleClick: json['isDoubleClick'],
      isSingleClick: json['isSingleClick'],
    );
  } catch (error) {
    return null;
  }
}

Flic2ButtonSingleOrDoubleClickOrHold?
    createFlic2ButtonSingleOrDoubleClickOrHoldEvent(String data) {
  try {
    var json = parseObject(data);
    var buttonHold = _createBaseButtonHoldEvent(json);
    if (buttonHold == null) {
      return null;
    }
    var baseClickEvent = _createBaseClickEvent(json);
    if (baseClickEvent == null) {
      return null;
    }
    var baseSingleOrDoubleClickEvent =
        _createBaseSingleOrDoubleClickEvent(json);
    if (baseSingleOrDoubleClickEvent == null) {
      return null;
    }
    return Flic2ButtonSingleOrDoubleClickOrHold(
      baseButtonHold: buttonHold,
      baseClickEvent: baseClickEvent,
      baseSingleOrDoubleClick: baseSingleOrDoubleClickEvent,
    );
  } catch (error) {
    return null;
  }
}

Flic2ButtonUpOrDown? createFlic2ButtonUpOrDownEvent(String data) {
  try {
    var json = parseObject(data);
    print("json $json");
    var baseClickEvent = _createBaseClickEvent(json);
    print("baseClickEvent $baseClickEvent");
    if (baseClickEvent == null) {
      return null;
    }
    return Flic2ButtonUpOrDown(
      isDown: json['isDown'],
      isUp: json['isUp'],
      baseClickEvent: baseClickEvent,
    );
  } catch (error) {
    return null;
  }
}

Flic2ButtonClickOrHold? createFlic2ButtonClickOrHoldEvent(String data) {
  try {
    var json = parseObject(data);
    var baseClickEvent = _createBaseClickEvent(json);
    if (baseClickEvent == null) {
      return null;
    }
    var buttonHold = _createBaseButtonHoldEvent(json);
    if (buttonHold == null) {
      return null;
    }
    return Flic2ButtonClickOrHold(
      baseButtonHold: buttonHold,
      baseClickEvent: baseClickEvent,
    );
  } catch (error) {
    return null;
  }
}

Flic2ButtonSingleOrDoubleClick? createFlic2ButtonSingleOrDoubleClickEvent(
    String data) {
  try {
    var json = parseObject(data);
    var baseClickEvent = _createBaseClickEvent(json);
    if (baseClickEvent == null) {
      return null;
    }
    var baseSingleOrDoubleClickEvent =
        _createBaseSingleOrDoubleClickEvent(json);
    if (baseSingleOrDoubleClickEvent == null) {
      return null;
    }
    return Flic2ButtonSingleOrDoubleClick(
      baseSingleOrDoubleClick: baseSingleOrDoubleClickEvent,
      baseClickEvent: baseClickEvent,
    );
  } catch (error) {
    return null;
  }
}

/// helper to convert the int from the native to a nice enum
Flic2ButtonConnectionState _connectionStateFromChannelCode(int code) {
  switch (code) {
    case 0:
      return Flic2ButtonConnectionState.disconnected;
    case 1:
      return Flic2ButtonConnectionState.connecting;
    case 2:
      return Flic2ButtonConnectionState.connecting_starting;
    case 3:
      return Flic2ButtonConnectionState.connected_ready;
    default:
      return Flic2ButtonConnectionState.disconnected;
  }
}
