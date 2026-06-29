import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leefriends/data/auth_controller.dart';
import 'package:leefriends/data/menu_repository.dart';
import 'package:leefriends/screens/root_scaffold.dart';
import 'package:leefriends/theme/app_theme.dart';

void main() {
  testWidgets('App boots with bottom navigation tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RootScaffold(
          repository: MenuRepository(),
          auth: AuthController(),
        ),
      ),
    );
    // 첫 프레임에 홈/메뉴/발주 탭이 보여야 한다.
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('메뉴'), findsWidgets);
    expect(find.text('발주'), findsOneWidget);
  });
}
