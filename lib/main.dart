import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const HabitQuestApp());
}

class HabitQuestApp extends StatelessWidget {
  const HabitQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitQuest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum Rarity { common, rare, epic, legendary }

extension RarityX on Rarity {
  String get label {
    switch (this) {
      case Rarity.common:
        return 'Обычный';
      case Rarity.rare:
        return 'Редкий';
      case Rarity.epic:
        return 'Эпический';
      case Rarity.legendary:
        return 'Легендарный';
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.rare:
        return Colors.blue;
      case Rarity.epic:
        return Colors.purple;
      case Rarity.legendary:
        return Colors.orange;
    }
  }
}

class Artifact {
  final String name;
  final String description;
  final Rarity rarity;
  final double xpMultiplier;
  final double goldMultiplier;
  final bool shieldStreak;

  Artifact({
    required this.name,
    required this.description,
    required this.rarity,
    this.xpMultiplier = 1.0,
    this.goldMultiplier = 1.0,
    this.shieldStreak = false,
  });
}

class Habit {
  final String title;
  final String description;
  final int baseXp;
  final int baseGold;
  int streak;
  DateTime? lastDone;

  Habit({
    required this.title,
    required this.description,
    this.baseXp = 10,
    this.baseGold = 5,
    this.streak = 0,
    this.lastDone,
  });
}

class Quest {
  final String name;
  final String narrative;
  final List<Habit> steps;
  bool claimedReward;

  Quest({
    required this.name,
    required this.narrative,
    required this.steps,
    this.claimedReward = false,
  });

  bool get isCompleted => steps.every((h) => h.streak >= 1);
}

class Player {
  int level;
  int xp;
  int gold;
  List<Artifact> inventory;

  Player({
    this.level = 1,
    this.xp = 0,
    this.gold = 0,
    List<Artifact>? inventory,
  }) : inventory = inventory ?? [];

  int xpToNextLevel() => level * 100;

  void addRewards(int rawXp, int rawGold, {Iterable<Artifact> effects = const []}) {
    double xpMult = 1.0;
    double goldMult = 1.0;
    for (final a in inventory) {
      xpMult *= a.xpMultiplier;
      goldMult *= a.goldMultiplier;
    }
    for (final a in effects) {
      xpMult *= a.xpMultiplier;
      goldMult *= a.goldMultiplier;
    }

    xp += (rawXp * xpMult).round();
    gold += (rawGold * goldMult).round();

    while (xp >= xpToNextLevel()) {
      xp -= xpToNextLevel();
      level++;
    }
  }
}

class GameService with ChangeNotifier {
  final Random _rng = Random();

  late Player player;
  late List<Habit> habits;
  late List<Quest> quests;

  GameService() {
    player = Player();
    habits = _defaultHabits();
    quests = _defaultQuests();
  }

  List<Habit> _defaultHabits() => [
        Habit(title: 'Утренняя вода', description: 'Выпить стакан воды сразу после пробуждения'),
        Habit(title: '10 минут чтения', description: 'Прочитать минимум 10 минут'),
        Habit(title: 'Фокус-сессия', description: '25 минут без отвлечений'),
        Habit(title: 'Прогулка', description: 'Минимум 15 минут на свежем воздухе'),
      ];

  List<Quest> _defaultQuests() => [
        Quest(
          name: 'Утренняя рутина',
          narrative: 'Собери энергию дня: вода + фокус!',
          steps: [
            Habit(title: 'Стакан воды', description: 'Запускаем метаболизм', baseXp: 12, baseGold: 5),
            Habit(title: '5 минут планирования', description: 'Список задач на день', baseXp: 15, baseGold: 7),
          ],
        ),
        Quest(
          name: '30 дней фитнеса',
          narrative: 'Стань сильнее с ежедневной активностью.',
          steps: [
            Habit(title: 'Разминка', description: '5–10 минут', baseXp: 10, baseGold: 5),
            Habit(title: 'Тренировка', description: 'Минимум 20 минут', baseXp: 20, baseGold: 10),
          ],
        ),
        Quest(
          name: 'Марафон чтения',
          narrative: 'Погрузи мозг в поток знаний.',
          steps: [
            Habit(title: 'Чтение 10 мин', description: 'Каждый день без пропусков', baseXp: 12, baseGold: 6),
          ],
        ),
      ];

  Artifact _randomChestDrop() {
    final roll = _rng.nextDouble();
    if (roll < 0.60) {
      return Artifact(
          name: 'Кольцо дисциплины',
          description: '+5% к золоту',
          rarity: Rarity.common,
          goldMultiplier: 1.05);
    } else if (roll < 0.85) {
      return Artifact(
          name: 'Амулет продуктивности',
          description: '+10% к XP',
          rarity: Rarity.rare,
          xpMultiplier: 1.10);
    } else if (roll < 0.97) {
      return Artifact(
          name: 'Меч фокусировки',
          description: '+15% к XP и золоту',
          rarity: Rarity.epic,
          xpMultiplier: 1.15,
          goldMultiplier: 1.15);
    } else {
      return Artifact(
          name: 'Корона мастера',
          description: '+25% к XP',
          rarity: Rarity.legendary,
          xpMultiplier: 1.25);
    }
  }

  void completeHabit(Habit h) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (h.lastDone != null) {
      final last = DateTime(h.lastDone!.year, h.lastDone!.month, h.lastDone!.day);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        h.streak += 1;
      } else if (diff == 0) {
      } else {
        h.streak = 0;
      }
    } else {
      h.streak = 1;
    }
    h.lastDone = now;

    player.addRewards(h.baseXp, h.baseGold);

    if ([3, 7, 14].contains(h.streak)) {
      player.inventory.add(_randomChestDrop());
    }
    notifyListeners();
  }

  void claimQuestReward(Quest q) {
    if (q.isCompleted && !q.claimedReward) {
      q.claimedReward = true;
      player.addRewards(50, 30);
      player.inventory.add(_randomChestDrop());
      notifyListeners();
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService game = GameService();
  int index = 0;

  @override
  void initState() {
    super.initState();
    game.addListener(_refresh);
  }

  @override
  void dispose() {
    game.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HabitsTab(game: game),
      QuestsTab(game: game),
      InventoryTab(game: game),
      ProfileTab(game: game),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('HabitQuest')),
      body: tabs[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Привычки'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Квесты'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Инвентарь'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}

class HabitsTab extends StatelessWidget {
  final GameService game;
  const HabitsTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: game.habits.length,
      itemBuilder: (context, i) {
        final h = game.habits[i];
        return Card(
          child: ListTile(
            title: Text(h.title),
            subtitle: Text('${h.description}\nСтрик: ${h.streak}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () => game.completeHabit(h),
              child: const Text('Готово'),
            ),
          ),
        );
      },
    );
  }
}

class QuestsTab extends StatelessWidget {
  final GameService game;
  const QuestsTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: game.quests.length,
      itemBuilder: (context, i) {
        final q = game.quests[i];
        return Card(
          child: ExpansionTile(
            title: Text(q.name),
            subtitle: Text(q.narrative),
            children: [
              ...q.steps.map((s) => ListTile(
                    title: Text('• ${s.title}'),
                    subtitle: Text(s.description),
                    trailing: Text('Стрик: ${s.streak}'),
                  )),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: q.isCompleted && !q.claimedReward ? () => game.claimQuestReward(q) : null,
                  child: Text(q.claimedReward ? 'Награда получена' : 'Забрать награду'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class InventoryTab extends StatelessWidget {
  final GameService game;
  const InventoryTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final items = game.player.inventory;
    if (items.isEmpty) {
      return const Center(child: Text('Инвентарь пуст — выполняй привычки и собирай лут!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final a = items[i];
        return Card(
          child: ListTile(
            leading: Icon(Icons.auto_awesome, color: a.rarity.color),
            title: Text(a.name),
            subtitle: Text('${a.description}\nРедкость: ${a.rarity.label}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class ProfileTab extends StatelessWidget {
  final GameService game;
  const ProfileTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final p = game.player;
    final xpToNext = p.xpToNextLevel();
    final progress = p.xp / xpToNext;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Уровень ${p.level}', style: Theme.of(context).textTheme.titleLarge),
                  Text('Золото: ${p.gold}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 8),
          Text('${p.xp} / $xpToNext XP до следующего уровня'),
        ],
      ),
    );
  }
}
