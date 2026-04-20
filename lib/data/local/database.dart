import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const localUserId = 'local-user';

enum ProjectStatus { active, paused, archived }

enum TaskStatus { todo, inProgress, done, archived }

enum PomodoroSessionType { work, shortBreak, longBreak }

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is List) {
      return decoded.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable().withLength(max: 200)();
  TextColumn get color => text().withDefault(const Constant('#0075de'))();
  TextColumn get status =>
      text().withDefault(Constant(ProjectStatus.active.name))();
  TextColumn get techTags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get gitUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get projectId => text().nullable()();
  TextColumn get parentTaskId => text().nullable()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable().withLength(max: 1000)();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get estimatedPomodoros =>
      integer().withDefault(const Constant(0))();
  IntColumn get actualPomodoros => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(Constant(TaskStatus.todo.name))();
  TextColumn get tags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PomodoroSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get taskId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
  TextColumn get type =>
      text().withDefault(Constant(PomodoroSessionType.work.name))();
  TextColumn get note => text().nullable().withLength(max: 200)();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get projectId => text().nullable()();
  TextColumn get taskId => text().nullable()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get note => text().nullable().withLength(max: 1000)();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UserPreferences extends Table {
  TextColumn get userId => text()();
  IntColumn get workDuration => integer().withDefault(const Constant(25))();
  IntColumn get shortBreakDuration =>
      integer().withDefault(const Constant(5))();
  IntColumn get longBreakDuration =>
      integer().withDefault(const Constant(15))();
  IntColumn get longBreakInterval => integer().withDefault(const Constant(4))();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get soundVolume => integer().withDefault(const Constant(70))();
  BoolColumn get autoStartNext =>
      boolean().withDefault(const Constant(false))();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  TextColumn get accentColor => text().withDefault(const Constant('#0075de'))();
  IntColumn get weekStartsOn => integer().withDefault(const Constant(1))();
  TextColumn get dateFormat =>
      text().withDefault(const Constant('YYYY-MM-DD'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [Projects, Tasks, PomodoroSessions, CalendarEvents, UserPreferences],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sakunaflow'));

  AppDatabase.forTesting(super.executor);

  final _uuid = const Uuid();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
  );

  Future<void> seedDemoData({DateTime? now}) async {
    final existing = await select(projects).get();
    if (existing.isNotEmpty) return;

    final stamp = now ?? DateTime.now();
    await transaction(() async {
      await into(userPreferences).insert(
        UserPreferencesCompanion.insert(userId: localUserId, updatedAt: stamp),
      );

      await batch(
        (batch) => batch.insertAll(projects, [
          ProjectsCompanion.insert(
            id: 'project-sakunaflow',
            name: 'SakunaFlow',
            description: const Value('個人開發者任務管理 app'),
            color: const Value('#8c52ff'),
            techTags: const Value(['Flutter', 'Dart']),
            sortOrder: const Value(0),
            createdAt: stamp,
            updatedAt: stamp,
          ),
          ProjectsCompanion.insert(
            id: 'project-portfolio',
            name: '個人網站 v3',
            description: const Value('Portfolio 全面翻新'),
            color: const Value('#0075de'),
            techTags: const Value(['Next.js', 'TypeScript']),
            sortOrder: const Value(1),
            createdAt: stamp,
            updatedAt: stamp,
          ),
          ProjectsCompanion.insert(
            id: 'project-homeserver',
            name: 'HomeServer',
            description: const Value('家用伺服器基礎設施'),
            color: const Value('#2a9d99'),
            status: Value(ProjectStatus.paused.name),
            techTags: const Value(['Docker', 'Nginx', 'Linux']),
            sortOrder: const Value(2),
            createdAt: stamp,
            updatedAt: stamp,
          ),
        ]),
      );

      await batch(
        (batch) => batch.insertAll(tasks, [
          _taskSeed(
            id: 'task-sync-push',
            projectId: 'project-sakunaflow',
            title: '實作 SyncService push 機制',
            status: TaskStatus.inProgress,
            priority: 1,
            estimatedPomodoros: 3,
            actualPomodoros: 2,
            dueDate: stamp,
            sortOrder: 0,
            now: stamp,
          ),
          _taskSeed(
            id: 'task-calendar-ui',
            projectId: 'project-sakunaflow',
            title: '設計 CalendarScreen UI',
            priority: 2,
            estimatedPomodoros: 2,
            dueDate: stamp,
            sortOrder: 1,
            now: stamp,
          ),
          _taskSeed(
            id: 'task-pomodoro-bg',
            projectId: 'project-sakunaflow',
            title: '修復番茄鐘背景計時 bug',
            priority: 0,
            estimatedPomodoros: 1,
            dueDate: stamp,
            sortOrder: 2,
            now: stamp,
          ),
          _taskSeed(
            id: 'task-hero',
            projectId: 'project-portfolio',
            title: '撰寫首頁 Hero 區塊',
            priority: 2,
            estimatedPomodoros: 1,
            dueDate: stamp.add(const Duration(days: 1)),
            sortOrder: 3,
            now: stamp,
          ),
          _taskSeed(
            id: 'task-seo',
            projectId: 'project-portfolio',
            title: '設定 SEO meta tags',
            status: TaskStatus.done,
            priority: 3,
            estimatedPomodoros: 1,
            actualPomodoros: 1,
            completedAt: stamp.subtract(const Duration(days: 1)),
            sortOrder: 4,
            now: stamp,
          ),
          _taskSeed(
            id: 'task-flight',
            title: '訂機票（5月回台南）',
            priority: 2,
            dueDate: stamp,
            sortOrder: 5,
            now: stamp,
          ),
        ]),
      );

      await into(calendarEvents).insert(
        CalendarEventsCompanion.insert(
          id: 'event-review',
          projectId: const Value('project-sakunaflow'),
          title: 'Phase 1 review',
          note: const Value('檢查本地核心與 UI flow'),
          startAt: stamp.add(const Duration(hours: 15)),
          endAt: stamp.add(const Duration(hours: 16)),
          color: const Value('#dd5b00'),
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
    });
  }

  TasksCompanion _taskSeed({
    required String id,
    String? projectId,
    required String title,
    TaskStatus status = TaskStatus.todo,
    int priority = 2,
    int estimatedPomodoros = 0,
    int actualPomodoros = 0,
    DateTime? dueDate,
    DateTime? completedAt,
    required int sortOrder,
    required DateTime now,
  }) {
    return TasksCompanion.insert(
      id: id,
      projectId: Value(projectId),
      title: title,
      priority: Value(priority),
      dueDate: Value(dueDate),
      estimatedPomodoros: Value(estimatedPomodoros),
      actualPomodoros: Value(actualPomodoros),
      status: Value(status.name),
      sortOrder: Value(sortOrder),
      completedAt: Value(completedAt),
      createdAt: now,
      updatedAt: now,
    );
  }

  Stream<List<Project>> watchProjects({bool includeArchived = false}) {
    final query = select(projects)
      ..where((project) => project.deletedAt.isNull())
      ..orderBy([(project) => OrderingTerm.asc(project.sortOrder)]);

    return query.watch().map((items) {
      if (includeArchived) return items;
      return items
          .where((project) => project.status != ProjectStatus.archived.name)
          .toList(growable: false);
    });
  }

  Future<Project> createProject({
    required String name,
    String? description,
    String color = '#0075de',
    List<String> techTags = const [],
    String? gitUrl,
    DateTime? now,
  }) async {
    final stamp = now ?? DateTime.now();
    final id = _uuid.v4();
    final maxOrder = await _maxSortOrder('projects');
    await into(projects).insert(
      ProjectsCompanion.insert(
        id: id,
        name: name.trim(),
        description: Value(_blankToNull(description)),
        color: Value(color),
        techTags: Value(techTags),
        gitUrl: Value(_blankToNull(gitUrl)),
        sortOrder: Value(maxOrder + 1),
        createdAt: stamp,
        updatedAt: stamp,
      ),
    );
    return getProject(id);
  }

  Future<Project> getProject(String id) {
    return (select(
      projects,
    )..where((project) => project.id.equals(id))).getSingle();
  }

  Future<void> updateProjectStatus(
    String id,
    ProjectStatus status, {
    DateTime? now,
  }) {
    return (update(projects)..where((project) => project.id.equals(id))).write(
      ProjectsCompanion(
        status: Value(status.name),
        updatedAt: Value(now ?? DateTime.now()),
      ),
    );
  }

  Future<void> softDeleteProject(String id, {DateTime? now}) async {
    final stamp = now ?? DateTime.now();
    await transaction(() async {
      await (update(projects)..where((project) => project.id.equals(id))).write(
        ProjectsCompanion(deletedAt: Value(stamp), updatedAt: Value(stamp)),
      );
      await (update(tasks)..where((task) => task.projectId.equals(id))).write(
        TasksCompanion(deletedAt: Value(stamp), updatedAt: Value(stamp)),
      );
    });
  }

  Stream<List<Task>> watchTasks() {
    return (select(tasks)
          ..where((task) => task.deletedAt.isNull())
          ..orderBy([(task) => OrderingTerm.asc(task.sortOrder)]))
        .watch();
  }

  Stream<List<Task>> watchProjectTasks(String projectId) {
    return watchTasks().map(
      (items) => items
          .where((task) => task.projectId == projectId)
          .toList(growable: false),
    );
  }

  Stream<List<Task>> watchTodayTasks(DateTime now) {
    return watchTasks().map((items) {
      final today = _filterTodayTasks(items, now);
      today.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return today;
    });
  }

  Future<List<Task>> getTodayTasks(DateTime now) async {
    final items =
        await (select(tasks)
              ..where((task) => task.deletedAt.isNull())
              ..orderBy([(task) => OrderingTerm.asc(task.sortOrder)]))
            .get();
    return _filterTodayTasks(items, now);
  }

  Future<Task> createTask({
    required String title,
    String? description,
    String? projectId,
    String? parentTaskId,
    int priority = 2,
    int estimatedPomodoros = 0,
    DateTime? dueDate,
    List<String> tags = const [],
    DateTime? now,
  }) async {
    final stamp = now ?? DateTime.now();
    final id = _uuid.v4();
    final maxOrder = await _maxSortOrder('tasks');
    await into(tasks).insert(
      TasksCompanion.insert(
        id: id,
        projectId: Value(projectId),
        parentTaskId: Value(parentTaskId),
        title: title.trim(),
        description: Value(_blankToNull(description)),
        priority: Value(priority),
        dueDate: Value(dueDate),
        estimatedPomodoros: Value(estimatedPomodoros),
        tags: Value(tags),
        sortOrder: Value(maxOrder + 1),
        createdAt: stamp,
        updatedAt: stamp,
      ),
    );
    return getTask(id);
  }

  Future<Task> getTask(String id) {
    return (select(tasks)..where((task) => task.id.equals(id))).getSingle();
  }

  Future<void> updateTaskStatus(
    String id,
    TaskStatus status, {
    DateTime? now,
  }) async {
    final stamp = now ?? DateTime.now();
    await (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        status: Value(status.name),
        completedAt: status == TaskStatus.done
            ? Value(stamp)
            : const Value.absent(),
        updatedAt: Value(stamp),
      ),
    );
  }

  Future<void> completeTask(String id, {DateTime? now}) {
    return updateTaskStatus(id, TaskStatus.done, now: now);
  }

  Future<void> softDeleteTask(String id, {DateTime? now}) {
    final stamp = now ?? DateTime.now();
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(deletedAt: Value(stamp), updatedAt: Value(stamp)),
    );
  }

  Future<PomodoroSession> addPomodoroSession({
    required String taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationMinutes,
    required PomodoroSessionType type,
    required bool completed,
    String? note,
  }) async {
    final id = _uuid.v4();
    return transaction(() async {
      await into(pomodoroSessions).insert(
        PomodoroSessionsCompanion.insert(
          id: id,
          taskId: taskId,
          startedAt: startedAt,
          endedAt: endedAt,
          durationMinutes: durationMinutes,
          type: Value(type.name),
          completed: Value(completed),
          note: Value(_blankToNull(note)),
          createdAt: DateTime.now(),
        ),
      );

      if (completed && type == PomodoroSessionType.work) {
        final task = await getTask(taskId);
        await (update(tasks)..where((row) => row.id.equals(taskId))).write(
          TasksCompanion(
            actualPomodoros: Value(task.actualPomodoros + 1),
            updatedAt: Value(endedAt),
          ),
        );
      }

      return (select(
        pomodoroSessions,
      )..where((session) => session.id.equals(id))).getSingle();
    });
  }

  Future<List<PomodoroSession>> sessionsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final all = await (select(
      pomodoroSessions,
    )..orderBy([(session) => OrderingTerm.asc(session.startedAt)])).get();
    return all
        .where(
          (session) =>
              !session.startedAt.isBefore(start) &&
              session.startedAt.isBefore(end),
        )
        .toList(growable: false);
  }

  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return (select(calendarEvents)
          ..where((event) => event.deletedAt.isNull())
          ..orderBy([(event) => OrderingTerm.asc(event.startAt)]))
        .watch()
        .map(
          (events) => events
              .where(
                (event) =>
                    event.endAt.isAfter(start) && event.startAt.isBefore(end),
              )
              .toList(growable: false),
        );
  }

  Future<CalendarEvent> createCalendarEvent({
    required String title,
    String? note,
    String? projectId,
    String? taskId,
    required DateTime startAt,
    required DateTime endAt,
    String? color,
    DateTime? now,
  }) async {
    final stamp = now ?? DateTime.now();
    final id = _uuid.v4();
    await into(calendarEvents).insert(
      CalendarEventsCompanion.insert(
        id: id,
        title: title.trim(),
        note: Value(_blankToNull(note)),
        projectId: Value(projectId),
        taskId: Value(taskId),
        startAt: startAt,
        endAt: endAt,
        color: Value(_blankToNull(color)),
        createdAt: stamp,
        updatedAt: stamp,
      ),
    );
    return (select(
      calendarEvents,
    )..where((event) => event.id.equals(id))).getSingle();
  }

  Future<UserPreference> getPreferences() {
    return (select(userPreferences)
          ..where((preference) => preference.userId.equals(localUserId)))
        .getSingle();
  }

  Stream<UserPreference> watchPreferences() {
    return (select(userPreferences)
          ..where((preference) => preference.userId.equals(localUserId)))
        .watchSingle();
  }

  Future<void> updatePomodoroDurations({
    required int workDuration,
    required int shortBreakDuration,
    required int longBreakDuration,
    required int longBreakInterval,
    DateTime? now,
  }) {
    return (update(
      userPreferences,
    )..where((preference) => preference.userId.equals(localUserId))).write(
      UserPreferencesCompanion(
        workDuration: Value(workDuration.clamp(5, 60)),
        shortBreakDuration: Value(shortBreakDuration.clamp(5, 60)),
        longBreakDuration: Value(longBreakDuration.clamp(5, 60)),
        longBreakInterval: Value(longBreakInterval.clamp(2, 8)),
        updatedAt: Value(now ?? DateTime.now()),
      ),
    );
  }

  Future<int> _maxSortOrder(String tableName) async {
    final rows = await customSelect(
      'SELECT COALESCE(MAX(sort_order), -1) AS max_order FROM $tableName',
    ).get();
    return rows.single.read<int>('max_order');
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  List<Task> _filterTodayTasks(List<Task> items, DateTime now) {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return items
        .where((task) {
          if (task.status == TaskStatus.archived.name) {
            return false;
          }
          final due = task.dueDate;
          final completedAt = task.completedAt;
          return task.status == TaskStatus.inProgress.name ||
              (due != null && !due.isAfter(endOfToday)) ||
              (completedAt != null && _isSameDay(completedAt, now));
        })
        .toList(growable: false);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
