import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:video_filter_app/src/component/page_route.dart';

class AppModule extends Module {
  @override
  List<Bind<Object>> get binds => [
        Bind.factory((i) => FlutterFFmpeg()),
      ];

  @override
  List<ModularRoute> get routes => pageRoutes;
}
