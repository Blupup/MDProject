// lib/game/artifact_reading_game.dart
//
// 🕯️ ЧТЕНИЕ АРТЕФАКТОВ — исследуй объект и расшифруй руны.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _ArtifactRune {
  final String glyph;
  final String trueMeaning;
  final List<String> falseMeanings;
  final Offset anchor;
  final bool needsLight;
  final bool needsCloseZoom;
  final double requiredRotation;

  const _ArtifactRune({
    required this.glyph,
    required this.trueMeaning,
    required this.falseMeanings,
    required this.anchor,
    this.needsLight = false,
    this.needsCloseZoom = false,
    this.requiredRotation = 0,
  });
}

const _runes = [
  _ArtifactRune(
    glyph: 'ᚠ',
    trueMeaning: 'Огонь памяти',
    falseMeanings: ['Пустой свет', 'Слепая искра'],
    anchor: Offset(-0.32, -0.20),
    needsLight: true,
  ),
  _ArtifactRune(
    glyph: 'ᚢ',
    trueMeaning: 'Печать глубины',
    falseMeanings: ['Ложная печать', 'Круг пыли'],
    anchor: Offset(0.18, -0.24),
    needsCloseZoom: true,
  ),
  _ArtifactRune(
    glyph: 'ᚱ',
    trueMeaning: 'Ключ резонанса',
    falseMeanings: ['Разрыв тишины', 'Пустой ключ'],
    anchor: Offset(-0.14, 0.15),
    requiredRotation: pi * 0.45,
  ),
  _ArtifactRune(
    glyph: 'ᛞ',
    trueMeaning: 'Узел материи',
    falseMeanings: ['Прах металла', 'Холодный узел'],
    anchor: Offset(0.31, 0.23),
    needsLight: true,
    needsCloseZoom: true,
  ),
];

enum _InspectionPhase { inspecting, success, fail }

class ArtifactReadingGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const ArtifactReadingGame({
    super.key,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<ArtifactReadingGame> createState() => _ArtifactReadingGameState();
}

class _ArtifactReadingGameState extends State<ArtifactReadingGame>
    with TickerProviderStateMixin {
  final _rng = Random();
  late AnimationController _bgCtrl;
  late AnimationController _resultCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _resultFade;
  late Animation<double> _resultScale;

  double _rotation = 0;
  double _zoom = 1.0;
  bool _lightOn = false;
  int _activeRune = -1;
  int _mistakes = 0;
  static const _maxMistakes = 4;
  _InspectionPhase _phase = _InspectionPhase.inspecting;
  final Set<int> _revealed = {};
  final Map<int, String> _mappedMeanings = {};
  final Map<int, List<String>> _knowledgeCache = {};
  String _status = 'Осмотри артефакт: вращай, приближай, включи свет.';
  bool _showInlineGuide = true;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultFade =
        CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  bool _runeVisible(_ArtifactRune rune) {
    final lightOk = !rune.needsLight || _lightOn;
    final zoomOk = !rune.needsCloseZoom || _zoom >= 1.35;
    final angleDelta = (_rotation - rune.requiredRotation).abs();
    final rotationOk = rune.requiredRotation == 0 || angleDelta < 0.48;
    return lightOk && zoomOk && rotationOk;
  }

  void _refreshRevealed() {
    for (int i = 0; i < _runes.length; i++) {
      if (_runeVisible(_runes[i])) _revealed.add(i);
    }
    if (_revealed.isEmpty) {
      _status = 'Символы пока скрыты. Попробуй другой угол или свет.';
    } else {
      _status =
          'Шаг ${_currentStep}/3: найдено рун ${_revealed.length}/${_runes.length}.';
    }
  }

  void _validateFinal() {
    final ok = _mappedMeanings.entries.every(
      (e) => _runes[e.key].trueMeaning == e.value,
    );
    if (ok) {
      setState(() {
        _phase = _InspectionPhase.success;
        _status = 'Артефакт прочитан. Истинные свойства раскрыты.';
      });
      _resultCtrl.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), widget.onSuccess);
    } else {
      _mistakes++;
      HapticFeedback.heavyImpact();
      if (_mistakes >= _maxMistakes) {
        setState(() {
          _phase = _InspectionPhase.fail;
          _status = 'Ложные интерпретации разрушили чтение артефакта.';
        });
        _resultCtrl.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), widget.onFail);
      } else {
        setState(() {
          _status = 'Объект реагирует нестабильно. Проверь трактовки ещё раз.';
        });
      }
    }
  }

  List<String> _knowledgeOptions(int runeIdx) {
    if (_knowledgeCache.containsKey(runeIdx)) return _knowledgeCache[runeIdx]!;
    final rune = _runes[runeIdx];
    final options = [rune.trueMeaning, ...rune.falseMeanings]..shuffle(_rng);
    _knowledgeCache[runeIdx] = options;
    return options;
  }

  int get _currentStep {
    if (_revealed.length < _runes.length) return 1;
    if (_mappedMeanings.length < _runes.length) return 2;
    return 3;
  }

  String get _stepHint {
    if (_currentStep == 1) {
      return '1) Открой руны: кнопками крути и приближай артефакт, включай свет.';
    }
    if (_currentStep == 2) {
      return '2) Нажми руну и выбери значение в книге знаний.';
    }
    return '3) Нажми "Проверить трактовки".';
  }

  void _rotateBy(double delta) {
    setState(() {
      _rotation += delta;
      _refreshRevealed();
    });
  }

  void _zoomBy(double delta) {
    setState(() {
      _zoom = (_zoom + delta).clamp(0.8, 2.2);
      _refreshRevealed();
    });
  }

  void _resetView() {
    setState(() {
      _rotation = 0;
      _zoom = 1.0;
      _refreshRevealed();
    });
  }

  void _submitIfReady() {
    if (_mappedMeanings.length < _runes.length) {
      setState(() {
        _status = 'Сначала сопоставь все ${_runes.length} руны.';
      });
      return;
    }
    _validateFinal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ArtifactTablePainter(
                t: _bgAnim.value,
                lightOn: _lightOn,
                mistakeLevel: _mistakes / _maxMistakes,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStatus(),
                _buildStepPanel(),
                const SizedBox(height: 10),
                Expanded(child: _buildInspectionArea()),
                _buildKnowledgeBook(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_phase != _InspectionPhase.inspecting) _buildEndOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child:
                  const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ЧТЕНИЕ АРТЕФАКТОВ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _lightOn = !_lightOn;
              _refreshRevealed();
            }),
            icon: Icon(
              _lightOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
              color: _lightOn ? const Color(0xFFFFD7A5) : Colors.white60,
            ),
          ),
          IconButton(
            onPressed: _showGuideDialog,
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Шум: $_mistakes/$_maxMistakes',
              style: const TextStyle(
                color: Color(0xFFFFA3A3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1620).withOpacity(0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Text(
          _stepHint,
          style: TextStyle(
            color: const Color(0xFFBFDBFE).withOpacity(0.92),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF17131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Руководство: Чтение артефактов',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _guideLine('1) Открой руны: свет + угол + приближение.'),
              _guideLine('2) Нажми найденную руну на артефакте или в книге.'),
              _guideLine('3) Выбери трактовку из вариантов.'),
              _guideLine('4) Нажми "Проверить трактовки".'),
              const SizedBox(height: 8),
              Text(
                'Откуда брать трактовки: из контекста осмотра. Если руна открылась только при свете, обычно подходит "энергетическая/огненная" трактовка. Если открылась только при сильном зуме, чаще это "структурная/глубинная" трактовка. Если нужна ротация — трактовка про ключ, резонанс, направление.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ложные трактовки специально похожи на правильные. При ошибках растет "Шум".',
                style: TextStyle(
                  color: const Color(0xFFFCA5A5).withOpacity(0.9),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Понятно'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF93C5FD)),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.84),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionArea() {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (d) {
                setState(() {
                  _zoom = (_zoom * d.scale).clamp(0.8, 2.2);
                  _rotation += d.rotation * 0.2;
                  _refreshRevealed();
                });
              },
              onTapDown: (d) {
                final local = d.localPosition;
                final center = Offset(
                  constraints.maxWidth / 2,
                  (constraints.maxHeight - 64) / 2,
                );
                for (int i = 0; i < _runes.length; i++) {
                  if (!_revealed.contains(i)) continue;
                  final runePos = center + _runes[i].anchor * (110 * _zoom);
                  if ((runePos - local).distance < 28) {
                    setState(() => _activeRune = i);
                    HapticFeedback.selectionClick();
                  }
                }
              },
              child: Center(
                child: AnimatedBuilder(
                  animation: _bgAnim,
                  builder: (_, __) => CustomPaint(
                    size: const Size(320, 320),
                    painter: _ArtifactObjectPainter(
                      rotation: _rotation,
                      zoom: _zoom,
                      lightOn: _lightOn,
                      revealed: _revealed,
                      activeRune: _activeRune,
                      t: _bgAnim.value,
                      mistakeLevel: _mistakes / _maxMistakes,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                _ctrlBtn(Icons.rotate_left_rounded, () => _rotateBy(-0.25)),
                const SizedBox(width: 8),
                _ctrlBtn(Icons.rotate_right_rounded, () => _rotateBy(0.25)),
                const SizedBox(width: 8),
                _ctrlBtn(Icons.zoom_out_rounded, () => _zoomBy(-0.12)),
                const SizedBox(width: 8),
                _ctrlBtn(Icons.zoom_in_rounded, () => _zoomBy(0.12)),
                const SizedBox(width: 8),
                _ctrlBtn(Icons.replay_rounded, _resetView),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildKnowledgeBook() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131015).withOpacity(0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Книга знаний',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showInlineGuide = !_showInlineGuide),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(
                    _showInlineGuide
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Как выбирать трактовку',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.86),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showInlineGuide) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Text(
                'Источник трактовки — способ, которым ты открыл руну:\n'
                '• Свет: смыслы энергии, огня, проявления.\n'
                '• Приближение: смыслы глубины, структуры, материи.\n'
                '• Поворот: смыслы ключа, резонанса, направления.\n\n'
                'Если вариант слишком "пустой" (например, про пыль/шум/иллюзию), это часто ложная трактовка.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_runes.length, (i) {
              final revealed = _revealed.contains(i);
              final selected = _activeRune == i;
              return GestureDetector(
                onTap: revealed ? () => setState(() => _activeRune = i) : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6D28D9).withOpacity(0.35)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFC4B5FD)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    revealed ? _runes[i].glyph : '❓',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          if (_activeRune >= 0 && _revealed.contains(_activeRune))
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _knowledgeOptions(_activeRune).map((option) {
                final selected = _mappedMeanings[_activeRune] == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _mappedMeanings[_activeRune] = option;
                      _refreshRevealed();
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0EA5E9).withOpacity(0.28)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7DD3FC)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFBAE6FD)
                            : Colors.white.withOpacity(0.82),
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'Выбери найденную руну на артефакте.',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitIfReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
              label: const Text(
                'Проверить трактовки',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOverlay() {
    final isSuccess = _phase == _InspectionPhase.success;
    return AnimatedBuilder(
      animation: _resultCtrl,
      builder: (_, __) => FadeTransition(
        opacity: _resultFade,
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: Center(
            child: ScaleTransition(
              scale: _resultScale,
              child: Container(
                margin: const EdgeInsets.all(42),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF110D14),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSuccess
                        ? const Color(0xFF7DD3FC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isSuccess ? '📖' : '💀', style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 8),
                    Text(
                      isSuccess ? 'АРТЕФАКТ\nРАСШИФРОВАН' : 'ЧТЕНИЕ\nПРЕРВАНО',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSuccess
                            ? const Color(0xFFBAE6FD)
                            : const Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtifactTablePainter extends CustomPainter {
  final double t;
  final bool lightOn;
  final double mistakeLevel;
  _ArtifactTablePainter({
    required this.t,
    required this.lightOn,
    required this.mistakeLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D0B0F), Color(0xFF1A1310)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final table = Paint()..color = const Color(0xFF2A1E16).withOpacity(0.88);
    canvas.drawRect(
      Rect.fromLTWH(10, size.height * 0.28, size.width - 20, size.height * 0.52),
      table,
    );

    final lightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE2B4).withOpacity(lightOn ? 0.34 : 0.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.62, size.height * 0.20),
          radius: 240,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.20), 240, lightPaint);

    final dust = Paint()
      ..color = const Color(0xFFF3E8D2).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (int i = 0; i < 52; i++) {
      final x = (i * 37.0) % size.width;
      final y = (size.height * 0.15) +
          ((i * 29) % (size.height * 0.45)) +
          sin(t * 2 * pi + i) * 4;
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.4 : 0.8, dust);
    }

    if (mistakeLevel > 0.1) {
      final crack = Paint()
        ..color = const Color(0xFFF87171).withOpacity(mistakeLevel * 0.35)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;
      final start = Offset(size.width * 0.24, size.height * 0.56);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(start.dx + 65, start.dy - 18)
        ..lineTo(start.dx + 84, start.dy + 14)
        ..lineTo(start.dx + 132, start.dy - 8);
      canvas.drawPath(path, crack);
    }
  }

  @override
  bool shouldRepaint(_ArtifactTablePainter old) =>
      old.t != t || old.lightOn != lightOn || old.mistakeLevel != mistakeLevel;
}

class _ArtifactObjectPainter extends CustomPainter {
  final double rotation;
  final double zoom;
  final bool lightOn;
  final Set<int> revealed;
  final int activeRune;
  final double t;
  final double mistakeLevel;

  _ArtifactObjectPainter({
    required this.rotation,
    required this.zoom,
    required this.lightOn,
    required this.revealed,
    required this.activeRune,
    required this.t,
    required this.mistakeLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(zoom);

    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF635D58), Color(0xFF2F2C2A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(-90, -90, 180, 180));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-90, -90, 180, 180),
        const Radius.circular(26),
      ),
      base,
    );

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFB3ACA0).withOpacity(0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-90, -90, 180, 180),
        const Radius.circular(26),
      ),
      rim,
    );

    for (int i = 0; i < _runes.length; i++) {
      if (!revealed.contains(i)) continue;
      final rune = _runes[i];
      final pos = Offset(rune.anchor.dx * 110, rune.anchor.dy * 110);
      final glow = Paint()
        ..color = (i == activeRune
                ? const Color(0xFF7DD3FC)
                : const Color(0xFFA78BFA))
            .withOpacity(lightOn ? 0.95 : 0.72)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, i == activeRune ? 16 : 12, glow);
      final tp = TextPainter(
        text: TextSpan(
          text: rune.glyph,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    if (mistakeLevel > 0.15) {
      final crack = Paint()
        ..color = const Color(0xFFFCA5A5).withOpacity(0.32 + mistakeLevel * 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(-52, -10)
        ..lineTo(-20, 6)
        ..lineTo(-6, -2)
        ..lineTo(22, 16)
        ..lineTo(50, 8);
      canvas.drawPath(path, crack);
    }

    final resonance = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF93C5FD).withOpacity(0.25 + sin(t * 2 * pi) * 0.1);
    canvas.drawCircle(Offset.zero, 102, resonance);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtifactObjectPainter old) {
    return old.rotation != rotation ||
        old.zoom != zoom ||
        old.lightOn != lightOn ||
        old.activeRune != activeRune ||
        old.t != t ||
        old.revealed != revealed ||
        old.mistakeLevel != mistakeLevel;
  }
}
