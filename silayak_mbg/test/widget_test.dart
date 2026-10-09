// Basic smoke test untuk aplikasi SI-LAYAK MBG.
//
// Template bawaan Flutter (yang memakai class `MyApp` dan menguji tombol
// counter) sudah diganti di sini karena aplikasi ini tidak punya counter,
// dan class utama aplikasinya bernama `SiLayakMbgApp` (lihat lib/main.dart).

import 'package:flutter_test/flutter_test.dart';

import 'package:silayak_mbg/main.dart';

void main() {
  testWidgets('SiLayakMbgApp tampil tanpa error (splash screen muncul)', (WidgetTester tester) async {
    await tester.pumpWidget(const SiLayakMbgApp());

    // Frame pertama: splash screen dengan judul aplikasi harus tampil.
    await tester.pump();

    expect(find.text('SI-LAYAK MBG'), findsOneWidget);
  });
}
