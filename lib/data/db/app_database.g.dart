// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMinutesMeta = const VerificationMeta(
    'startMinutes',
  );
  @override
  late final GeneratedColumn<int> startMinutes = GeneratedColumn<int>(
    'start_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('planned'),
  );
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedDateMeta = const VerificationMeta(
    'plannedDate',
  );
  @override
  late final GeneratedColumn<String> plannedDate = GeneratedColumn<String>(
    'planned_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalPlannedDateMeta =
      const VerificationMeta('originalPlannedDate');
  @override
  late final GeneratedColumn<String> originalPlannedDate =
      GeneratedColumn<String>(
        'original_planned_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _movedCountMeta = const VerificationMeta(
    'movedCount',
  );
  @override
  late final GeneratedColumn<int> movedCount = GeneratedColumn<int>(
    'moved_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recurrenceTemplateIdMeta =
      const VerificationMeta('recurrenceTemplateId');
  @override
  late final GeneratedColumn<int> recurrenceTemplateId = GeneratedColumn<int>(
    'recurrence_template_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    durationMinutes,
    startMinutes,
    notes,
    status,
    weekStart,
    plannedDate,
    originalPlannedDate,
    movedCount,
    recurrenceTemplateId,
    createdAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('start_minutes')) {
      context.handle(
        _startMinutesMeta,
        startMinutes.isAcceptableOrUnknown(
          data['start_minutes']!,
          _startMinutesMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('planned_date')) {
      context.handle(
        _plannedDateMeta,
        plannedDate.isAcceptableOrUnknown(
          data['planned_date']!,
          _plannedDateMeta,
        ),
      );
    }
    if (data.containsKey('original_planned_date')) {
      context.handle(
        _originalPlannedDateMeta,
        originalPlannedDate.isAcceptableOrUnknown(
          data['original_planned_date']!,
          _originalPlannedDateMeta,
        ),
      );
    }
    if (data.containsKey('moved_count')) {
      context.handle(
        _movedCountMeta,
        movedCount.isAcceptableOrUnknown(data['moved_count']!, _movedCountMeta),
      );
    }
    if (data.containsKey('recurrence_template_id')) {
      context.handle(
        _recurrenceTemplateIdMeta,
        recurrenceTemplateId.isAcceptableOrUnknown(
          data['recurrence_template_id']!,
          _recurrenceTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      startMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minutes'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      plannedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_date'],
      ),
      originalPlannedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_planned_date'],
      ),
      movedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moved_count'],
      )!,
      recurrenceTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_template_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String title;
  final int? durationMinutes;
  final int? startMinutes;
  final String? notes;
  final String status;
  final String weekStart;
  final String? plannedDate;
  final String? originalPlannedDate;
  final int movedCount;
  final int? recurrenceTemplateId;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  const Task({
    required this.id,
    required this.title,
    this.durationMinutes,
    this.startMinutes,
    this.notes,
    required this.status,
    required this.weekStart,
    this.plannedDate,
    this.originalPlannedDate,
    required this.movedCount,
    this.recurrenceTemplateId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || startMinutes != null) {
      map['start_minutes'] = Variable<int>(startMinutes);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['week_start'] = Variable<String>(weekStart);
    if (!nullToAbsent || plannedDate != null) {
      map['planned_date'] = Variable<String>(plannedDate);
    }
    if (!nullToAbsent || originalPlannedDate != null) {
      map['original_planned_date'] = Variable<String>(originalPlannedDate);
    }
    map['moved_count'] = Variable<int>(movedCount);
    if (!nullToAbsent || recurrenceTemplateId != null) {
      map['recurrence_template_id'] = Variable<int>(recurrenceTemplateId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      startMinutes: startMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinutes),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      weekStart: Value(weekStart),
      plannedDate: plannedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedDate),
      originalPlannedDate: originalPlannedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPlannedDate),
      movedCount: Value(movedCount),
      recurrenceTemplateId: recurrenceTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceTemplateId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      startMinutes: serializer.fromJson<int?>(json['startMinutes']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      plannedDate: serializer.fromJson<String?>(json['plannedDate']),
      originalPlannedDate: serializer.fromJson<String?>(
        json['originalPlannedDate'],
      ),
      movedCount: serializer.fromJson<int>(json['movedCount']),
      recurrenceTemplateId: serializer.fromJson<int?>(
        json['recurrenceTemplateId'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'startMinutes': serializer.toJson<int?>(startMinutes),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'weekStart': serializer.toJson<String>(weekStart),
      'plannedDate': serializer.toJson<String?>(plannedDate),
      'originalPlannedDate': serializer.toJson<String?>(originalPlannedDate),
      'movedCount': serializer.toJson<int>(movedCount),
      'recurrenceTemplateId': serializer.toJson<int?>(recurrenceTemplateId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'completedAt': serializer.toJson<String?>(completedAt),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    Value<int?> durationMinutes = const Value.absent(),
    Value<int?> startMinutes = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    String? weekStart,
    Value<String?> plannedDate = const Value.absent(),
    Value<String?> originalPlannedDate = const Value.absent(),
    int? movedCount,
    Value<int?> recurrenceTemplateId = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    Value<String?> completedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    startMinutes: startMinutes.present
        ? startMinutes.value
        : this.startMinutes,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    weekStart: weekStart ?? this.weekStart,
    plannedDate: plannedDate.present ? plannedDate.value : this.plannedDate,
    originalPlannedDate: originalPlannedDate.present
        ? originalPlannedDate.value
        : this.originalPlannedDate,
    movedCount: movedCount ?? this.movedCount,
    recurrenceTemplateId: recurrenceTemplateId.present
        ? recurrenceTemplateId.value
        : this.recurrenceTemplateId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      startMinutes: data.startMinutes.present
          ? data.startMinutes.value
          : this.startMinutes,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      plannedDate: data.plannedDate.present
          ? data.plannedDate.value
          : this.plannedDate,
      originalPlannedDate: data.originalPlannedDate.present
          ? data.originalPlannedDate.value
          : this.originalPlannedDate,
      movedCount: data.movedCount.present
          ? data.movedCount.value
          : this.movedCount,
      recurrenceTemplateId: data.recurrenceTemplateId.present
          ? data.recurrenceTemplateId.value
          : this.recurrenceTemplateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('weekStart: $weekStart, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('originalPlannedDate: $originalPlannedDate, ')
          ..write('movedCount: $movedCount, ')
          ..write('recurrenceTemplateId: $recurrenceTemplateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    durationMinutes,
    startMinutes,
    notes,
    status,
    weekStart,
    plannedDate,
    originalPlannedDate,
    movedCount,
    recurrenceTemplateId,
    createdAt,
    updatedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.durationMinutes == this.durationMinutes &&
          other.startMinutes == this.startMinutes &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.weekStart == this.weekStart &&
          other.plannedDate == this.plannedDate &&
          other.originalPlannedDate == this.originalPlannedDate &&
          other.movedCount == this.movedCount &&
          other.recurrenceTemplateId == this.recurrenceTemplateId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> durationMinutes;
  final Value<int?> startMinutes;
  final Value<String?> notes;
  final Value<String> status;
  final Value<String> weekStart;
  final Value<String?> plannedDate;
  final Value<String?> originalPlannedDate;
  final Value<int> movedCount;
  final Value<int?> recurrenceTemplateId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> completedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.plannedDate = const Value.absent(),
    this.originalPlannedDate = const Value.absent(),
    this.movedCount = const Value.absent(),
    this.recurrenceTemplateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.durationMinutes = const Value.absent(),
    this.startMinutes = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    required String weekStart,
    this.plannedDate = const Value.absent(),
    this.originalPlannedDate = const Value.absent(),
    this.movedCount = const Value.absent(),
    this.recurrenceTemplateId = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.completedAt = const Value.absent(),
  }) : title = Value(title),
       weekStart = Value(weekStart),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? durationMinutes,
    Expression<int>? startMinutes,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? weekStart,
    Expression<String>? plannedDate,
    Expression<String>? originalPlannedDate,
    Expression<int>? movedCount,
    Expression<int>? recurrenceTemplateId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (startMinutes != null) 'start_minutes': startMinutes,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (weekStart != null) 'week_start': weekStart,
      if (plannedDate != null) 'planned_date': plannedDate,
      if (originalPlannedDate != null)
        'original_planned_date': originalPlannedDate,
      if (movedCount != null) 'moved_count': movedCount,
      if (recurrenceTemplateId != null)
        'recurrence_template_id': recurrenceTemplateId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int?>? durationMinutes,
    Value<int?>? startMinutes,
    Value<String?>? notes,
    Value<String>? status,
    Value<String>? weekStart,
    Value<String?>? plannedDate,
    Value<String?>? originalPlannedDate,
    Value<int>? movedCount,
    Value<int?>? recurrenceTemplateId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? completedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startMinutes: startMinutes ?? this.startMinutes,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      weekStart: weekStart ?? this.weekStart,
      plannedDate: plannedDate ?? this.plannedDate,
      originalPlannedDate: originalPlannedDate ?? this.originalPlannedDate,
      movedCount: movedCount ?? this.movedCount,
      recurrenceTemplateId: recurrenceTemplateId ?? this.recurrenceTemplateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (startMinutes.present) {
      map['start_minutes'] = Variable<int>(startMinutes.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (plannedDate.present) {
      map['planned_date'] = Variable<String>(plannedDate.value);
    }
    if (originalPlannedDate.present) {
      map['original_planned_date'] = Variable<String>(
        originalPlannedDate.value,
      );
    }
    if (movedCount.present) {
      map['moved_count'] = Variable<int>(movedCount.value);
    }
    if (recurrenceTemplateId.present) {
      map['recurrence_template_id'] = Variable<int>(recurrenceTemplateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startMinutes: $startMinutes, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('weekStart: $weekStart, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('originalPlannedDate: $originalPlannedDate, ')
          ..write('movedCount: $movedCount, ')
          ..write('recurrenceTemplateId: $recurrenceTemplateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $TaskHistoriesTable extends TaskHistories
    with TableInfo<$TaskHistoriesTable, TaskHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromDateMeta = const VerificationMeta(
    'fromDate',
  );
  @override
  late final GeneratedColumn<String> fromDate = GeneratedColumn<String>(
    'from_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toDateMeta = const VerificationMeta('toDate');
  @override
  late final GeneratedColumn<String> toDate = GeneratedColumn<String>(
    'to_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    eventType,
    fromDate,
    toDate,
    timestamp,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('from_date')) {
      context.handle(
        _fromDateMeta,
        fromDate.isAcceptableOrUnknown(data['from_date']!, _fromDateMeta),
      );
    }
    if (data.containsKey('to_date')) {
      context.handle(
        _toDateMeta,
        toDate.isAcceptableOrUnknown(data['to_date']!, _toDateMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      fromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_date'],
      ),
      toDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_date'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TaskHistoriesTable createAlias(String alias) {
    return $TaskHistoriesTable(attachedDatabase, alias);
  }
}

class TaskHistory extends DataClass implements Insertable<TaskHistory> {
  final int id;
  final int taskId;
  final String eventType;
  final String? fromDate;
  final String? toDate;
  final String timestamp;
  final String? note;
  const TaskHistory({
    required this.id,
    required this.taskId,
    required this.eventType,
    this.fromDate,
    this.toDate,
    required this.timestamp,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || fromDate != null) {
      map['from_date'] = Variable<String>(fromDate);
    }
    if (!nullToAbsent || toDate != null) {
      map['to_date'] = Variable<String>(toDate);
    }
    map['timestamp'] = Variable<String>(timestamp);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TaskHistoriesCompanion toCompanion(bool nullToAbsent) {
    return TaskHistoriesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      eventType: Value(eventType),
      fromDate: fromDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fromDate),
      toDate: toDate == null && nullToAbsent
          ? const Value.absent()
          : Value(toDate),
      timestamp: Value(timestamp),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TaskHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskHistory(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      fromDate: serializer.fromJson<String?>(json['fromDate']),
      toDate: serializer.fromJson<String?>(json['toDate']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'eventType': serializer.toJson<String>(eventType),
      'fromDate': serializer.toJson<String?>(fromDate),
      'toDate': serializer.toJson<String?>(toDate),
      'timestamp': serializer.toJson<String>(timestamp),
      'note': serializer.toJson<String?>(note),
    };
  }

  TaskHistory copyWith({
    int? id,
    int? taskId,
    String? eventType,
    Value<String?> fromDate = const Value.absent(),
    Value<String?> toDate = const Value.absent(),
    String? timestamp,
    Value<String?> note = const Value.absent(),
  }) => TaskHistory(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    eventType: eventType ?? this.eventType,
    fromDate: fromDate.present ? fromDate.value : this.fromDate,
    toDate: toDate.present ? toDate.value : this.toDate,
    timestamp: timestamp ?? this.timestamp,
    note: note.present ? note.value : this.note,
  );
  TaskHistory copyWithCompanion(TaskHistoriesCompanion data) {
    return TaskHistory(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      fromDate: data.fromDate.present ? data.fromDate.value : this.fromDate,
      toDate: data.toDate.present ? data.toDate.value : this.toDate,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskHistory(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('eventType: $eventType, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, eventType, fromDate, toDate, timestamp, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskHistory &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.eventType == this.eventType &&
          other.fromDate == this.fromDate &&
          other.toDate == this.toDate &&
          other.timestamp == this.timestamp &&
          other.note == this.note);
}

class TaskHistoriesCompanion extends UpdateCompanion<TaskHistory> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> eventType;
  final Value<String?> fromDate;
  final Value<String?> toDate;
  final Value<String> timestamp;
  final Value<String?> note;
  const TaskHistoriesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.fromDate = const Value.absent(),
    this.toDate = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.note = const Value.absent(),
  });
  TaskHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required String eventType,
    this.fromDate = const Value.absent(),
    this.toDate = const Value.absent(),
    required String timestamp,
    this.note = const Value.absent(),
  }) : taskId = Value(taskId),
       eventType = Value(eventType),
       timestamp = Value(timestamp);
  static Insertable<TaskHistory> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? eventType,
    Expression<String>? fromDate,
    Expression<String>? toDate,
    Expression<String>? timestamp,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (eventType != null) 'event_type': eventType,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (timestamp != null) 'timestamp': timestamp,
      if (note != null) 'note': note,
    });
  }

  TaskHistoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? eventType,
    Value<String?>? fromDate,
    Value<String?>? toDate,
    Value<String>? timestamp,
    Value<String?>? note,
  }) {
    return TaskHistoriesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      eventType: eventType ?? this.eventType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (fromDate.present) {
      map['from_date'] = Variable<String>(fromDate.value);
    }
    if (toDate.present) {
      map['to_date'] = Variable<String>(toDate.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('eventType: $eventType, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $WeekMetasTable extends WeekMetas
    with TableInfo<$WeekMetasTable, WeekMeta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekMetasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _copyFromPreviousAppliedMeta =
      const VerificationMeta('copyFromPreviousApplied');
  @override
  late final GeneratedColumn<int> copyFromPreviousApplied =
      GeneratedColumn<int>(
        'copy_from_previous_applied',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  @override
  List<GeneratedColumn> get $columns => [weekStart, copyFromPreviousApplied];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'week_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeekMeta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('copy_from_previous_applied')) {
      context.handle(
        _copyFromPreviousAppliedMeta,
        copyFromPreviousApplied.isAcceptableOrUnknown(
          data['copy_from_previous_applied']!,
          _copyFromPreviousAppliedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weekStart};
  @override
  WeekMeta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeekMeta(
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_start'],
      )!,
      copyFromPreviousApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}copy_from_previous_applied'],
      )!,
    );
  }

  @override
  $WeekMetasTable createAlias(String alias) {
    return $WeekMetasTable(attachedDatabase, alias);
  }
}

class WeekMeta extends DataClass implements Insertable<WeekMeta> {
  final String weekStart;
  final int copyFromPreviousApplied;
  const WeekMeta({
    required this.weekStart,
    required this.copyFromPreviousApplied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['week_start'] = Variable<String>(weekStart);
    map['copy_from_previous_applied'] = Variable<int>(copyFromPreviousApplied);
    return map;
  }

  WeekMetasCompanion toCompanion(bool nullToAbsent) {
    return WeekMetasCompanion(
      weekStart: Value(weekStart),
      copyFromPreviousApplied: Value(copyFromPreviousApplied),
    );
  }

  factory WeekMeta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeekMeta(
      weekStart: serializer.fromJson<String>(json['weekStart']),
      copyFromPreviousApplied: serializer.fromJson<int>(
        json['copyFromPreviousApplied'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weekStart': serializer.toJson<String>(weekStart),
      'copyFromPreviousApplied': serializer.toJson<int>(
        copyFromPreviousApplied,
      ),
    };
  }

  WeekMeta copyWith({String? weekStart, int? copyFromPreviousApplied}) =>
      WeekMeta(
        weekStart: weekStart ?? this.weekStart,
        copyFromPreviousApplied:
            copyFromPreviousApplied ?? this.copyFromPreviousApplied,
      );
  WeekMeta copyWithCompanion(WeekMetasCompanion data) {
    return WeekMeta(
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      copyFromPreviousApplied: data.copyFromPreviousApplied.present
          ? data.copyFromPreviousApplied.value
          : this.copyFromPreviousApplied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeekMeta(')
          ..write('weekStart: $weekStart, ')
          ..write('copyFromPreviousApplied: $copyFromPreviousApplied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(weekStart, copyFromPreviousApplied);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeekMeta &&
          other.weekStart == this.weekStart &&
          other.copyFromPreviousApplied == this.copyFromPreviousApplied);
}

class WeekMetasCompanion extends UpdateCompanion<WeekMeta> {
  final Value<String> weekStart;
  final Value<int> copyFromPreviousApplied;
  final Value<int> rowid;
  const WeekMetasCompanion({
    this.weekStart = const Value.absent(),
    this.copyFromPreviousApplied = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeekMetasCompanion.insert({
    required String weekStart,
    this.copyFromPreviousApplied = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : weekStart = Value(weekStart);
  static Insertable<WeekMeta> custom({
    Expression<String>? weekStart,
    Expression<int>? copyFromPreviousApplied,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (weekStart != null) 'week_start': weekStart,
      if (copyFromPreviousApplied != null)
        'copy_from_previous_applied': copyFromPreviousApplied,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeekMetasCompanion copyWith({
    Value<String>? weekStart,
    Value<int>? copyFromPreviousApplied,
    Value<int>? rowid,
  }) {
    return WeekMetasCompanion(
      weekStart: weekStart ?? this.weekStart,
      copyFromPreviousApplied:
          copyFromPreviousApplied ?? this.copyFromPreviousApplied,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (copyFromPreviousApplied.present) {
      map['copy_from_previous_applied'] = Variable<int>(
        copyFromPreviousApplied.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeekMetasCompanion(')
          ..write('weekStart: $weekStart, ')
          ..write('copyFromPreviousApplied: $copyFromPreviousApplied, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringTemplatesTable extends RecurringTemplates
    with TableInfo<$RecurringTemplatesTable, RecurringTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeekdayMeta = const VerificationMeta(
    'targetWeekday',
  );
  @override
  late final GeneratedColumn<int> targetWeekday = GeneratedColumn<int>(
    'target_weekday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    durationMinutes,
    notes,
    targetWeekday,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('target_weekday')) {
      context.handle(
        _targetWeekdayMeta,
        targetWeekday.isAcceptableOrUnknown(
          data['target_weekday']!,
          _targetWeekdayMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      targetWeekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_weekday'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RecurringTemplatesTable createAlias(String alias) {
    return $RecurringTemplatesTable(attachedDatabase, alias);
  }
}

class RecurringTemplate extends DataClass
    implements Insertable<RecurringTemplate> {
  final int id;
  final String title;
  final int? durationMinutes;
  final String? notes;
  final int? targetWeekday;
  final int isActive;
  final String createdAt;
  const RecurringTemplate({
    required this.id,
    required this.title,
    this.durationMinutes,
    this.notes,
    this.targetWeekday,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || targetWeekday != null) {
      map['target_weekday'] = Variable<int>(targetWeekday);
    }
    map['is_active'] = Variable<int>(isActive);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  RecurringTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RecurringTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      targetWeekday: targetWeekday == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeekday),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTemplate(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      notes: serializer.fromJson<String?>(json['notes']),
      targetWeekday: serializer.fromJson<int?>(json['targetWeekday']),
      isActive: serializer.fromJson<int>(json['isActive']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'notes': serializer.toJson<String?>(notes),
      'targetWeekday': serializer.toJson<int?>(targetWeekday),
      'isActive': serializer.toJson<int>(isActive),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  RecurringTemplate copyWith({
    int? id,
    String? title,
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> targetWeekday = const Value.absent(),
    int? isActive,
    String? createdAt,
  }) => RecurringTemplate(
    id: id ?? this.id,
    title: title ?? this.title,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    notes: notes.present ? notes.value : this.notes,
    targetWeekday: targetWeekday.present
        ? targetWeekday.value
        : this.targetWeekday,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  RecurringTemplate copyWithCompanion(RecurringTemplatesCompanion data) {
    return RecurringTemplate(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      notes: data.notes.present ? data.notes.value : this.notes,
      targetWeekday: data.targetWeekday.present
          ? data.targetWeekday.value
          : this.targetWeekday,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplate(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('notes: $notes, ')
          ..write('targetWeekday: $targetWeekday, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    durationMinutes,
    notes,
    targetWeekday,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTemplate &&
          other.id == this.id &&
          other.title == this.title &&
          other.durationMinutes == this.durationMinutes &&
          other.notes == this.notes &&
          other.targetWeekday == this.targetWeekday &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class RecurringTemplatesCompanion extends UpdateCompanion<RecurringTemplate> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> durationMinutes;
  final Value<String?> notes;
  final Value<int?> targetWeekday;
  final Value<int> isActive;
  final Value<String> createdAt;
  const RecurringTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.notes = const Value.absent(),
    this.targetWeekday = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RecurringTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.durationMinutes = const Value.absent(),
    this.notes = const Value.absent(),
    this.targetWeekday = const Value.absent(),
    this.isActive = const Value.absent(),
    required String createdAt,
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<RecurringTemplate> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? durationMinutes,
    Expression<String>? notes,
    Expression<int>? targetWeekday,
    Expression<int>? isActive,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (notes != null) 'notes': notes,
      if (targetWeekday != null) 'target_weekday': targetWeekday,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RecurringTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int?>? durationMinutes,
    Value<String?>? notes,
    Value<int?>? targetWeekday,
    Value<int>? isActive,
    Value<String>? createdAt,
  }) {
    return RecurringTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      targetWeekday: targetWeekday ?? this.targetWeekday,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (targetWeekday.present) {
      map['target_weekday'] = Variable<int>(targetWeekday.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('notes: $notes, ')
          ..write('targetWeekday: $targetWeekday, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskHistoriesTable taskHistories = $TaskHistoriesTable(this);
  late final $WeekMetasTable weekMetas = $WeekMetasTable(this);
  late final $RecurringTemplatesTable recurringTemplates =
      $RecurringTemplatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    taskHistories,
    weekMetas,
    recurringTemplates,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      required String title,
      Value<int?> durationMinutes,
      Value<int?> startMinutes,
      Value<String?> notes,
      Value<String> status,
      required String weekStart,
      Value<String?> plannedDate,
      Value<String?> originalPlannedDate,
      Value<int> movedCount,
      Value<int?> recurrenceTemplateId,
      required String createdAt,
      required String updatedAt,
      Value<String?> completedAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int?> durationMinutes,
      Value<int?> startMinutes,
      Value<String?> notes,
      Value<String> status,
      Value<String> weekStart,
      Value<String?> plannedDate,
      Value<String?> originalPlannedDate,
      Value<int> movedCount,
      Value<int?> recurrenceTemplateId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String?> completedAt,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPlannedDate => $composableBuilder(
    column: $table.originalPlannedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movedCount => $composableBuilder(
    column: $table.movedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceTemplateId => $composableBuilder(
    column: $table.recurrenceTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPlannedDate => $composableBuilder(
    column: $table.originalPlannedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movedCount => $composableBuilder(
    column: $table.movedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceTemplateId => $composableBuilder(
    column: $table.recurrenceTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startMinutes => $composableBuilder(
    column: $table.startMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get plannedDate => $composableBuilder(
    column: $table.plannedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalPlannedDate => $composableBuilder(
    column: $table.originalPlannedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get movedCount => $composableBuilder(
    column: $table.movedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceTemplateId => $composableBuilder(
    column: $table.recurrenceTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<int?> startMinutes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> weekStart = const Value.absent(),
                Value<String?> plannedDate = const Value.absent(),
                Value<String?> originalPlannedDate = const Value.absent(),
                Value<int> movedCount = const Value.absent(),
                Value<int?> recurrenceTemplateId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                durationMinutes: durationMinutes,
                startMinutes: startMinutes,
                notes: notes,
                status: status,
                weekStart: weekStart,
                plannedDate: plannedDate,
                originalPlannedDate: originalPlannedDate,
                movedCount: movedCount,
                recurrenceTemplateId: recurrenceTemplateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int?> durationMinutes = const Value.absent(),
                Value<int?> startMinutes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String weekStart,
                Value<String?> plannedDate = const Value.absent(),
                Value<String?> originalPlannedDate = const Value.absent(),
                Value<int> movedCount = const Value.absent(),
                Value<int?> recurrenceTemplateId = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<String?> completedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                durationMinutes: durationMinutes,
                startMinutes: startMinutes,
                notes: notes,
                status: status,
                weekStart: weekStart,
                plannedDate: plannedDate,
                originalPlannedDate: originalPlannedDate,
                movedCount: movedCount,
                recurrenceTemplateId: recurrenceTemplateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$TaskHistoriesTableCreateCompanionBuilder =
    TaskHistoriesCompanion Function({
      Value<int> id,
      required int taskId,
      required String eventType,
      Value<String?> fromDate,
      Value<String?> toDate,
      required String timestamp,
      Value<String?> note,
    });
typedef $$TaskHistoriesTableUpdateCompanionBuilder =
    TaskHistoriesCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<String> eventType,
      Value<String?> fromDate,
      Value<String?> toDate,
      Value<String> timestamp,
      Value<String?> note,
    });

class $$TaskHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskHistoriesTable> {
  $$TaskHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromDate => $composableBuilder(
    column: $table.fromDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toDate => $composableBuilder(
    column: $table.toDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskHistoriesTable> {
  $$TaskHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromDate => $composableBuilder(
    column: $table.fromDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toDate => $composableBuilder(
    column: $table.toDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskHistoriesTable> {
  $$TaskHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get fromDate =>
      $composableBuilder(column: $table.fromDate, builder: (column) => column);

  GeneratedColumn<String> get toDate =>
      $composableBuilder(column: $table.toDate, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TaskHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskHistoriesTable,
          TaskHistory,
          $$TaskHistoriesTableFilterComposer,
          $$TaskHistoriesTableOrderingComposer,
          $$TaskHistoriesTableAnnotationComposer,
          $$TaskHistoriesTableCreateCompanionBuilder,
          $$TaskHistoriesTableUpdateCompanionBuilder,
          (
            TaskHistory,
            BaseReferences<_$AppDatabase, $TaskHistoriesTable, TaskHistory>,
          ),
          TaskHistory,
          PrefetchHooks Function()
        > {
  $$TaskHistoriesTableTableManager(_$AppDatabase db, $TaskHistoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> fromDate = const Value.absent(),
                Value<String?> toDate = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TaskHistoriesCompanion(
                id: id,
                taskId: taskId,
                eventType: eventType,
                fromDate: fromDate,
                toDate: toDate,
                timestamp: timestamp,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required String eventType,
                Value<String?> fromDate = const Value.absent(),
                Value<String?> toDate = const Value.absent(),
                required String timestamp,
                Value<String?> note = const Value.absent(),
              }) => TaskHistoriesCompanion.insert(
                id: id,
                taskId: taskId,
                eventType: eventType,
                fromDate: fromDate,
                toDate: toDate,
                timestamp: timestamp,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskHistoriesTable,
      TaskHistory,
      $$TaskHistoriesTableFilterComposer,
      $$TaskHistoriesTableOrderingComposer,
      $$TaskHistoriesTableAnnotationComposer,
      $$TaskHistoriesTableCreateCompanionBuilder,
      $$TaskHistoriesTableUpdateCompanionBuilder,
      (
        TaskHistory,
        BaseReferences<_$AppDatabase, $TaskHistoriesTable, TaskHistory>,
      ),
      TaskHistory,
      PrefetchHooks Function()
    >;
typedef $$WeekMetasTableCreateCompanionBuilder =
    WeekMetasCompanion Function({
      required String weekStart,
      Value<int> copyFromPreviousApplied,
      Value<int> rowid,
    });
typedef $$WeekMetasTableUpdateCompanionBuilder =
    WeekMetasCompanion Function({
      Value<String> weekStart,
      Value<int> copyFromPreviousApplied,
      Value<int> rowid,
    });

class $$WeekMetasTableFilterComposer
    extends Composer<_$AppDatabase, $WeekMetasTable> {
  $$WeekMetasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get copyFromPreviousApplied => $composableBuilder(
    column: $table.copyFromPreviousApplied,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeekMetasTableOrderingComposer
    extends Composer<_$AppDatabase, $WeekMetasTable> {
  $$WeekMetasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get copyFromPreviousApplied => $composableBuilder(
    column: $table.copyFromPreviousApplied,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeekMetasTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeekMetasTable> {
  $$WeekMetasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<int> get copyFromPreviousApplied => $composableBuilder(
    column: $table.copyFromPreviousApplied,
    builder: (column) => column,
  );
}

class $$WeekMetasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeekMetasTable,
          WeekMeta,
          $$WeekMetasTableFilterComposer,
          $$WeekMetasTableOrderingComposer,
          $$WeekMetasTableAnnotationComposer,
          $$WeekMetasTableCreateCompanionBuilder,
          $$WeekMetasTableUpdateCompanionBuilder,
          (WeekMeta, BaseReferences<_$AppDatabase, $WeekMetasTable, WeekMeta>),
          WeekMeta,
          PrefetchHooks Function()
        > {
  $$WeekMetasTableTableManager(_$AppDatabase db, $WeekMetasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekMetasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekMetasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekMetasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> weekStart = const Value.absent(),
                Value<int> copyFromPreviousApplied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekMetasCompanion(
                weekStart: weekStart,
                copyFromPreviousApplied: copyFromPreviousApplied,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String weekStart,
                Value<int> copyFromPreviousApplied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekMetasCompanion.insert(
                weekStart: weekStart,
                copyFromPreviousApplied: copyFromPreviousApplied,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeekMetasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeekMetasTable,
      WeekMeta,
      $$WeekMetasTableFilterComposer,
      $$WeekMetasTableOrderingComposer,
      $$WeekMetasTableAnnotationComposer,
      $$WeekMetasTableCreateCompanionBuilder,
      $$WeekMetasTableUpdateCompanionBuilder,
      (WeekMeta, BaseReferences<_$AppDatabase, $WeekMetasTable, WeekMeta>),
      WeekMeta,
      PrefetchHooks Function()
    >;
typedef $$RecurringTemplatesTableCreateCompanionBuilder =
    RecurringTemplatesCompanion Function({
      Value<int> id,
      required String title,
      Value<int?> durationMinutes,
      Value<String?> notes,
      Value<int?> targetWeekday,
      Value<int> isActive,
      required String createdAt,
    });
typedef $$RecurringTemplatesTableUpdateCompanionBuilder =
    RecurringTemplatesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int?> durationMinutes,
      Value<String?> notes,
      Value<int?> targetWeekday,
      Value<int> isActive,
      Value<String> createdAt,
    });

class $$RecurringTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetWeekday => $composableBuilder(
    column: $table.targetWeekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurringTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetWeekday => $composableBuilder(
    column: $table.targetWeekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get targetWeekday => $composableBuilder(
    column: $table.targetWeekday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecurringTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringTemplatesTable,
          RecurringTemplate,
          $$RecurringTemplatesTableFilterComposer,
          $$RecurringTemplatesTableOrderingComposer,
          $$RecurringTemplatesTableAnnotationComposer,
          $$RecurringTemplatesTableCreateCompanionBuilder,
          $$RecurringTemplatesTableUpdateCompanionBuilder,
          (
            RecurringTemplate,
            BaseReferences<
              _$AppDatabase,
              $RecurringTemplatesTable,
              RecurringTemplate
            >,
          ),
          RecurringTemplate,
          PrefetchHooks Function()
        > {
  $$RecurringTemplatesTableTableManager(
    _$AppDatabase db,
    $RecurringTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> targetWeekday = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => RecurringTemplatesCompanion(
                id: id,
                title: title,
                durationMinutes: durationMinutes,
                notes: notes,
                targetWeekday: targetWeekday,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> targetWeekday = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                required String createdAt,
              }) => RecurringTemplatesCompanion.insert(
                id: id,
                title: title,
                durationMinutes: durationMinutes,
                notes: notes,
                targetWeekday: targetWeekday,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurringTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringTemplatesTable,
      RecurringTemplate,
      $$RecurringTemplatesTableFilterComposer,
      $$RecurringTemplatesTableOrderingComposer,
      $$RecurringTemplatesTableAnnotationComposer,
      $$RecurringTemplatesTableCreateCompanionBuilder,
      $$RecurringTemplatesTableUpdateCompanionBuilder,
      (
        RecurringTemplate,
        BaseReferences<
          _$AppDatabase,
          $RecurringTemplatesTable,
          RecurringTemplate
        >,
      ),
      RecurringTemplate,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskHistoriesTableTableManager get taskHistories =>
      $$TaskHistoriesTableTableManager(_db, _db.taskHistories);
  $$WeekMetasTableTableManager get weekMetas =>
      $$WeekMetasTableTableManager(_db, _db.weekMetas);
  $$RecurringTemplatesTableTableManager get recurringTemplates =>
      $$RecurringTemplatesTableTableManager(_db, _db.recurringTemplates);
}
