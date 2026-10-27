// Renders LinkedIn-ready mockups of the app's real screens with sample data.
//
//   flutter test tool/mockups/linkedin_mockups_test.dart
//
// Writes six 2160x2700 (4:5) PNGs and a carousel PDF of the same slides to
// tool/mockups/out/. The views are the production widgets; only the data and
// the device frame are staged here.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cognitive_fitness_app/controllers/dashboard_controller.dart';
import 'package:cognitive_fitness_app/controllers/navigation_controller.dart';
import 'package:cognitive_fitness_app/controllers/reports_controller.dart';
import 'package:cognitive_fitness_app/controllers/results_controller.dart';
import 'package:cognitive_fitness_app/controllers/settings_controller.dart';
import 'package:cognitive_fitness_app/controllers/coach_controller.dart';
import 'package:cognitive_fitness_app/core/theme/app_colors.dart';
import 'package:cognitive_fitness_app/core/theme/app_theme.dart';
import 'package:cognitive_fitness_app/core/utils/formatters.dart';
import 'package:cognitive_fitness_app/models/app_settings.dart';
import 'package:cognitive_fitness_app/models/coach_message.dart';
import 'package:cognitive_fitness_app/models/test_result.dart';
import 'package:cognitive_fitness_app/models/test_type.dart';
import 'package:cognitive_fitness_app/views/coach/coach_view.dart';
import 'package:cognitive_fitness_app/views/reports/widgets/trend_chart_card.dart';
import 'package:cognitive_fitness_app/views/results/result_view.dart';
import 'package:cognitive_fitness_app/views/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../test/fakes.dart';

const _fontDir = 'tool/mockups/fonts';
const _outDir = 'tool/mockups/out';
const _canvas = Size(1080, 1350);
const _pixelRatio = 2.0;
const _slideCount = 6;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_installFonts);

  testWidgets('LinkedIn mockups', (tester) async {
    // flutter_test flattens shadows by default; the design relies on them.
    debugDisableShadows = false;
    tester.view
      ..physicalSize = _canvas
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Directory(_outDir).createSync(recursive: true);

    final data = (await tester.runAsync(_SampleData.create))!;

    final slides = [
      await _capture(tester, '01-hero', _HeroSlide(data), prepare: () async {
        await _askCoach(tester, _HeroSlide.coachPhone, [CoachTopic.weekly]);
      }),
      await _capture(tester, '02-dashboard', _DashboardSlide(data)),
      await _capture(tester, '03-reports', _ReportsSlide(data), prepare: () async {
        final chart = find.descendant(of: find.byKey(_ReportsSlide.chartsPhone), matching: find.byType(TrendChartCard));
        _verticalScrollable(tester, _ReportsSlide.chartsPhone).jumpTo(600);
        await tester.pump();
        await Scrollable.ensureVisible(tester.element(chart), alignment: 0.02);
      }),
      await _capture(tester, '04-coach', _CoachSlide(data), prepare: () async {
        await _askCoach(tester, _CoachSlide.phone, [CoachTopic.weekly, CoachTopic.bestTest]);
      }),
      await _capture(tester, '05-tests', _TestsSlide(data)),
      await _capture(tester, '06-architecture', const _ArchitectureSlide()),
    ];
    File(p.join(_outDir, 'cognitive-fitness-carousel.pdf')).writeAsBytesSync(_carouselPdf(slides, _canvas));

    // Restored before the end of the body, where flutter_test checks it.
    debugDisableShadows = true;
  });
}

// --- Rendering --------------------------------------------------------------

/// Serves the bundled Plus Jakarta Sans files as app assets so google_fonts
/// loads them instead of fetching over the test's mocked network.
Future<void> _installFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  final assetsDir = Platform.environment['UNIT_TEST_ASSETS']!;
  final fonts = {
    for (final file in Directory(_fontDir).listSync().whereType<File>()) 'mockup_fonts/${p.basename(file.path)}': file,
  };
  const codec = StandardMessageCodec();
  final manifestFile = File(p.join(assetsDir, 'AssetManifest.bin'));
  final manifest = <Object?, Object?>{
    if (manifestFile.existsSync())
      ...codec.decodeMessage(ByteData.sublistView(manifestFile.readAsBytesSync())) as Map<Object?, Object?>,
    for (final key in fonts.keys)
      key: [
        {'asset': key},
      ],
  };
  final manifestBytes = codec.encodeMessage(manifest)!;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    message,
  ) async {
    final key = utf8.decode(Uint8List.sublistView(message!));
    if (key == 'AssetManifest.bin') return manifestBytes;
    final file = fonts[key] ?? File(p.join(assetsDir, key));
    return file.existsSync() ? ByteData.sublistView(file.readAsBytesSync()) : null;
  });

  // Material icons ship with the SDK next to the flutter_tester binary.
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? p.normalize(p.join(p.dirname(Platform.resolvedExecutable), '../../../../..'));
  final icons = File(p.join(flutterRoot, 'bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();

  AppTheme.light();
  for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800]) {
    GoogleFonts.plusJakartaSans(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
}

/// Writes the slide as `<name>.png` and returns its pixels for the PDF.
Future<_RgbaImage> _capture(
  WidgetTester tester,
  String name,
  Widget slide, {
  Future<void> Function()? prepare,
}) async {
  final boundary = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: Material(color: _Palette.canvas, child: slide),
      ),
    ),
  );
  // Never pumpAndSettle: the coach orb pulses forever.
  await tester.pump(const Duration(seconds: 1));
  if (prepare != null) await prepare();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));

  return (await tester.runAsync(() async {
    final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: _pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    File(p.join(_outDir, '$name.png')).writeAsBytesSync(png!.buffer.asUint8List());
    return _RgbaImage(image.width, image.height, rgba!.buffer.asUint8List());
  }))!;
}

class _RgbaImage {
  const _RgbaImage(this.width, this.height, this.pixels);

  final int width;
  final int height;
  final Uint8List pixels;
}

/// A minimal PDF with one full-bleed image per [pageSize] page, the format
/// LinkedIn turns into a swipeable document carousel.
Uint8List _carouselPdf(List<_RgbaImage> slides, Size pageSize) {
  final out = BytesBuilder(copy: false);
  final offsets = <int>[];
  void write(String text) => out.add(latin1.encode(text));
  void object(String dictionary, [List<int>? stream]) {
    offsets.add(out.length);
    write('${offsets.length} 0 obj\n$dictionary\n');
    if (stream != null) {
      write('stream\n');
      out.add(stream);
      write('\nendstream\n');
    }
    write('endobj\n');
  }

  final width = pageSize.width.round();
  final height = pageSize.height.round();
  // Objects: 1 catalog, 2 page tree, then page / contents / image per slide.
  final pageIds = [for (var i = 0; i < slides.length; i++) 3 + i * 3];

  write('%PDF-1.4\n');
  object('<< /Type /Catalog /Pages 2 0 R >>');
  object('<< /Type /Pages /Kids [${pageIds.map((id) => '$id 0 R').join(' ')}] /Count ${slides.length} >>');
  for (final (i, slide) in slides.indexed) {
    final id = pageIds[i];
    object(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $width $height] '
      '/Resources << /XObject << /Slide ${id + 2} 0 R >> >> /Contents ${id + 1} 0 R >>',
    );
    final contents = latin1.encode('q $width 0 0 $height 0 0 cm /Slide Do Q');
    object('<< /Length ${contents.length} >>', contents);
    final pixels = _deflateRgb(slide);
    object(
      '<< /Type /XObject /Subtype /Image /Width ${slide.width} /Height ${slide.height} '
      '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode '
      '/DecodeParms << /Predictor 15 /Colors 3 /Columns ${slide.width} >> /Length ${pixels.length} >>',
      pixels,
    );
  }

  final xref = out.length;
  write('xref\n0 ${offsets.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  write('trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  return out.takeBytes();
}

/// Drops alpha (slides are opaque) and applies PNG "Up" row filtering before
/// deflating, which shrinks the smooth gradients considerably.
List<int> _deflateRgb(_RgbaImage image) {
  final stride = image.width * 3;
  final rows = Uint8List((stride + 1) * image.height);
  var o = 0;
  for (var y = 0; y < image.height; y++) {
    rows[o++] = 2;
    for (var x = 0; x < image.width; x++) {
      final i = (y * image.width + x) * 4;
      for (var c = 0; c < 3; c++) {
        final above = y == 0 ? 0 : image.pixels[i - image.width * 4 + c];
        rows[o++] = (image.pixels[i + c] - above) & 0xFF;
      }
    }
  }
  return ZLibCodec(level: 9).encode(rows);
}

ScrollPosition _verticalScrollable(WidgetTester tester, Key phone) {
  return tester
      .stateList<ScrollableState>(find.descendant(of: find.byKey(phone), matching: find.byType(Scrollable)))
      .firstWhere((s) => s.position.axis == Axis.vertical)
      .position;
}

/// Asks the coach on [phone] each topic, then scrolls to the latest answer.
Future<void> _askCoach(WidgetTester tester, Key phone, List<CoachTopic> topics) async {
  final chip = find.descendant(of: find.byKey(phone), matching: find.byType(ActionChip)).first;
  final coach = tester.element(chip).read<CoachController>();
  for (final topic in topics) {
    coach.ask(topic);
  }
  await tester.pump();
  final messages = _verticalScrollable(tester, phone);
  messages.jumpTo(messages.maxScrollExtent);
}

final _theme = AppTheme.light();

// --- Sample data ------------------------------------------------------------

/// Three weeks of plausible history: reaction times improving from ~520 ms to
/// ~360 ms, a 15-day streak, and 3 of 5 sessions done today.
class _SampleData {
  _SampleData._(this.now, this.results, this.settings)
    : dashboard = DashboardController(results, settings, clock: () => now),
      reports = ReportsController(results, settings, clock: () => now);

  final DateTime now;
  final ResultsController results;
  final SettingsController settings;
  final DashboardController dashboard;
  final ReportsController reports;

  static Future<_SampleData> create() async {
    final now = DateTime.now().startOfDay.add(const Duration(hours: 18, minutes: 30));
    final settingsRepository = InMemorySettingsRepository()..saved = const AppSettings(dailyGoal: 5);
    final results = ResultsController(InMemoryResultRepository(_history(now)));
    final settings = SettingsController(settingsRepository);
    await Future.wait([results.load(), settings.load()]);
    return _SampleData._(now, results, settings);
  }

  static List<TestResult> _history(DateTime now) {
    final random = Random(7);
    const mix = [TestType.single, TestType.dual, TestType.single, TestType.visual, TestType.auditory, TestType.tapping];
    const typeOffsetMs = {TestType.dual: 90, TestType.auditory: 55, TestType.visual: 25};
    final history = <TestResult>[];

    for (var day = 20; day >= 0; day--) {
      if (day > 14 && day % 3 == 0) continue; // rest days before the current streak
      final today = day == 0;
      final sessions = today ? 3 : 2 + random.nextInt(3);
      final baseMs = 520 - (20 - day) * 8.0;

      for (var i = 0; i < sessions; i++) {
        final type = today ? const [TestType.visual, TestType.dual, TestType.single][i] : mix[random.nextInt(mix.length)];
        final timestamp = today
            ? now.subtract(Duration(minutes: const [215, 120, 25][i]))
            : now.startOfDay.addDays(-day).add(Duration(hours: 8 + i * 3, minutes: random.nextInt(60)));
        final isLast = today && i == sessions - 1;
        final correct = 12 + random.nextInt(40);
        final attempts = switch (type) {
          TestType.single || TestType.dual => 3,
          TestType.tapping => 3 + random.nextInt(4),
          _ => 5,
        };

        history.add(
          TestResult(
            type: type,
            timestamp: timestamp,
            durationMs: type.estimatedSeconds * 1000 + random.nextInt(8000) - 4000,
            reactionMs: type == TestType.tapping
                ? null
                : isLast
                ? 318
                : baseMs + (typeOffsetMs[type] ?? 0) + random.nextInt(60) - 30,
            tapIntervalMs: type == TestType.tapping ? 340 + random.nextInt(90).toDouble() : null,
            variabilityMs: isLast ? 24 : 25 + random.nextInt(45).toDouble(),
            errors: !isLast && random.nextDouble() < 0.18 ? 1 : 0,
            attempts: attempts,
            correctAnswer: type.hasMath ? correct : null,
            mathAnswer: type.hasMath ? (random.nextDouble() < 0.88 ? correct : correct + 1) : null,
          ),
        );
      }
    }
    return [for (var i = 0; i < history.length; i++) history[i].copyWith(id: i + 1)];
  }
}

/// Runs a production screen in its own app, sharing the sample controllers.
class _AppScreen extends StatelessWidget {
  const _AppScreen(this.data, {required this.home, this.tab = AppTab.home});

  final _SampleData data;
  final Widget home;
  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: data.results),
        ChangeNotifierProvider.value(value: data.settings),
        ChangeNotifierProvider(create: (_) => NavigationController()..select(tab)),
        ChangeNotifierProvider.value(value: data.dashboard),
        ChangeNotifierProvider.value(value: data.reports),
      ],
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: _theme, home: home),
    );
  }
}

// --- Device frame -----------------------------------------------------------

class _Phone extends StatelessWidget {
  const _Phone({super.key, required this.child, this.scale = 1});

  static const screen = Size(390, 844);
  static const _frame = 3.0;
  static const _bezel = 10.0;
  static const _statusBar = 44.0;
  static final size = Size(screen.width + (_frame + _bezel) * 2, screen.height + (_frame + _bezel) * 2);

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size * scale,
      child: FittedBox(
        child: Container(
          width: size.width,
          height: size.height,
          padding: const EdgeInsets.all(_frame),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A5A5A), Color(0xFF1C1C1C), Color(0xFF3C3C3C)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x2E000000), blurRadius: 70, offset: Offset(0, 36)),
              BoxShadow(color: Color(0x1F000000), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(_bezel),
            decoration: BoxDecoration(color: const Color(0xFF0B0B0B), borderRadius: BorderRadius.circular(57)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(47),
              child: Stack(
                children: [
                  MediaQuery(
                    data: const MediaQueryData(
                      size: screen,
                      devicePixelRatio: 3,
                      padding: EdgeInsets.only(top: _statusBar, bottom: 14),
                      viewPadding: EdgeInsets.only(top: _statusBar, bottom: 14),
                    ),
                    child: child,
                  ),
                  const Positioned(top: 0, left: 0, right: 0, height: _statusBar, child: _StatusBar()),
                  Positioned(
                    bottom: 7,
                    left: (screen.width - 124) / 2,
                    child: Container(
                      width: 124,
                      height: 5,
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Text('9:41', style: _font(15, FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.signal_cellular_alt_rounded, size: 17, color: AppColors.ink),
              const SizedBox(width: 5),
              const Icon(Icons.wifi_rounded, size: 17, color: AppColors.ink),
              const SizedBox(width: 5),
              const Icon(Icons.battery_full_rounded, size: 17, color: AppColors.ink),
            ],
          ),
          Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(color: Color(0xFF0B0B0B), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// --- Slide building blocks --------------------------------------------------

abstract final class _Palette {
  static const canvas = Color(0xFFF1F0EE);
  static const muted = Color(0xFF6E6E6E);
}

TextStyle _font(double size, FontWeight weight, {Color color = AppColors.ink, double height = 1.25, double spacing = 0}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );
}

TextStyle _headlineStyle(double size) => _font(size, FontWeight.w800, height: 1.04, spacing: -size * 0.035);

/// Shared background, brand mark and slide counter.
class _Slide extends StatelessWidget {
  const _Slide({required this.number, required this.child});

  final int number;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(right: -260, top: -300, child: _Glow(size: 820, color: AppColors.accent.withValues(alpha: 0.20))),
        Positioned(left: -320, bottom: -340, child: _Glow(size: 760, color: Colors.white.withValues(alpha: 0.95))),
        Positioned.fill(child: child),
        Positioned(left: 72, top: 64, child: const _Brand()),
        Positioned(
          right: 72,
          top: 74,
          child: Text(
            '${number.toString().padLeft(2, '0')} / ${_slideCount.toString().padLeft(2, '0')}',
            style: _font(20, FontWeight.w600, color: _Palette.muted, spacing: 1),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [AppColors.accentLight, AppColors.accent],
            ),
            boxShadow: [BoxShadow(color: Color(0x55E1633F), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Text('Cognitive Fitness', style: _font(24, FontWeight.w700, spacing: -0.4)),
      ],
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: _font(19, FontWeight.w700, color: AppColors.accent, spacing: 2.4));
  }
}

/// Headline with an optional accent-coloured second part.
class _Headline extends StatelessWidget {
  const _Headline(this.plain, this.accent, {this.size = 64, this.align = TextAlign.start});

  final String plain;
  final String accent;
  final double size;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: plain),
          TextSpan(text: accent, style: const TextStyle(color: AppColors.accent)),
        ],
      ),
      textAlign: align,
      style: _headlineStyle(size),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text, {this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: align, style: _font(25, FontWeight.w500, color: _Palette.muted, height: 1.45));
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Icon(icon, color: AppColors.accent, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(child: Text(text, style: _font(22, FontWeight.w600, color: AppColors.inkSoft, height: 1.3))),
        ],
      ),
    );
  }
}

/// Copy column beside a single large phone.
class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.copy, required this.phone, this.phoneOnLeft = false});

  final List<Widget> copy;
  final Widget phone;
  final bool phoneOnLeft;

  @override
  Widget build(BuildContext context) {
    final column = SizedBox(
      width: 430,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: copy),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 150, 64, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: phoneOnLeft ? [phone, column] : [column, phone],
      ),
    );
  }
}

/// Centered headline above a row of phones.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.headline, required this.body, required this.phones});

  final Widget headline;
  final String body;
  final Widget phones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 168, 72, 0),
      child: Column(
        children: [
          headline,
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: _Body(body, align: TextAlign.center),
          ),
          const SizedBox(height: 44),
          phones,
        ],
      ),
    );
  }
}

// --- Slides -----------------------------------------------------------------

class _HeroSlide extends StatelessWidget {
  const _HeroSlide(this.data);

  static const coachPhone = ValueKey('hero-coach');

  final _SampleData data;

  @override
  Widget build(BuildContext context) {
    const side = 0.78;
    const center = 0.92;
    return _Slide(
      number: 1,
      child: Stack(
        children: [
          const Positioned(
            left: 72,
            right: 72,
            top: 168,
            child: Column(
              children: [
                _Headline('Train your focus\n', 'See your progress', size: 76, align: TextAlign.center),
                SizedBox(height: 24),
                _Body(
                  'Reaction and biofeedback tests, real reports and an on-device coach, '
                  'rebuilt from the ground up in Flutter.',
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: 580,
            left: 540 - 300 - _Phone.size.width * side / 2,
            child: _Phone(
              scale: side,
              child: _AppScreen(data, home: const MainShell(), tab: AppTab.progress),
            ),
          ),
          Positioned(
            top: 580,
            left: 540 + 300 - _Phone.size.width * side / 2,
            child: _Phone(key: coachPhone, scale: side, child: _AppScreen(data, home: const CoachView())),
          ),
          Positioned(
            top: 500,
            left: 540 - _Phone.size.width * center / 2,
            child: _Phone(scale: center, child: _AppScreen(data, home: const MainShell())),
          ),
        ],
      ),
    );
  }
}

class _DashboardSlide extends StatelessWidget {
  const _DashboardSlide(this.data);

  final _SampleData data;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      number: 2,
      child: _SideBySide(
        copy: const [
          _Kicker('Home dashboard'),
          SizedBox(height: 20),
          _Headline('Your day\n', 'at a glance', size: 62),
          SizedBox(height: 24),
          _Body('Everything that matters today on one calm screen.'),
          SizedBox(height: 12),
          _Feature(Icons.track_changes_rounded, 'Daily goal that fills as you train'),
          _Feature(Icons.favorite_rounded, 'Readiness score and streaks'),
          _Feature(Icons.bolt_rounded, 'One-tap start for your next test'),
        ],
        phone: _Phone(scale: 1.16, child: _AppScreen(data, home: const MainShell())),
      ),
    );
  }
}

class _ReportsSlide extends StatelessWidget {
  const _ReportsSlide(this.data);

  static const chartsPhone = ValueKey('reports-charts');

  final _SampleData data;

  @override
  Widget build(BuildContext context) {
    const scale = 0.92;
    return _Slide(
      number: 3,
      child: _Stacked(
        headline: const _Headline('Reports that\n', 'explain your progress', size: 64, align: TextAlign.center),
        body: 'Daily, weekly and monthly views with trend charts, a personal target and clear insights.',
        phones: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Phone(
              scale: scale,
              child: _AppScreen(data, home: const MainShell(), tab: AppTab.progress),
            ),
            const SizedBox(width: 44),
            _Phone(
              key: chartsPhone,
              scale: scale,
              child: _AppScreen(data, home: const MainShell(), tab: AppTab.progress),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachSlide extends StatelessWidget {
  const _CoachSlide(this.data);

  static const phone = ValueKey('coach');

  final _SampleData data;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      number: 4,
      child: _SideBySide(
        phoneOnLeft: true,
        copy: const [
          _Kicker('Progress coach'),
          SizedBox(height: 20),
          _Headline('Ask how\n', "you're doing", size: 62),
          SizedBox(height: 24),
          _Body('Answers come from your own test history, stored on your device.'),
          SizedBox(height: 12),
          _Feature(Icons.calendar_month_rounded, 'Daily and weekly recaps'),
          _Feature(Icons.emoji_events_rounded, 'Your strongest test and streak'),
          _Feature(Icons.route_rounded, 'What to train next'),
        ],
        phone: _Phone(key: phone, scale: 1.16, child: _AppScreen(data, home: const CoachView())),
      ),
    );
  }
}

class _TestsSlide extends StatelessWidget {
  const _TestsSlide(this.data);

  final _SampleData data;

  @override
  Widget build(BuildContext context) {
    const scale = 0.92;
    return _Slide(
      number: 5,
      child: _Stacked(
        headline: const _Headline('Five tests\n', 'Instant feedback', size: 64, align: TextAlign.center),
        body: 'Reaction, dual-task, auditory, visual go/no-go and tapping, each scored 0–100 '
            'against your own average.',
        phones: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Phone(
              scale: scale,
              child: _AppScreen(data, home: const MainShell(), tab: AppTab.tests),
            ),
            const SizedBox(width: 44),
            _Phone(
              scale: scale,
              child: _AppScreen(data, home: ResultView(result: data.results.results.first)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureSlide extends StatelessWidget {
  const _ArchitectureSlide();

  static const _layers = [
    (Icons.phone_iphone_rounded, 'Views', 'Widgets only. They read controllers and never touch storage.', 'DashboardView · ReportsView · CoachView'),
    (Icons.tune_rounded, 'Controllers', 'ChangeNotifiers exposed with Provider, one source of truth for results.', 'ResultsController · ReportsController'),
    (Icons.settings_suggest_rounded, 'Services', 'SQLite, preferences, audio and pure, unit-tested analytics.', 'AnalyticsService · CoachService'),
    (Icons.data_object_rounded, 'Models', 'Plain, immutable data shared by every layer.', 'TestResult · ReportSummary · AppSettings'),
  ];

  static const _stack = ['Flutter 3.35', 'Dart 3.9', 'Provider', 'fl_chart', 'sqflite', '21 unit tests'];

  @override
  Widget build(BuildContext context) {
    return _Slide(
      number: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(72, 196, 72, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Kicker('Under the hood'),
            const SizedBox(height: 20),
            const _Headline('Clean ', 'MVC architecture', size: 64),
            const SizedBox(height: 20),
            const _Body('Each layer has one job, so screens stay simple and the logic stays testable.'),
            const SizedBox(height: 40),
            for (final (i, (icon, title, description, examples)) in _layers.indexed) ...[
              if (i > 0) const _LayerArrow(),
              _LayerCard(icon: icon, title: title, description: description, examples: examples),
            ],
            const SizedBox(height: 56),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final label in _stack) _StackChip(label)],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({required this.icon, required this.title, required this.description, required this.examples});

  final IconData icon;
  final String title;
  final String description;
  final String examples;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.accent, size: 30),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _font(26, FontWeight.w800, spacing: -0.5)),
                const SizedBox(height: 4),
                Text(description, style: _font(19, FontWeight.w500, color: AppColors.inkSoft, height: 1.35)),
                const SizedBox(height: 6),
                Text(examples, style: _font(16, FontWeight.w600, color: _Palette.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerArrow extends StatelessWidget {
  const _LayerArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 46, top: 10, bottom: 10),
      child: Icon(Icons.south_rounded, color: AppColors.accent, size: 30),
    );
  }
}

class _StackChip extends StatelessWidget {
  const _StackChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(40)),
      child: Text(label, style: _font(19, FontWeight.w600, color: Colors.white)),
    );
  }
}
