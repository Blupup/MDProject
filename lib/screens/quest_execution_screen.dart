// ignore_for_file: prefer_const_constructors, duplicate_ignore, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class QuestExecutionScreen extends StatefulWidget {
  final String questId;

  const QuestExecutionScreen({super.key, this.questId = 'b_corpus_intro'});

  @override
  State<QuestExecutionScreen> createState() => _QuestExecutionScreenState();
}

class _QuestExecutionScreenState extends State<QuestExecutionScreen> {
  int _currentTaskIndex = 0;
  bool _isTaskCompleted = false;

  final List<QuestTask> _tasks = [
    // ignore: prefer_const_constructors
    QuestTask(
      number: 1,
      title: 'Начало пути',
      description: 'Найди главный вход Б-корпуса',
      hint: 'Ищи большую стеклянную дверь с вывеской "Б-корпус"',
      location: 'Главный вход',
      icon: Icons.flag_rounded,
    ),
    QuestTask(
      number: 2,
      title: 'Библиотека',
      description: 'Найди библиотеку на 2 этаже',
      hint: 'Поднимись по главной лестнице и поверни налево',
      location: '2 этаж, левое крыло',
      icon: Icons.menu_book_rounded,
    ),
    QuestTask(
      number: 3,
      title: 'Столовая',
      description: 'Найди столовую на 1 этаже',
      hint: 'Пройди по коридору от главного входа прямо',
      location: '1 этаж, правое крыло',
      icon: Icons.restaurant_rounded,
    ),
  ];

  void _completeTask() {
    setState(() {
      _isTaskCompleted = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Задание "${_tasks[_currentTaskIndex].title}" выполнено!'),
        backgroundColor: const Color(0xFF00D4AA),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextTask() {
    if (_currentTaskIndex < _tasks.length - 1) {
      setState(() {
        _currentTaskIndex++;
        _isTaskCompleted = false;
      });
    } else {
      _completeQuest();
    }
  }

  void _previousTask() {
    if (_currentTaskIndex > 0) {
      setState(() {
        _currentTaskIndex--;
        _isTaskCompleted = false;
      });
    }
  }

  void _completeQuest() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF151A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF2E86AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Поздравляем!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Вы успешно завершили квест "Знакомство с Б-корпусом"!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Отлично!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF151A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Подсказка',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _tasks[_currentTaskIndex].hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Понятно',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = _tasks[_currentTaskIndex];
    final progress = (_currentTaskIndex / _tasks.length);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2D),
      body: SafeArea(
        child: Column(
          children: [
            // Кастомный AppBar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A0F2D),
                    const Color(0xFF151A3A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Выполнение квеста',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _showHint,
                    tooltip: 'Подсказка',
                  ),
                ],
              ),
            ),
            
            // Прогресс бар
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1E2344),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Задание ${_currentTaskIndex + 1} из ${_tasks.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF00D4AA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: Stack(
                children: [
                  // Фоновые элементы
                  Positioned(
                    top: 100,
                    right: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2E86AB).withOpacity(0.1),
                            const Color(0xFF0A0F2D).withOpacity(0.01),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Текущее задание
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4AA).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      currentTask.icon,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    currentTask.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentTask.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        currentTask.location,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Статус выполнения
                        if (_isTaskCompleted)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00D4AA),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00D4AA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Задание выполнено! Можете переходить к следующему.',
                                    style: TextStyle(
                                      color: Color(0xFF00D4AA),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA726).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFA726),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFA726),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Найдите указанное место и отметьте выполнение задания',
                                    style: TextStyle(
                                      color: Color(0xFFFFA726),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 32),
                        
                        // Инструкции
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151A3A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Что нужно сделать:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _InstructionItem(
                                icon: Icons.directions_walk_rounded,
                                text: 'Найдите указанное место в Б-корпусе',
                              ),
                              const SizedBox(height: 12),
                              const _InstructionItem(
                                icon: Icons.qr_code_scanner_rounded,
                                text: 'Отсканируйте QR-код или нажмите кнопку выполнения',
                              ),
                              const SizedBox(height: 12),
                              const _InstructionItem(
                                icon: Icons.verified_rounded,
                                text: 'Получите подтверждение и переходите к следующему заданию',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Нижняя панель с кнопками
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A0F2D).withOpacity(0.9),
                    const Color(0xFF0A0F2D),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  if (_currentTaskIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousTask,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Назад',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_currentTaskIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _isTaskCompleted 
                            ? const LinearGradient(
                                colors: [Color(0xFF00D4AA), Color(0xFF00A886)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF2E86AB), Color(0xFF00D4AA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isTaskCompleted ? const Color(0xFF00D4AA) : const Color(0xFF2E86AB)).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isTaskCompleted ? _nextTask : _completeTask,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isTaskCompleted && _currentTaskIndex == _tasks.length - 1)
                                  const Icon(
                                    Icons.celebration_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                if (_isTaskCompleted && _currentTaskIndex < _tasks.length - 1)
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                if (!_isTaskCompleted)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isTaskCompleted 
                                      ? _currentTaskIndex == _tasks.length - 1 
                                          ? 'Завершить квест' 
                                          : 'Следующее задание'
                                      : 'Выполнил задание',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestTask {
  final int number;
  final String title;
  final String description;
  final String hint;
  final String location;
  final IconData icon;

  const QuestTask({
    required this.number,
    required this.title,
    required this.description,
    required this.hint,
    required this.location,
    required this.icon,
  });
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2344),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2E86AB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}