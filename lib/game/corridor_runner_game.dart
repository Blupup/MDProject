// lib/game/corridor_runner_game.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common_widgets.dart';

const double _gravity   = 1800.0;
const double _jumpForce = -520.0;
const double _pipeSpeed = 190.0;
const double _pipeGap   = 175.0;
const double _pipeW     = 58.0;
const double _playerW   = 46.0;
const double _playerH   = 46.0;
const int    _winCoins  = 10;
const int    _winSec    = 30;

class CorridorRunnerGame extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  const CorridorRunnerGame({super.key, required this.onSuccess, required this.onFail});
  @override
  State<CorridorRunnerGame> createState() => _CorridorRunnerGameState();
}

class _Obs { double x; final double gapTop; bool passed = false;
  _Obs({required this.x, required this.gapTop}); }
class _Coin { double x; final double y; bool collected = false;
  _Coin({required this.x, required this.y}); }

class _CorridorRunnerGameState extends State<CorridorRunnerGame>
    with TickerProviderStateMixin {
  double _playerY = 0, _velY = 0;
  final List<_Obs>  _obs   = [];
  final List<_Coin> _coins = [];
  final _rng = Random();
  bool _started = false, _dead = false, _won = false;
  int _score = 0, _coinsGot = 0, _secLeft = _winSec, _lives = 3;
  DateTime? _lastTick;
  Timer? _timer;
  late AnimationController _loop, _winCtrl, _deadCtrl, _coinPulse;
  late Animation<double> _winScale, _deadScale, _coinPulseA;
  double _w = 0, _h = 0;
  double get _absY => _h / 2 + _playerY;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)..forward();
    _winCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _deadCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _coinPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _winScale  = Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_winCtrl, curve:Curves.elasticOut));
    _deadScale = Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_deadCtrl,curve:Curves.easeOut));
    _coinPulseA= Tween(begin:0.82,end:1.18).animate(CurvedAnimation(parent:_coinPulse,curve:Curves.easeInOut));
    _timer = Timer.periodic(const Duration(seconds:1),(_){
      if (!mounted||!_started||_dead||_won) return;
      setState(()=>_secLeft--);
      if (_secLeft<=0) _triggerWin();
    });
  }

  @override
  void dispose(){ _loop.dispose();_winCtrl.dispose();_deadCtrl.dispose();
    _coinPulse.dispose();_timer?.cancel();super.dispose(); }

  void _tick(){
    if (!_started||_dead||_won||_w==0) return;
    final now = DateTime.now();
    final dt  = _lastTick==null ? 0.016
        : (now.difference(_lastTick!).inMicroseconds/1e6).clamp(0.0,0.05);
    _lastTick = now;
    setState((){
      _velY += _gravity*dt;
      _playerY += _velY*dt;
      final half = _h/2 - _playerH/2 - 6;
      if (_playerY> half){ _playerY= half; _velY=0; _hitDie(); return; }
      if (_playerY<-half){ _playerY=-half; _velY=0; _hitDie(); return; }

      for(final o in _obs) o.x -= _pipeSpeed*dt;
      _obs.removeWhere((o)=>o.x+_pipeW<0);
      final lastX = _obs.isEmpty?_w:_obs.last.x;
      if (lastX < _w-210){
        final gt = _h*0.18 + _rng.nextDouble()*(_h*0.42);
        _obs.add(_Obs(x:_w+10, gapTop:gt));
        if (_rng.nextBool())
          _coins.add(_Coin(x:_w+10+_pipeW/2, y:gt+_pipeGap/2));
      }

      for(final c in _coins) c.x -= _pipeSpeed*dt;
      _coins.removeWhere((c)=>c.x<-20);

      final pr = Rect.fromCenter(center:Offset(78,_absY),width:_playerW-10,height:_playerH-10);
      for(final o in _obs){
        if (pr.overlaps(Rect.fromLTWH(o.x,0,_pipeW,o.gapTop))||
            pr.overlaps(Rect.fromLTWH(o.x,o.gapTop+_pipeGap,_pipeW,_h))){
          _hitDie(); return; }
        if (!o.passed && o.x+_pipeW<78){ o.passed=true; _score+=5; HapticFeedback.lightImpact(); }
      }
      for(final c in _coins){
        if (!c.collected && pr.overlaps(Rect.fromCenter(center:Offset(c.x,c.y),width:28,height:28))){
          c.collected=true; _coinsGot++; _score+=10;
          HapticFeedback.selectionClick();
          if (_coinsGot>=_winCoins) _triggerWin();
        }
      }
    });
  }

  void _hitDie(){
    _lives--;
    HapticFeedback.heavyImpact();
    if (_lives<=0){ _triggerDead(); }
    else { _playerY=0; _velY=-180; }
  }

  void _onTap(){
    if (_dead||_won) return;
    if (!_started){ setState(()=>_started=true); _lastTick=DateTime.now(); return; }
    HapticFeedback.lightImpact();
    setState(()=>_velY=_jumpForce);
  }

  void _triggerWin(){
    if (_won||_dead) return;
    setState(()=>_won=true); _loop.stop(); _timer?.cancel();
    HapticFeedback.heavyImpact(); _winCtrl.forward();
    Future.delayed(const Duration(milliseconds:2800),widget.onSuccess);
  }

  void _triggerDead(){
    if (_dead) return;
    setState(()=>_dead=true); _loop.stop(); _timer?.cancel();
    _deadCtrl.forward();
    Future.delayed(const Duration(milliseconds:2500),widget.onFail);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children:[
        _topBar(),
        Expanded(child: GestureDetector(
          onTapDown: (_)=>_onTap(),
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(builder:(ctx,con){
            _w=con.maxWidth; _h=con.maxHeight;
            return CustomPaint(
              painter: _ScenePainter(
                obstacles: _obs, coins: _coins,
                playerY: _absY, velY: _velY,
                w: _w, h: _h, isDead: _dead,
                coinPulse: _coinPulseA.value,
              ),
              child: Stack(children:[
                if (!_started&&!_dead&&!_won) _startHint(),
                if (_won)  _winOverlay(),
                if (_dead) _deadOverlay(),
              ]),
            );
          }),
        )),
      ])),
    );
  }

  Widget _topBar(){
    final tc = _secLeft>15?kGreen:(_secLeft>7?Colors.orange:kRed);
    return Container(
      padding: const EdgeInsets.fromLTRB(14,8,14,6), color: kBg,
      child: Row(children:[
        Container(
          padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[Color(0xFFFF6B35),Color(0xFFFF3D71)]),
            borderRadius: BorderRadius.circular(10)),
          child: const Row(children:[
            Icon(Icons.directions_run_rounded,color:Colors.white,size:13),
            SizedBox(width:4),
            Text('Коридорный раннер',style:TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w700)),
          ])),
        const Spacer(),
        const Text('📋',style:TextStyle(fontSize:15)),
        const SizedBox(width:4),
        Text('$_coinsGot/$_winCoins',style:const TextStyle(color:kGold,fontWeight:FontWeight.w800,fontSize:13)),
        const SizedBox(width:12),
        Text('$_score',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:15)),
        const SizedBox(width:12),
        Row(children:List.generate(3,(i)=>Padding(
          padding:const EdgeInsets.only(left:3),
          child:Icon(i<_lives?Icons.favorite_rounded:Icons.favorite_border_rounded,
              color:i<_lives?kRed:Colors.white24,size:19)))),
        const SizedBox(width:12),
        Container(width:38,height:38,
          decoration:BoxDecoration(border:Border.all(color:tc,width:2),
            shape:BoxShape.circle,color:tc.withOpacity(0.1)),
          child:Center(child:Text('$_secLeft',
            style:TextStyle(color:tc,fontSize:12,fontWeight:FontWeight.w900)))),
      ]),
    );
  }

  Widget _startHint()=>Center(child:Container(
    padding:const EdgeInsets.symmetric(horizontal:24,vertical:18),
    decoration:BoxDecoration(color:Colors.black.withOpacity(0.72),
      borderRadius:BorderRadius.circular(20),border:Border.all(color:kGreen.withOpacity(0.5))),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Text('🎓',style:TextStyle(fontSize:46)),
      const SizedBox(height:8),
      const Text('Студент-Раннер',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      Text('Нажми чтобы прыгнуть!',style:TextStyle(color:Colors.white.withOpacity(0.7),fontSize:13)),
      const SizedBox(height:4),
      Text('Собери $_winCoins зачёток или продержись $_winSec сек',
        style:const TextStyle(color:kGreen,fontSize:12,fontWeight:FontWeight.w600),
        textAlign:TextAlign.center),
    ])));

  Widget _winOverlay()=>Positioned.fill(child:Container(
    color:Colors.black.withOpacity(0.6),
    child:ScaleTransition(scale:_winScale,child:Center(child:Column(
      mainAxisAlignment:MainAxisAlignment.center,children:[
        Container(width:100,height:100,
          decoration:BoxDecoration(gradient:const LinearGradient(colors:[kGold,Color(0xFFFFE066)]),
            shape:BoxShape.circle,boxShadow:[BoxShadow(color:kGold.withOpacity(0.6),blurRadius:28,spreadRadius:4)]),
          child:const Center(child:Text('🎓',style:TextStyle(fontSize:50)))),
        const SizedBox(height:18),
        const Text('Сессия сдана!',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:Colors.white)),
        const SizedBox(height:10),
        Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:8),
          decoration:BoxDecoration(gradient:const LinearGradient(colors:[kGold,Color(0xFFFFA726)]),
            borderRadius:BorderRadius.circular(14)),
          child:Text('+$_score очков  •  $_coinsGot зачёток',
            style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w800))),
      ])))));

  Widget _deadOverlay()=>Positioned.fill(child:Container(
    color:Colors.black.withOpacity(0.65),
    child:ScaleTransition(scale:_deadScale,child:Center(child:Column(
      mainAxisAlignment:MainAxisAlignment.center,children:[
        Container(width:100,height:100,
          decoration:BoxDecoration(color:kRed.withOpacity(0.12),shape:BoxShape.circle,
            border:Border.all(color:kRed,width:3),
            boxShadow:[BoxShadow(color:kRed.withOpacity(0.3),blurRadius:20)]),
          child:const Center(child:Text('😵',style:TextStyle(fontSize:50)))),
        const SizedBox(height:18),
        const Text('Отчислен!',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:Colors.white)),
        const SizedBox(height:8),
        Text('Собрано зачёток: $_coinsGot',
          style:const TextStyle(fontSize:15,color:kGold,fontWeight:FontWeight.w600)),
        const SizedBox(height:6),
        Text('Попробуй ещё раз! 💪',
          style:TextStyle(color:Colors.white.withOpacity(0.5),fontSize:13)),
      ])))));
}

// ═══════════════════════════════════════════════════════════════════════════
//  Единый CustomPainter — рисует ВСЁ: фон, препятствия, монеты, игрока
// ═══════════════════════════════════════════════════════════════════════════
class _ScenePainter extends CustomPainter {
  final List<_Obs>  obstacles;
  final List<_Coin> coins;
  final double playerY, velY, w, h, coinPulse;
  final bool isDead;

  const _ScenePainter({
    required this.obstacles, required this.coins,
    required this.playerY, required this.velY,
    required this.w, required this.h,
    required this.isDead, required this.coinPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBg(canvas, size);
    for (final o in obstacles) _drawObs(canvas, size, o);
    for (final c in coins)     _drawCoin(canvas, c);
    _drawPlayer(canvas);
  }

  // ── Фон: коридор ──────────────────────────────────────────────────────────
  void _drawBg(Canvas canvas, Size size) {
    // Небо
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,size.height),
      Paint()..shader=const LinearGradient(
        colors:[Color(0xFF0D1545),Color(0xFF1A237E)],
        begin:Alignment.topCenter,end:Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0,0,size.width,size.height)));

    // Потолок
    canvas.drawRect(Rect.fromLTWH(0,0,size.width,28),
      Paint()..color=const Color(0xFF1A237E));

    // Пол
    canvas.drawRect(Rect.fromLTWH(0,size.height-38,size.width,38),
      Paint()..color=const Color(0xFF283593));
    final tp = Paint()..color=const Color(0xFF3949AB).withOpacity(0.45)..strokeWidth=1;
    for(double y=size.height-38;y<size.height;y+=10)
      canvas.drawLine(Offset(0,y),Offset(size.width,y),tp);

    // Перспективные линии
    final pp = Paint()..color=const Color(0xFF3949AB).withOpacity(0.22)..strokeWidth=1;
    final cx=size.width/2, cy=size.height/2;
    for(int i=0;i<=5;i++){
      final x=size.width*i/5;
      canvas.drawLine(Offset(x,0),Offset(cx+(x-cx)*0.28,cy),pp);
      canvas.drawLine(Offset(x,size.height),Offset(cx+(x-cx)*0.28,cy),pp);
    }

    // Лампы
    final lp = Paint()..color=kGold.withOpacity(0.4);
    for(double x=55;x<size.width;x+=110){
      canvas.drawRect(Rect.fromLTWH(x-7,28,14,6),lp);
      final path=Path()
        ..moveTo(x-7,34)..lineTo(x-18,76)..lineTo(x+18,76)..lineTo(x+7,34)..close();
      canvas.drawPath(path,Paint()..color=kGold.withOpacity(0.07));
    }
  }

  // ── Препятствие — пара стен с дверью ─────────────────────────────────────
  void _drawObs(Canvas canvas, Size size, _Obs o) {
    // Верхняя стена
    _drawWall(canvas, Rect.fromLTWH(o.x, 0, _pipeW, o.gapTop), isTop: true);
    // Нижняя стена
    final botY = o.gapTop + _pipeGap;
    _drawWall(canvas, Rect.fromLTWH(o.x, botY, _pipeW, size.height - botY), isTop: false);

    // Обвязка зазора (рамка)
    final framePaint = Paint()..color=const Color(0xFFB87333);
    canvas.drawRect(Rect.fromLTWH(o.x, o.gapTop-7, _pipeW, 7), framePaint);
    canvas.drawRect(Rect.fromLTWH(o.x, o.gapTop+_pipeGap, _pipeW, 7), framePaint);

    // Тень у зазора
    final shPaint = Paint()
      ..shader=LinearGradient(
        colors:[Colors.black.withOpacity(0.4),Colors.transparent],
        begin:Alignment.topCenter,end:Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(o.x,o.gapTop,_pipeW,24));
    canvas.drawRect(Rect.fromLTWH(o.x,o.gapTop,_pipeW,24),shPaint);
  }

  void _drawWall(Canvas canvas, Rect rect, {required bool isTop}) {
    // Заливка стены
    final wallPaint = Paint()
      ..shader=LinearGradient(
        colors:isTop
          ?[const Color(0xFF1A237E),const Color(0xFF283593)]
          :[const Color(0xFF283593),const Color(0xFF1A237E)],
        begin:Alignment.topCenter,end:Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect,wallPaint);

    // Горизонтальные полосы (плитка)
    final tilePaint = Paint()..color=const Color(0xFF3949AB).withOpacity(0.45)..strokeWidth=1;
    for(double y=rect.top;y<rect.bottom;y+=18)
      canvas.drawLine(Offset(rect.left,y),Offset(rect.right,y),tilePaint);

    // Дверь
    final dh = (rect.height*0.38).clamp(28.0,82.0);
    final dy = isTop ? rect.bottom-dh-3 : rect.top+3;
    final doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left+5, dy, rect.width-10, dh),
      const Radius.circular(5));
    canvas.drawRRect(doorRect, Paint()..color=const Color(0xFF5C6BC0));

    // Рамка двери
    canvas.drawRRect(doorRect,
      Paint()..color=const Color(0xFF7986CB)..style=PaintingStyle.stroke..strokeWidth=1.5);

    // Ручка
    canvas.drawCircle(
      Offset(rect.left+rect.width*0.65, dy+dh/2), 4,
      Paint()..color=kGold);

    // Вертикальная панель двери
    canvas.drawLine(
      Offset(rect.left+rect.width/2, dy+4),
      Offset(rect.left+rect.width/2, dy+dh-4),
      Paint()..color=const Color(0xFF7986CB).withOpacity(0.6)..strokeWidth=1);

    // Надпись
    final ts = TextSpan(text:'АУДИТ.',
      style:TextStyle(color:Colors.white.withOpacity(0.35),fontSize:7,fontWeight:FontWeight.w700));
    final tp = TextPainter(text:ts,textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(rect.left+(rect.width-tp.width)/2,
      isTop ? rect.top+6 : rect.bottom-tp.height-6));
  }

  // ── Монета — зачётка ─────────────────────────────────────────────────────
  void _drawCoin(Canvas canvas, _Coin c) {
    final r = 14.0 * coinPulse;
    canvas.drawCircle(Offset(c.x,c.y), r,
      Paint()..shader=RadialGradient(
        colors:[const Color(0xFFFFE066),kGold],
      ).createShader(Rect.fromCircle(center:Offset(c.x,c.y),radius:r)));
    // Блик
    canvas.drawCircle(Offset(c.x,c.y),r,
      Paint()..color=kGold.withOpacity(0.5)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
    // Иконка — маленький книжный символ
    final ts = const TextSpan(text:'📋',style:TextStyle(fontSize:14));
    final tp = TextPainter(text:ts,textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(c.x-tp.width/2,c.y-tp.height/2));
  }

  // ── Игрок ─────────────────────────────────────────────────────────────────
  void _drawPlayer(Canvas canvas) {
    final cx = 78.0, cy = playerY;
    final angle = (velY / 600).clamp(-0.5, 0.6);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Свечение
    canvas.drawCircle(Offset.zero, _playerW/2+4,
      Paint()..color=(isDead?kRed:kGreen).withOpacity(0.35)
        ..maskFilter=const MaskFilter.blur(BlurStyle.normal,10));

    // Круг
    canvas.drawCircle(Offset.zero, _playerW/2,
      Paint()..shader=(isDead
        ?const LinearGradient(colors:[kRed,Color(0xFFFF8E53)])
        :const LinearGradient(colors:[kBlue,kGreen])
      ).createShader(Rect.fromCircle(center:Offset.zero,radius:_playerW/2)));

    // Эмодзи
    final ts = TextSpan(text:isDead?'😵':'🎓',style:const TextStyle(fontSize:26));
    final tp = TextPainter(text:ts,textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(-tp.width/2,-tp.height/2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}