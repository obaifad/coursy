import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/app_widgets.dart';
import 'package:my_app/widgets/profile_avatar.dart';

/// الصور تُفكّ بحجم عرضها لا بحجمها الأصلي (ذاكرة أقل، وفكّ أسرع على الأجهزة الضعيفة).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('profile avatar decodes at its display size', (tester) async {
    await pump(tester, const ProfileAvatar(size: 64, imageUrl: 'https://coursy.sy/storage/avatars/1.jpg'));
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<ResizeImage>(), reason: 'decoded at the source size (up to 1024 px) for a 64 dp circle');
    expect((image.image as ResizeImage).width, 64 * 3);
  });

  testWidgets('network images in cards decode at their display width (guard)', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 160, height: 100, child: AppNetworkImage(url: 'https://coursy.sy/storage/c1.jpg')),
    );
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.memCacheWidth, 160 * 3);
  });
}
