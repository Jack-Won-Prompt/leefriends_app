import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_http.dart';
import 'data/auth_controller.dart';
import 'data/menu_repository.dart';
import 'data/push_service.dart';
import 'data/update_service.dart';
import 'screens/root_scaffold.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 운영 서버 TLS 중간 인증서 보완 (Android Flutter 핸드셰이크 우회)
  await AppHttp.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LeeFriendsApp());
}

class LeeFriendsApp extends StatefulWidget {
  const LeeFriendsApp({super.key});

  @override
  State<LeeFriendsApp> createState() => _LeeFriendsAppState();
}

class _LeeFriendsAppState extends State<LeeFriendsApp> {
  final _repository = MenuRepository();
  final _auth = AuthController();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _auth.restore();
    // FCM 초기화 (Firebase 미설정 환경에서도 안전하게 no-op)
    PushService.instance.init(_auth, messengerKey: _messengerKey);
    // Play 스토어 인앱 업데이트 확인 (스토어 설치본에서만 동작, 그 외 무시)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndUpdate();
    });
  }

  @override
  void dispose() {
    _repository.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEEFRIENDS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scaffoldMessengerKey: _messengerKey,
      home: RootScaffold(repository: _repository, auth: _auth),
    );
  }
}
