import 'package:flic_button/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flic_button/flic_button.dart';
import 'package:logging/logging.dart';

void main() {
  setUp(() {
    // create the listener
  });

  test('can parse createFlic2ButtonUpOrDownEvent', () async {
    var json =
        """{"wasQueued":false,"lastQueued":false,"timestamp":22603614854,"button":{"uuid":"0b4af6a3d4ee467995dcb9e7f5ba3fd2","bdAddr":"80:E4:DA:79:D0:2B","readyTime":22602989493,"name":"","serialNo":"BG21-D45425","connection":3,"firmwareVer":10,"battPerc":100,"battTime":1678038398137,"battVolt":3.026953,"pressCount":1752},"isUp":true,"isDown":false}""";
    var event = createFlic2ButtonUpOrDownEvent(json);

    expect(event, isNotNull);
  });

  tearDown(() {});
}
