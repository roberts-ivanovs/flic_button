import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'models.dart';

abstract class Flic2Listener {
  /// called as a button is found by the plugin (while scanning)
  void onButtonFound(Flic2Button button) {}

  /// called as a button is discovered (by bluetooth address) by the plugin (while scanning)
  void onButtonDiscovered(String buttonAddress) {}

  /// called as an already paired button is found by the plugin (while scanning)
  void onPairedButtonDiscovered(Flic2Button button) {}

  void onButtonSingleOrDoubleClickOrHold(
      Flic2ButtonSingleOrDoubleClickOrHold buttonClick);
  void onButtonUpOrDown(Flic2ButtonUpOrDown buttonClick);
  void onButtonClickOrHold(Flic2ButtonClickOrHold buttonClick);
  void onButtonSingleOrDoubleClick(Flic2ButtonSingleOrDoubleClick buttonClick);

  /// called by the plugin as a button becomes connected
  void onButtonConnected() {}

  /// called by the plugin as a scan is started
  void onScanStarted() {}

  /// called by the plugin as a scan is completed
  void onScanCompleted() {}

  /// called by the plugin as an unexpected error is encountered
  void onFlic2Error(String error) {}
}

/// the plugin to handle Flic2 buttons
class FlicButtonPlugin {
  static const String _channelName = 'flic_button';
  static const String _methodNameInitialize = 'initializeFlic2';
  static const String _methodNameDispose = 'disposeFlic2';
  static const String _methodNameCallback = 'callListener';

  static const String _methodNameStartFlic2Scan = "startFlic2Scan";
  static const String _methodNameStopFlic2Scan = "stopFlic2Scan";
  static const String _methodNameStartListenToFlic2 = "startListenToFlic2";
  static const String _methodNameStopListenToFlic2 = "stopListenToFlic2";

  static const String _methodNameGetButtons = "getButtons";
  static const String _methodNameGetButtonsByAddr = "getButtonsByAddr";

  static const String _methodNameConnectButton = "connectButton";
  static const String _methodNameDisconnectButton = "disconnectButton";
  static const String _methodNameForgetButton = "forgetButton";

  // ignore: constant_identifier_names
  static const String ERROR_CRITICAL = 'CRITICAL';
  // ignore: constant_identifier_names
  static const String ERROR_NOT_STARTED = 'NOT_STARTED';
  // ignore: constant_identifier_names
  static const String ERROR_ALREADY_STARTED = 'ALREADY_STARTED';
  // ignore: constant_identifier_names
  static const String ERROR_INVALID_ARGUMENTS = 'INVALID_ARGUMENTS';

  static const int methodFlic2DiscoverPaired = 100;
  static const int methodFlic2Discovered = 101;
  static const int methodFlic2Connected = 102;
  static const int methodFlic2Scanning = 103;
  static const int methodFlic2ScanComplete = 104;
  static const int methodFlic2Found = 105;
  static const int methodFlic2Error = 200;
  static const int methodFlic2ButtonClickSingleOrDoubleClickOrHold = 301;
  static const int methodFlic2ButtonUpDown = 302;
  static const int methodFlic2ButtonClickOrHold = 303;
  static const int methodFlic2ButtonSingleOrDoubleClick = 304;

  static const MethodChannel _channel = MethodChannel(_channelName);

  Flic2Listener _flic2listener;
  late Future<bool?> invokationFuture;

  set flic2listener(Flic2Listener flic2listener) {
    _flic2listener = flic2listener;
  }

  final log = Logger('FlicButtonPlugin');

  FlicButtonPlugin(this._flic2listener) {
    // set the callback handler to ours to receive all our data back after
    // initialized
    _channel.setMethodCallHandler(_methodCallHandler);
    invokationFuture = _channel.invokeMethod<bool>(_methodNameInitialize);
  }

  /// dispose of this plugin to shut it all down (iOS doesn't at the moment)
  Future<bool?> disposeFlic2() async {
    // this just stops the FLIC 2 manager if not started that's ok
    return _channel.invokeMethod<bool>(_methodNameDispose);
  }

  /// initiate a scan for buttons
  Future<bool?> scanForFlic2() async {
    // scan for flic 2 buttons then please
    return _channel.invokeMethod<bool>(_methodNameStartFlic2Scan);
  }

  /// cancel any running scan
  Future<bool?> cancelScanForFlic2() async {
    // scan for flic 2 buttons then please
    return _channel.invokeMethod<bool>(_methodNameStopFlic2Scan);
  }

  /// connect a button for use
  Future<bool?> connectButton(String buttonUuid) async {
    // connect this button then please
    return _channel.invokeMethod<bool>(_methodNameConnectButton, [buttonUuid]);
  }

  /// disconnect a button to stop using
  Future<bool?> disconnectButton(String buttonUuid) async {
    // disconnect this button then please
    return _channel
        .invokeMethod<bool>(_methodNameDisconnectButton, [buttonUuid]);
  }

  /// have the manager forget the button (so you can scan again and connect again)
  Future<bool?> forgetButton(String buttonUuid) async {
    // forget this button then please
    return _channel.invokeMethod<bool>(_methodNameForgetButton, [buttonUuid]);
  }

  /// listen to the button (android only, or can commonly ignore)
  Future<bool?> listenToFlic2Button(String buttonUuid) async {
    // scan for flic 2 buttons then please
    return _channel
        .invokeMethod<bool>(_methodNameStartListenToFlic2, [buttonUuid]);
  }

  /// stop listening to a button (not iOS)
  Future<bool?> cancelListenToFlic2Button(String buttonUuid) async {
    // scan for flic 2 buttons then please
    return _channel
        .invokeMethod<bool>(_methodNameStopListenToFlic2, [buttonUuid]);
  }

  /// get all the flic 2 buttons the manager is currently aware of (will remember between sessions)
  Future<List<Flic2Button>> getFlic2Buttons() async {
    // get the buttons
    final buttons = await _channel.invokeMethod<List?>(_methodNameGetButtons);
    if (null == buttons) {
      return [];
    } else {
      var result = buttons
          .map((e) => createFlic2ButtonFromData(e as String) as Flic2Button)
          .toList();
      return result;
    }
  }

  /// when a button is discovered, you can just get the bluetooth address, this let's you see if there's a button behind that
  Future<Flic2Button?> getFlic2ButtonByAddress(String buttonAddress) async {
    // scan for flic 2 buttons then please
    final buttonString = await _channel
        .invokeMethod<String?>(_methodNameGetButtonsByAddr, [buttonAddress]);
    if (buttonString == null || buttonString.isEmpty) {
      // not a valid button
      return null;
    } else {
      return createFlic2ButtonFromData(buttonString);
    }
  }

  /// called back from the native with the relevant data
  Future<void> _methodCallHandler(MethodCall call) async {
    // this is called from the other side when there's something happening in which
    // we are interested, the ID of the method determines what is sent back
    switch (call.method) {
      case _methodNameCallback:
        // this is a nice callback from the implementation - call the proper
        // function that is required then (by the passed data)
        final methodId = call.arguments['method'] ?? '';
        final methodData = call.arguments['data'] ?? '';

        // get the callback that's registered with this ID to call it
        switch (methodId) {
          case methodFlic2DiscoverPaired:
            {
              var message = createFlic2ButtonFromData(methodData);
              if (message != null) {
                _flic2listener.onPairedButtonDiscovered(message);
              }
            }
            break;
          case methodFlic2Discovered:
            // process this method - have discovered a flic 2 button, but just the address which isn't great
            _flic2listener.onButtonDiscovered(methodData);
            break;
          case methodFlic2Connected:
            // process this method - have connected a flic 2 button
            _flic2listener.onButtonConnected();
            break;
          case methodFlic2Found:
            {
              var message = createFlic2ButtonFromData(methodData);
              if (message != null) {
                _flic2listener.onButtonFound(message);
              }
            }
            break;
          case methodFlic2ButtonClickSingleOrDoubleClickOrHold:
            {
              var message =
                  createFlic2ButtonSingleOrDoubleClickOrHoldEvent(methodData);
              if (message != null) {
                _flic2listener.onButtonSingleOrDoubleClickOrHold(message);
              }
            }
            break;
          case methodFlic2ButtonUpDown:
            {
              var message = createFlic2ButtonUpOrDownEvent(methodData);
              if (message != null) {
                _flic2listener.onButtonUpOrDown(message);
              }
            }
            break;
          case methodFlic2ButtonClickOrHold:
            {
              var message = createFlic2ButtonClickOrHoldEvent(methodData);
              if (message != null) {
                _flic2listener.onButtonClickOrHold(message);
              }
            }
            break;
          case methodFlic2ButtonSingleOrDoubleClick:
            {
              var message =
                  createFlic2ButtonSingleOrDoubleClickEvent(methodData);
              if (message != null) {
                _flic2listener.onButtonSingleOrDoubleClick(message);
              }
            }
            break;
          case methodFlic2Scanning:
            // process this method - scanning for buttons
            _flic2listener.onScanStarted();
            break;
          case methodFlic2ScanComplete:
            // process this method - scanning for buttons completed
            _flic2listener.onScanCompleted();
            break;
          case methodFlic2Error:
            // process this method - scanning for buttons completed
            _flic2listener.onFlic2Error(methodData);
            break;
          default:
            log.severe('unrecognised method callback encountered $methodId');
            break;
        }
        break;
      default:
        log.warning('Ignoring unrecognised invoke from native ${call.method}');
        break;
    }
  }
}
