// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverUrl,
    username,
    displayName,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_serverUrlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
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
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String serverUrl;
  final String username;
  final String? displayName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Account({
    required this.id,
    required this.serverUrl,
    required this.username,
    this.displayName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_url'] = Variable<String>(serverUrl);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      serverUrl: Value(serverUrl),
      username: Value(username),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      serverUrl: serializer.fromJson<String>(json['serverUrl']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverUrl': serializer.toJson<String>(serverUrl),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Account copyWith({
    int? id,
    String? serverUrl,
    String? username,
    Value<String?> displayName = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Account(
    id: id ?? this.id,
    serverUrl: serverUrl ?? this.serverUrl,
    username: username ?? this.username,
    displayName: displayName.present ? displayName.value : this.displayName,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverUrl,
    username,
    displayName,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.serverUrl == this.serverUrl &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> serverUrl;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String serverUrl,
    required String username,
    this.displayName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : serverUrl = Value(serverUrl),
       username = Value(username);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? serverUrl,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverUrl != null) 'server_url': serverUrl,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? serverUrl,
    Value<String>? username,
    Value<String?>? displayName,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    type,
    name,
    parentId,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final int serverId;
  final String type;
  final String name;
  final int? parentId;
  final DateTime cachedAt;
  const Category({
    required this.id,
    required this.serverId,
    required this.type,
    required this.name,
    this.parentId,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      serverId: Value(serverId),
      type: Value(type),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      cachedAt: Value(cachedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<int?>(parentId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Category copyWith({
    int? id,
    int? serverId,
    String? type,
    String? name,
    Value<int?> parentId = const Value.absent(),
    DateTime? cachedAt,
  }) => Category(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    type: type ?? this.type,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, type, name, parentId, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.type == this.type &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.cachedAt == this.cachedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<String> type;
  final Value<String> name;
  final Value<int?> parentId;
  final Value<DateTime> cachedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required String type,
    required String name,
    this.parentId = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : serverId = Value(serverId),
       type = Value(type),
       name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<int>? parentId,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<String>? type,
    Value<String>? name,
    Value<int?>? parentId,
    Value<DateTime>? cachedAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      type: type ?? this.type,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamIconMeta = const VerificationMeta(
    'streamIcon',
  );
  @override
  late final GeneratedColumn<String> streamIcon = GeneratedColumn<String>(
    'stream_icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvArchiveMeta = const VerificationMeta(
    'tvArchive',
  );
  @override
  late final GeneratedColumn<bool> tvArchive = GeneratedColumn<bool>(
    'tv_archive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tv_archive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tvArchiveDurationMeta = const VerificationMeta(
    'tvArchiveDuration',
  );
  @override
  late final GeneratedColumn<int> tvArchiveDuration = GeneratedColumn<int>(
    'tv_archive_duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamTypeMeta = const VerificationMeta(
    'streamType',
  );
  @override
  late final GeneratedColumn<String> streamType = GeneratedColumn<String>(
    'stream_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('live'),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    streamId,
    categoryId,
    name,
    streamIcon,
    epgChannelId,
    tvArchive,
    tvArchiveDuration,
    streamType,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Channel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_icon')) {
      context.handle(
        _streamIconMeta,
        streamIcon.isAcceptableOrUnknown(data['stream_icon']!, _streamIconMeta),
      );
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('tv_archive')) {
      context.handle(
        _tvArchiveMeta,
        tvArchive.isAcceptableOrUnknown(data['tv_archive']!, _tvArchiveMeta),
      );
    }
    if (data.containsKey('tv_archive_duration')) {
      context.handle(
        _tvArchiveDurationMeta,
        tvArchiveDuration.isAcceptableOrUnknown(
          data['tv_archive_duration']!,
          _tvArchiveDurationMeta,
        ),
      );
    }
    if (data.containsKey('stream_type')) {
      context.handle(
        _streamTypeMeta,
        streamType.isAcceptableOrUnknown(data['stream_type']!, _streamTypeMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      streamIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_icon'],
      ),
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      ),
      tvArchive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tv_archive'],
      )!,
      tvArchiveDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tv_archive_duration'],
      ),
      streamType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_type'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class Channel extends DataClass implements Insertable<Channel> {
  final int id;
  final int serverId;
  final int streamId;
  final int? categoryId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final bool tvArchive;
  final int? tvArchiveDuration;
  final String streamType;
  final DateTime cachedAt;
  const Channel({
    required this.id,
    required this.serverId,
    required this.streamId,
    this.categoryId,
    required this.name,
    this.streamIcon,
    this.epgChannelId,
    required this.tvArchive,
    this.tvArchiveDuration,
    required this.streamType,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['stream_id'] = Variable<int>(streamId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || streamIcon != null) {
      map['stream_icon'] = Variable<String>(streamIcon);
    }
    if (!nullToAbsent || epgChannelId != null) {
      map['epg_channel_id'] = Variable<String>(epgChannelId);
    }
    map['tv_archive'] = Variable<bool>(tvArchive);
    if (!nullToAbsent || tvArchiveDuration != null) {
      map['tv_archive_duration'] = Variable<int>(tvArchiveDuration);
    }
    map['stream_type'] = Variable<String>(streamType);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      streamId: Value(streamId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      streamIcon: streamIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(streamIcon),
      epgChannelId: epgChannelId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgChannelId),
      tvArchive: Value(tvArchive),
      tvArchiveDuration: tvArchiveDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(tvArchiveDuration),
      streamType: Value(streamType),
      cachedAt: Value(cachedAt),
    );
  }

  factory Channel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      streamId: serializer.fromJson<int>(json['streamId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      streamIcon: serializer.fromJson<String?>(json['streamIcon']),
      epgChannelId: serializer.fromJson<String?>(json['epgChannelId']),
      tvArchive: serializer.fromJson<bool>(json['tvArchive']),
      tvArchiveDuration: serializer.fromJson<int?>(json['tvArchiveDuration']),
      streamType: serializer.fromJson<String>(json['streamType']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'streamId': serializer.toJson<int>(streamId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'name': serializer.toJson<String>(name),
      'streamIcon': serializer.toJson<String?>(streamIcon),
      'epgChannelId': serializer.toJson<String?>(epgChannelId),
      'tvArchive': serializer.toJson<bool>(tvArchive),
      'tvArchiveDuration': serializer.toJson<int?>(tvArchiveDuration),
      'streamType': serializer.toJson<String>(streamType),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Channel copyWith({
    int? id,
    int? serverId,
    int? streamId,
    Value<int?> categoryId = const Value.absent(),
    String? name,
    Value<String?> streamIcon = const Value.absent(),
    Value<String?> epgChannelId = const Value.absent(),
    bool? tvArchive,
    Value<int?> tvArchiveDuration = const Value.absent(),
    String? streamType,
    DateTime? cachedAt,
  }) => Channel(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    streamId: streamId ?? this.streamId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    name: name ?? this.name,
    streamIcon: streamIcon.present ? streamIcon.value : this.streamIcon,
    epgChannelId: epgChannelId.present ? epgChannelId.value : this.epgChannelId,
    tvArchive: tvArchive ?? this.tvArchive,
    tvArchiveDuration: tvArchiveDuration.present
        ? tvArchiveDuration.value
        : this.tvArchiveDuration,
    streamType: streamType ?? this.streamType,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      streamIcon: data.streamIcon.present
          ? data.streamIcon.value
          : this.streamIcon,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      tvArchive: data.tvArchive.present ? data.tvArchive.value : this.tvArchive,
      tvArchiveDuration: data.tvArchiveDuration.present
          ? data.tvArchiveDuration.value
          : this.tvArchiveDuration,
      streamType: data.streamType.present
          ? data.streamType.value
          : this.streamType,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('streamId: $streamId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('tvArchiveDuration: $tvArchiveDuration, ')
          ..write('streamType: $streamType, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    streamId,
    categoryId,
    name,
    streamIcon,
    epgChannelId,
    tvArchive,
    tvArchiveDuration,
    streamType,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.streamId == this.streamId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.streamIcon == this.streamIcon &&
          other.epgChannelId == this.epgChannelId &&
          other.tvArchive == this.tvArchive &&
          other.tvArchiveDuration == this.tvArchiveDuration &&
          other.streamType == this.streamType &&
          other.cachedAt == this.cachedAt);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<int> streamId;
  final Value<int?> categoryId;
  final Value<String> name;
  final Value<String?> streamIcon;
  final Value<String?> epgChannelId;
  final Value<bool> tvArchive;
  final Value<int?> tvArchiveDuration;
  final Value<String> streamType;
  final Value<DateTime> cachedAt;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.streamIcon = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.tvArchiveDuration = const Value.absent(),
    this.streamType = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required int streamId,
    this.categoryId = const Value.absent(),
    required String name,
    this.streamIcon = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.tvArchiveDuration = const Value.absent(),
    this.streamType = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : serverId = Value(serverId),
       streamId = Value(streamId),
       name = Value(name);
  static Insertable<Channel> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? streamId,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<String>? streamIcon,
    Expression<String>? epgChannelId,
    Expression<bool>? tvArchive,
    Expression<int>? tvArchiveDuration,
    Expression<String>? streamType,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (streamId != null) 'stream_id': streamId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (streamIcon != null) 'stream_icon': streamIcon,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (tvArchive != null) 'tv_archive': tvArchive,
      if (tvArchiveDuration != null) 'tv_archive_duration': tvArchiveDuration,
      if (streamType != null) 'stream_type': streamType,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  ChannelsCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<int>? streamId,
    Value<int?>? categoryId,
    Value<String>? name,
    Value<String?>? streamIcon,
    Value<String?>? epgChannelId,
    Value<bool>? tvArchive,
    Value<int?>? tvArchiveDuration,
    Value<String>? streamType,
    Value<DateTime>? cachedAt,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      streamId: streamId ?? this.streamId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      streamIcon: streamIcon ?? this.streamIcon,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      tvArchive: tvArchive ?? this.tvArchive,
      tvArchiveDuration: tvArchiveDuration ?? this.tvArchiveDuration,
      streamType: streamType ?? this.streamType,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamIcon.present) {
      map['stream_icon'] = Variable<String>(streamIcon.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (tvArchive.present) {
      map['tv_archive'] = Variable<bool>(tvArchive.value);
    }
    if (tvArchiveDuration.present) {
      map['tv_archive_duration'] = Variable<int>(tvArchiveDuration.value);
    }
    if (streamType.present) {
      map['stream_type'] = Variable<String>(streamType.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('streamId: $streamId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('tvArchiveDuration: $tvArchiveDuration, ')
          ..write('streamType: $streamType, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsTable extends EpgPrograms
    with TableInfo<$EpgProgramsTable, EpgProgram> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _epgIdMeta = const VerificationMeta('epgId');
  @override
  late final GeneratedColumn<String> epgId = GeneratedColumn<String>(
    'epg_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    epgId,
    channelId,
    title,
    description,
    start,
    end,
    lang,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgram> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('epg_id')) {
      context.handle(
        _epgIdMeta,
        epgId.isAcceptableOrUnknown(data['epg_id']!, _epgIdMeta),
      );
    } else if (isInserting) {
      context.missing(_epgIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpgProgram map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgram(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      epgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $EpgProgramsTable createAlias(String alias) {
    return $EpgProgramsTable(attachedDatabase, alias);
  }
}

class EpgProgram extends DataClass implements Insertable<EpgProgram> {
  final int id;
  final String epgId;
  final int? channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String lang;
  final DateTime cachedAt;
  const EpgProgram({
    required this.id,
    required this.epgId,
    this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    required this.lang,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['epg_id'] = Variable<String>(epgId);
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<int>(channelId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    map['lang'] = Variable<String>(lang);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  EpgProgramsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsCompanion(
      id: Value(id),
      epgId: Value(epgId),
      channelId: channelId == null && nullToAbsent
          ? const Value.absent()
          : Value(channelId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      start: Value(start),
      end: Value(end),
      lang: Value(lang),
      cachedAt: Value(cachedAt),
    );
  }

  factory EpgProgram.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgram(
      id: serializer.fromJson<int>(json['id']),
      epgId: serializer.fromJson<String>(json['epgId']),
      channelId: serializer.fromJson<int?>(json['channelId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
      lang: serializer.fromJson<String>(json['lang']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'epgId': serializer.toJson<String>(epgId),
      'channelId': serializer.toJson<int?>(channelId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
      'lang': serializer.toJson<String>(lang),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  EpgProgram copyWith({
    int? id,
    String? epgId,
    Value<int?> channelId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? start,
    DateTime? end,
    String? lang,
    DateTime? cachedAt,
  }) => EpgProgram(
    id: id ?? this.id,
    epgId: epgId ?? this.epgId,
    channelId: channelId.present ? channelId.value : this.channelId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    start: start ?? this.start,
    end: end ?? this.end,
    lang: lang ?? this.lang,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  EpgProgram copyWithCompanion(EpgProgramsCompanion data) {
    return EpgProgram(
      id: data.id.present ? data.id.value : this.id,
      epgId: data.epgId.present ? data.epgId.value : this.epgId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      lang: data.lang.present ? data.lang.value : this.lang,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgram(')
          ..write('id: $id, ')
          ..write('epgId: $epgId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('lang: $lang, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    epgId,
    channelId,
    title,
    description,
    start,
    end,
    lang,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgram &&
          other.id == this.id &&
          other.epgId == this.epgId &&
          other.channelId == this.channelId &&
          other.title == this.title &&
          other.description == this.description &&
          other.start == this.start &&
          other.end == this.end &&
          other.lang == this.lang &&
          other.cachedAt == this.cachedAt);
}

class EpgProgramsCompanion extends UpdateCompanion<EpgProgram> {
  final Value<int> id;
  final Value<String> epgId;
  final Value<int?> channelId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<String> lang;
  final Value<DateTime> cachedAt;
  const EpgProgramsCompanion({
    this.id = const Value.absent(),
    this.epgId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.lang = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  EpgProgramsCompanion.insert({
    this.id = const Value.absent(),
    required String epgId,
    this.channelId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required DateTime start,
    required DateTime end,
    this.lang = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : epgId = Value(epgId),
       title = Value(title),
       start = Value(start),
       end = Value(end);
  static Insertable<EpgProgram> custom({
    Expression<int>? id,
    Expression<String>? epgId,
    Expression<int>? channelId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<String>? lang,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epgId != null) 'epg_id': epgId,
      if (channelId != null) 'channel_id': channelId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (lang != null) 'lang': lang,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  EpgProgramsCompanion copyWith({
    Value<int>? id,
    Value<String>? epgId,
    Value<int?>? channelId,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? start,
    Value<DateTime>? end,
    Value<String>? lang,
    Value<DateTime>? cachedAt,
  }) {
    return EpgProgramsCompanion(
      id: id ?? this.id,
      epgId: epgId ?? this.epgId,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      lang: lang ?? this.lang,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (epgId.present) {
      map['epg_id'] = Variable<String>(epgId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsCompanion(')
          ..write('id: $id, ')
          ..write('epgId: $epgId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('lang: $lang, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, Movy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamIconMeta = const VerificationMeta(
    'streamIcon',
  );
  @override
  late final GeneratedColumn<String> streamIcon = GeneratedColumn<String>(
    'stream_icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directorMeta = const VerificationMeta(
    'director',
  );
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
    'director',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<int> releaseDate = GeneratedColumn<int>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    streamId,
    categoryId,
    name,
    streamIcon,
    rating,
    genre,
    plot,
    cast,
    director,
    releaseDate,
    durationSecs,
    containerExtension,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_icon')) {
      context.handle(
        _streamIconMeta,
        streamIcon.isAcceptableOrUnknown(data['stream_icon']!, _streamIconMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('cast')) {
      context.handle(
        _castMeta,
        cast.isAcceptableOrUnknown(data['cast']!, _castMeta),
      );
    }
    if (data.containsKey('director')) {
      context.handle(
        _directorMeta,
        director.isAcceptableOrUnknown(data['director']!, _directorMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Movy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      streamIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_icon'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      cast: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cast'],
      ),
      director: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}director'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_date'],
      ),
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class Movy extends DataClass implements Insertable<Movy> {
  final int id;
  final int serverId;
  final int streamId;
  final int? categoryId;
  final String name;
  final String? streamIcon;
  final String? rating;
  final String? genre;
  final String? plot;
  final String? cast;
  final String? director;
  final int? releaseDate;
  final int? durationSecs;
  final String? containerExtension;
  final DateTime cachedAt;
  const Movy({
    required this.id,
    required this.serverId,
    required this.streamId,
    this.categoryId,
    required this.name,
    this.streamIcon,
    this.rating,
    this.genre,
    this.plot,
    this.cast,
    this.director,
    this.releaseDate,
    this.durationSecs,
    this.containerExtension,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['stream_id'] = Variable<int>(streamId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || streamIcon != null) {
      map['stream_icon'] = Variable<String>(streamIcon);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || cast != null) {
      map['cast'] = Variable<String>(cast);
    }
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<int>(releaseDate);
    }
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      id: Value(id),
      serverId: Value(serverId),
      streamId: Value(streamId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      streamIcon: streamIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(streamIcon),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      cast: cast == null && nullToAbsent ? const Value.absent() : Value(cast),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      cachedAt: Value(cachedAt),
    );
  }

  factory Movy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movy(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      streamId: serializer.fromJson<int>(json['streamId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      streamIcon: serializer.fromJson<String?>(json['streamIcon']),
      rating: serializer.fromJson<String?>(json['rating']),
      genre: serializer.fromJson<String?>(json['genre']),
      plot: serializer.fromJson<String?>(json['plot']),
      cast: serializer.fromJson<String?>(json['cast']),
      director: serializer.fromJson<String?>(json['director']),
      releaseDate: serializer.fromJson<int?>(json['releaseDate']),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'streamId': serializer.toJson<int>(streamId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'name': serializer.toJson<String>(name),
      'streamIcon': serializer.toJson<String?>(streamIcon),
      'rating': serializer.toJson<String?>(rating),
      'genre': serializer.toJson<String?>(genre),
      'plot': serializer.toJson<String?>(plot),
      'cast': serializer.toJson<String?>(cast),
      'director': serializer.toJson<String?>(director),
      'releaseDate': serializer.toJson<int?>(releaseDate),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Movy copyWith({
    int? id,
    int? serverId,
    int? streamId,
    Value<int?> categoryId = const Value.absent(),
    String? name,
    Value<String?> streamIcon = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<String?> cast = const Value.absent(),
    Value<String?> director = const Value.absent(),
    Value<int?> releaseDate = const Value.absent(),
    Value<int?> durationSecs = const Value.absent(),
    Value<String?> containerExtension = const Value.absent(),
    DateTime? cachedAt,
  }) => Movy(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    streamId: streamId ?? this.streamId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    name: name ?? this.name,
    streamIcon: streamIcon.present ? streamIcon.value : this.streamIcon,
    rating: rating.present ? rating.value : this.rating,
    genre: genre.present ? genre.value : this.genre,
    plot: plot.present ? plot.value : this.plot,
    cast: cast.present ? cast.value : this.cast,
    director: director.present ? director.value : this.director,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Movy copyWithCompanion(MoviesCompanion data) {
    return Movy(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      streamIcon: data.streamIcon.present
          ? data.streamIcon.value
          : this.streamIcon,
      rating: data.rating.present ? data.rating.value : this.rating,
      genre: data.genre.present ? data.genre.value : this.genre,
      plot: data.plot.present ? data.plot.value : this.plot,
      cast: data.cast.present ? data.cast.value : this.cast,
      director: data.director.present ? data.director.value : this.director,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movy(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('streamId: $streamId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('rating: $rating, ')
          ..write('genre: $genre, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    streamId,
    categoryId,
    name,
    streamIcon,
    rating,
    genre,
    plot,
    cast,
    director,
    releaseDate,
    durationSecs,
    containerExtension,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movy &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.streamId == this.streamId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.streamIcon == this.streamIcon &&
          other.rating == this.rating &&
          other.genre == this.genre &&
          other.plot == this.plot &&
          other.cast == this.cast &&
          other.director == this.director &&
          other.releaseDate == this.releaseDate &&
          other.durationSecs == this.durationSecs &&
          other.containerExtension == this.containerExtension &&
          other.cachedAt == this.cachedAt);
}

class MoviesCompanion extends UpdateCompanion<Movy> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<int> streamId;
  final Value<int?> categoryId;
  final Value<String> name;
  final Value<String?> streamIcon;
  final Value<String?> rating;
  final Value<String?> genre;
  final Value<String?> plot;
  final Value<String?> cast;
  final Value<String?> director;
  final Value<int?> releaseDate;
  final Value<int?> durationSecs;
  final Value<String?> containerExtension;
  final Value<DateTime> cachedAt;
  const MoviesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.streamIcon = const Value.absent(),
    this.rating = const Value.absent(),
    this.genre = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  MoviesCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required int streamId,
    this.categoryId = const Value.absent(),
    required String name,
    this.streamIcon = const Value.absent(),
    this.rating = const Value.absent(),
    this.genre = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : serverId = Value(serverId),
       streamId = Value(streamId),
       name = Value(name);
  static Insertable<Movy> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? streamId,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<String>? streamIcon,
    Expression<String>? rating,
    Expression<String>? genre,
    Expression<String>? plot,
    Expression<String>? cast,
    Expression<String>? director,
    Expression<int>? releaseDate,
    Expression<int>? durationSecs,
    Expression<String>? containerExtension,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (streamId != null) 'stream_id': streamId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (streamIcon != null) 'stream_icon': streamIcon,
      if (rating != null) 'rating': rating,
      if (genre != null) 'genre': genre,
      if (plot != null) 'plot': plot,
      if (cast != null) 'cast': cast,
      if (director != null) 'director': director,
      if (releaseDate != null) 'release_date': releaseDate,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  MoviesCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<int>? streamId,
    Value<int?>? categoryId,
    Value<String>? name,
    Value<String?>? streamIcon,
    Value<String?>? rating,
    Value<String?>? genre,
    Value<String?>? plot,
    Value<String?>? cast,
    Value<String?>? director,
    Value<int?>? releaseDate,
    Value<int?>? durationSecs,
    Value<String?>? containerExtension,
    Value<DateTime>? cachedAt,
  }) {
    return MoviesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      streamId: streamId ?? this.streamId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      streamIcon: streamIcon ?? this.streamIcon,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      releaseDate: releaseDate ?? this.releaseDate,
      durationSecs: durationSecs ?? this.durationSecs,
      containerExtension: containerExtension ?? this.containerExtension,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamIcon.present) {
      map['stream_icon'] = Variable<String>(streamIcon.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<int>(releaseDate.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('streamId: $streamId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('rating: $rating, ')
          ..write('genre: $genre, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directorMeta = const VerificationMeta(
    'director',
  );
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
    'director',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<int> releaseDate = GeneratedColumn<int>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    seriesId,
    categoryId,
    name,
    cover,
    plot,
    cast,
    director,
    genre,
    rating,
    releaseDate,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('cast')) {
      context.handle(
        _castMeta,
        cast.isAcceptableOrUnknown(data['cast']!, _castMeta),
      );
    }
    if (data.containsKey('director')) {
      context.handle(
        _directorMeta,
        director.isAcceptableOrUnknown(data['director']!, _directorMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      cast: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cast'],
      ),
      director: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}director'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_date'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesTableData extends DataClass implements Insertable<SeriesTableData> {
  final int id;
  final int serverId;
  final int seriesId;
  final int? categoryId;
  final String name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? rating;
  final int? releaseDate;
  final DateTime cachedAt;
  const SeriesTableData({
    required this.id,
    required this.serverId,
    required this.seriesId,
    this.categoryId,
    required this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.releaseDate,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['series_id'] = Variable<int>(seriesId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || cast != null) {
      map['cast'] = Variable<String>(cast);
    }
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<int>(releaseDate);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      seriesId: Value(seriesId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      cast: cast == null && nullToAbsent ? const Value.absent() : Value(cast),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      cachedAt: Value(cachedAt),
    );
  }

  factory SeriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      cover: serializer.fromJson<String?>(json['cover']),
      plot: serializer.fromJson<String?>(json['plot']),
      cast: serializer.fromJson<String?>(json['cast']),
      director: serializer.fromJson<String?>(json['director']),
      genre: serializer.fromJson<String?>(json['genre']),
      rating: serializer.fromJson<String?>(json['rating']),
      releaseDate: serializer.fromJson<int?>(json['releaseDate']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'seriesId': serializer.toJson<int>(seriesId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'name': serializer.toJson<String>(name),
      'cover': serializer.toJson<String?>(cover),
      'plot': serializer.toJson<String?>(plot),
      'cast': serializer.toJson<String?>(cast),
      'director': serializer.toJson<String?>(director),
      'genre': serializer.toJson<String?>(genre),
      'rating': serializer.toJson<String?>(rating),
      'releaseDate': serializer.toJson<int?>(releaseDate),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  SeriesTableData copyWith({
    int? id,
    int? serverId,
    int? seriesId,
    Value<int?> categoryId = const Value.absent(),
    String? name,
    Value<String?> cover = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<String?> cast = const Value.absent(),
    Value<String?> director = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    Value<int?> releaseDate = const Value.absent(),
    DateTime? cachedAt,
  }) => SeriesTableData(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    seriesId: seriesId ?? this.seriesId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    name: name ?? this.name,
    cover: cover.present ? cover.value : this.cover,
    plot: plot.present ? plot.value : this.plot,
    cast: cast.present ? cast.value : this.cast,
    director: director.present ? director.value : this.director,
    genre: genre.present ? genre.value : this.genre,
    rating: rating.present ? rating.value : this.rating,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  SeriesTableData copyWithCompanion(SeriesTableCompanion data) {
    return SeriesTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      cover: data.cover.present ? data.cover.value : this.cover,
      plot: data.plot.present ? data.plot.value : this.plot,
      cast: data.cast.present ? data.cast.value : this.cast,
      director: data.director.present ? data.director.value : this.director,
      genre: data.genre.present ? data.genre.value : this.genre,
      rating: data.rating.present ? data.rating.value : this.rating,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('seriesId: $seriesId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    seriesId,
    categoryId,
    name,
    cover,
    plot,
    cast,
    director,
    genre,
    rating,
    releaseDate,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.seriesId == this.seriesId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.cover == this.cover &&
          other.plot == this.plot &&
          other.cast == this.cast &&
          other.director == this.director &&
          other.genre == this.genre &&
          other.rating == this.rating &&
          other.releaseDate == this.releaseDate &&
          other.cachedAt == this.cachedAt);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesTableData> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<int> seriesId;
  final Value<int?> categoryId;
  final Value<String> name;
  final Value<String?> cover;
  final Value<String?> plot;
  final Value<String?> cast;
  final Value<String?> director;
  final Value<String?> genre;
  final Value<String?> rating;
  final Value<int?> releaseDate;
  final Value<DateTime> cachedAt;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required int seriesId,
    this.categoryId = const Value.absent(),
    required String name,
    this.cover = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : serverId = Value(serverId),
       seriesId = Value(seriesId),
       name = Value(name);
  static Insertable<SeriesTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? seriesId,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<String>? cover,
    Expression<String>? plot,
    Expression<String>? cast,
    Expression<String>? director,
    Expression<String>? genre,
    Expression<String>? rating,
    Expression<int>? releaseDate,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (seriesId != null) 'series_id': seriesId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (cover != null) 'cover': cover,
      if (plot != null) 'plot': plot,
      if (cast != null) 'cast': cast,
      if (director != null) 'director': director,
      if (genre != null) 'genre': genre,
      if (rating != null) 'rating': rating,
      if (releaseDate != null) 'release_date': releaseDate,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  SeriesTableCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<int>? seriesId,
    Value<int?>? categoryId,
    Value<String>? name,
    Value<String?>? cover,
    Value<String?>? plot,
    Value<String?>? cast,
    Value<String?>? director,
    Value<String?>? genre,
    Value<String?>? rating,
    Value<int?>? releaseDate,
    Value<DateTime>? cachedAt,
  }) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      seriesId: seriesId ?? this.seriesId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      releaseDate: releaseDate ?? this.releaseDate,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<int>(releaseDate.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('seriesId: $seriesId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, Season> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _seriesLocalIdMeta = const VerificationMeta(
    'seriesLocalId',
  );
  @override
  late final GeneratedColumn<int> seriesLocalId = GeneratedColumn<int>(
    'series_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesLocalId,
    seasonNumber,
    name,
    cover,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Season> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_local_id')) {
      context.handle(
        _seriesLocalIdMeta,
        seriesLocalId.isAcceptableOrUnknown(
          data['series_local_id']!,
          _seriesLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriesLocalIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Season map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Season(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_local_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class Season extends DataClass implements Insertable<Season> {
  final int id;
  final int seriesLocalId;
  final int seasonNumber;
  final String? name;
  final String? cover;
  final DateTime cachedAt;
  const Season({
    required this.id,
    required this.seriesLocalId,
    required this.seasonNumber,
    this.name,
    this.cover,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_local_id'] = Variable<int>(seriesLocalId);
    map['season_number'] = Variable<int>(seasonNumber);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      id: Value(id),
      seriesLocalId: Value(seriesLocalId),
      seasonNumber: Value(seasonNumber),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      cachedAt: Value(cachedAt),
    );
  }

  factory Season.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Season(
      id: serializer.fromJson<int>(json['id']),
      seriesLocalId: serializer.fromJson<int>(json['seriesLocalId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      name: serializer.fromJson<String?>(json['name']),
      cover: serializer.fromJson<String?>(json['cover']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesLocalId': serializer.toJson<int>(seriesLocalId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'name': serializer.toJson<String?>(name),
      'cover': serializer.toJson<String?>(cover),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Season copyWith({
    int? id,
    int? seriesLocalId,
    int? seasonNumber,
    Value<String?> name = const Value.absent(),
    Value<String?> cover = const Value.absent(),
    DateTime? cachedAt,
  }) => Season(
    id: id ?? this.id,
    seriesLocalId: seriesLocalId ?? this.seriesLocalId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    name: name.present ? name.value : this.name,
    cover: cover.present ? cover.value : this.cover,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Season copyWithCompanion(SeasonsCompanion data) {
    return Season(
      id: data.id.present ? data.id.value : this.id,
      seriesLocalId: data.seriesLocalId.present
          ? data.seriesLocalId.value
          : this.seriesLocalId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      name: data.name.present ? data.name.value : this.name,
      cover: data.cover.present ? data.cover.value : this.cover,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Season(')
          ..write('id: $id, ')
          ..write('seriesLocalId: $seriesLocalId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seriesLocalId, seasonNumber, name, cover, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Season &&
          other.id == this.id &&
          other.seriesLocalId == this.seriesLocalId &&
          other.seasonNumber == this.seasonNumber &&
          other.name == this.name &&
          other.cover == this.cover &&
          other.cachedAt == this.cachedAt);
}

class SeasonsCompanion extends UpdateCompanion<Season> {
  final Value<int> id;
  final Value<int> seriesLocalId;
  final Value<int> seasonNumber;
  final Value<String?> name;
  final Value<String?> cover;
  final Value<DateTime> cachedAt;
  const SeasonsCompanion({
    this.id = const Value.absent(),
    this.seriesLocalId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  SeasonsCompanion.insert({
    this.id = const Value.absent(),
    required int seriesLocalId,
    required int seasonNumber,
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : seriesLocalId = Value(seriesLocalId),
       seasonNumber = Value(seasonNumber);
  static Insertable<Season> custom({
    Expression<int>? id,
    Expression<int>? seriesLocalId,
    Expression<int>? seasonNumber,
    Expression<String>? name,
    Expression<String>? cover,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesLocalId != null) 'series_local_id': seriesLocalId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (name != null) 'name': name,
      if (cover != null) 'cover': cover,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  SeasonsCompanion copyWith({
    Value<int>? id,
    Value<int>? seriesLocalId,
    Value<int>? seasonNumber,
    Value<String?>? name,
    Value<String?>? cover,
    Value<DateTime>? cachedAt,
  }) {
    return SeasonsCompanion(
      id: id ?? this.id,
      seriesLocalId: seriesLocalId ?? this.seriesLocalId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesLocalId.present) {
      map['series_local_id'] = Variable<int>(seriesLocalId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('id: $id, ')
          ..write('seriesLocalId: $seriesLocalId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _seasonLocalIdMeta = const VerificationMeta(
    'seasonLocalId',
  );
  @override
  late final GeneratedColumn<int> seasonLocalId = GeneratedColumn<int>(
    'season_local_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumMeta = const VerificationMeta(
    'episodeNum',
  );
  @override
  late final GeneratedColumn<int> episodeNum = GeneratedColumn<int>(
    'episode_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seasonLocalId,
    episodeNum,
    title,
    streamId,
    containerExtension,
    durationSecs,
    plot,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('season_local_id')) {
      context.handle(
        _seasonLocalIdMeta,
        seasonLocalId.isAcceptableOrUnknown(
          data['season_local_id']!,
          _seasonLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonLocalIdMeta);
    }
    if (data.containsKey('episode_num')) {
      context.handle(
        _episodeNumMeta,
        episodeNum.isAcceptableOrUnknown(data['episode_num']!, _episodeNumMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeNumMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seasonLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_local_id'],
      )!,
      episodeNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_num'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final int seasonLocalId;
  final int episodeNum;
  final String title;
  final int streamId;
  final String? containerExtension;
  final int? durationSecs;
  final String? plot;
  final DateTime cachedAt;
  const Episode({
    required this.id,
    required this.seasonLocalId,
    required this.episodeNum,
    required this.title,
    required this.streamId,
    this.containerExtension,
    this.durationSecs,
    this.plot,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['season_local_id'] = Variable<int>(seasonLocalId);
    map['episode_num'] = Variable<int>(episodeNum);
    map['title'] = Variable<String>(title);
    map['stream_id'] = Variable<int>(streamId);
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      seasonLocalId: Value(seasonLocalId),
      episodeNum: Value(episodeNum),
      title: Value(title),
      streamId: Value(streamId),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      cachedAt: Value(cachedAt),
    );
  }

  factory Episode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      seasonLocalId: serializer.fromJson<int>(json['seasonLocalId']),
      episodeNum: serializer.fromJson<int>(json['episodeNum']),
      title: serializer.fromJson<String>(json['title']),
      streamId: serializer.fromJson<int>(json['streamId']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      plot: serializer.fromJson<String?>(json['plot']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seasonLocalId': serializer.toJson<int>(seasonLocalId),
      'episodeNum': serializer.toJson<int>(episodeNum),
      'title': serializer.toJson<String>(title),
      'streamId': serializer.toJson<int>(streamId),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'plot': serializer.toJson<String?>(plot),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Episode copyWith({
    int? id,
    int? seasonLocalId,
    int? episodeNum,
    String? title,
    int? streamId,
    Value<String?> containerExtension = const Value.absent(),
    Value<int?> durationSecs = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    DateTime? cachedAt,
  }) => Episode(
    id: id ?? this.id,
    seasonLocalId: seasonLocalId ?? this.seasonLocalId,
    episodeNum: episodeNum ?? this.episodeNum,
    title: title ?? this.title,
    streamId: streamId ?? this.streamId,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    plot: plot.present ? plot.value : this.plot,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      seasonLocalId: data.seasonLocalId.present
          ? data.seasonLocalId.value
          : this.seasonLocalId,
      episodeNum: data.episodeNum.present
          ? data.episodeNum.value
          : this.episodeNum,
      title: data.title.present ? data.title.value : this.title,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      plot: data.plot.present ? data.plot.value : this.plot,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('seasonLocalId: $seasonLocalId, ')
          ..write('episodeNum: $episodeNum, ')
          ..write('title: $title, ')
          ..write('streamId: $streamId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('plot: $plot, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seasonLocalId,
    episodeNum,
    title,
    streamId,
    containerExtension,
    durationSecs,
    plot,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.seasonLocalId == this.seasonLocalId &&
          other.episodeNum == this.episodeNum &&
          other.title == this.title &&
          other.streamId == this.streamId &&
          other.containerExtension == this.containerExtension &&
          other.durationSecs == this.durationSecs &&
          other.plot == this.plot &&
          other.cachedAt == this.cachedAt);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<int> seasonLocalId;
  final Value<int> episodeNum;
  final Value<String> title;
  final Value<int> streamId;
  final Value<String?> containerExtension;
  final Value<int?> durationSecs;
  final Value<String?> plot;
  final Value<DateTime> cachedAt;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.seasonLocalId = const Value.absent(),
    this.episodeNum = const Value.absent(),
    this.title = const Value.absent(),
    this.streamId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.plot = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required int seasonLocalId,
    required int episodeNum,
    required String title,
    required int streamId,
    this.containerExtension = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.plot = const Value.absent(),
    this.cachedAt = const Value.absent(),
  }) : seasonLocalId = Value(seasonLocalId),
       episodeNum = Value(episodeNum),
       title = Value(title),
       streamId = Value(streamId);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<int>? seasonLocalId,
    Expression<int>? episodeNum,
    Expression<String>? title,
    Expression<int>? streamId,
    Expression<String>? containerExtension,
    Expression<int>? durationSecs,
    Expression<String>? plot,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seasonLocalId != null) 'season_local_id': seasonLocalId,
      if (episodeNum != null) 'episode_num': episodeNum,
      if (title != null) 'title': title,
      if (streamId != null) 'stream_id': streamId,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (plot != null) 'plot': plot,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  EpisodesCompanion copyWith({
    Value<int>? id,
    Value<int>? seasonLocalId,
    Value<int>? episodeNum,
    Value<String>? title,
    Value<int>? streamId,
    Value<String?>? containerExtension,
    Value<int?>? durationSecs,
    Value<String?>? plot,
    Value<DateTime>? cachedAt,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      seasonLocalId: seasonLocalId ?? this.seasonLocalId,
      episodeNum: episodeNum ?? this.episodeNum,
      title: title ?? this.title,
      streamId: streamId ?? this.streamId,
      containerExtension: containerExtension ?? this.containerExtension,
      durationSecs: durationSecs ?? this.durationSecs,
      plot: plot ?? this.plot,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seasonLocalId.present) {
      map['season_local_id'] = Variable<int>(seasonLocalId.value);
    }
    if (episodeNum.present) {
      map['episode_num'] = Variable<int>(episodeNum.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seasonLocalId: $seasonLocalId, ')
          ..write('episodeNum: $episodeNum, ')
          ..write('title: $title, ')
          ..write('streamId: $streamId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('plot: $plot, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    itemId,
    name,
    imageUrl,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final String type;
  final int itemId;
  final String name;
  final String? imageUrl;
  final DateTime addedAt;
  const Favorite({
    required this.id,
    required this.type,
    required this.itemId,
    required this.name,
    this.imageUrl,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['item_id'] = Variable<int>(itemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      type: Value(type),
      itemId: Value(itemId),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      addedAt: Value(addedAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      itemId: serializer.fromJson<int>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'itemId': serializer.toJson<int>(itemId),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith({
    int? id,
    String? type,
    int? itemId,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    DateTime? addedAt,
  }) => Favorite(
    id: id ?? this.id,
    type: type ?? this.type,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    addedAt: addedAt ?? this.addedAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, itemId, name, imageUrl, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.type == this.type &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> itemId;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<DateTime> addedAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int itemId,
    required String name,
    this.imageUrl = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : type = Value(type),
       itemId = Value(itemId),
       name = Value(name);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? itemId,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int>? itemId,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<DateTime>? addedAt,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryTable extends WatchHistory
    with TableInfo<$WatchHistoryTable, WatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionSecsMeta = const VerificationMeta(
    'positionSecs',
  );
  @override
  late final GeneratedColumn<int> positionSecs = GeneratedColumn<int>(
    'position_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    itemId,
    name,
    imageUrl,
    positionSecs,
    durationSecs,
    watchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('position_secs')) {
      context.handle(
        _positionSecsMeta,
        positionSecs.isAcceptableOrUnknown(
          data['position_secs']!,
          _positionSecsMeta,
        ),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      positionSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_secs'],
      )!,
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $WatchHistoryTable createAlias(String alias) {
    return $WatchHistoryTable(attachedDatabase, alias);
  }
}

class WatchHistoryData extends DataClass
    implements Insertable<WatchHistoryData> {
  final int id;
  final String type;
  final int itemId;
  final String name;
  final String? imageUrl;
  final int positionSecs;
  final int? durationSecs;
  final DateTime watchedAt;
  const WatchHistoryData({
    required this.id,
    required this.type,
    required this.itemId,
    required this.name,
    this.imageUrl,
    required this.positionSecs,
    this.durationSecs,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['item_id'] = Variable<int>(itemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['position_secs'] = Variable<int>(positionSecs);
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  WatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryCompanion(
      id: Value(id),
      type: Value(type),
      itemId: Value(itemId),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      positionSecs: Value(positionSecs),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      watchedAt: Value(watchedAt),
    );
  }

  factory WatchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      itemId: serializer.fromJson<int>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      positionSecs: serializer.fromJson<int>(json['positionSecs']),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'itemId': serializer.toJson<int>(itemId),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'positionSecs': serializer.toJson<int>(positionSecs),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  WatchHistoryData copyWith({
    int? id,
    String? type,
    int? itemId,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    int? positionSecs,
    Value<int?> durationSecs = const Value.absent(),
    DateTime? watchedAt,
  }) => WatchHistoryData(
    id: id ?? this.id,
    type: type ?? this.type,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    positionSecs: positionSecs ?? this.positionSecs,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  WatchHistoryData copyWithCompanion(WatchHistoryCompanion data) {
    return WatchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      positionSecs: data.positionSecs.present
          ? data.positionSecs.value
          : this.positionSecs,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('positionSecs: $positionSecs, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    itemId,
    name,
    imageUrl,
    positionSecs,
    durationSecs,
    watchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryData &&
          other.id == this.id &&
          other.type == this.type &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.positionSecs == this.positionSecs &&
          other.durationSecs == this.durationSecs &&
          other.watchedAt == this.watchedAt);
}

class WatchHistoryCompanion extends UpdateCompanion<WatchHistoryData> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> itemId;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<int> positionSecs;
  final Value<int?> durationSecs;
  final Value<DateTime> watchedAt;
  const WatchHistoryCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.positionSecs = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.watchedAt = const Value.absent(),
  });
  WatchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int itemId,
    required String name,
    this.imageUrl = const Value.absent(),
    this.positionSecs = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.watchedAt = const Value.absent(),
  }) : type = Value(type),
       itemId = Value(itemId),
       name = Value(name);
  static Insertable<WatchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? itemId,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<int>? positionSecs,
    Expression<int>? durationSecs,
    Expression<DateTime>? watchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (positionSecs != null) 'position_secs': positionSecs,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (watchedAt != null) 'watched_at': watchedAt,
    });
  }

  WatchHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int>? itemId,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<int>? positionSecs,
    Value<int?>? durationSecs,
    Value<DateTime>? watchedAt,
  }) {
    return WatchHistoryCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      positionSecs: positionSecs ?? this.positionSecs,
      durationSecs: durationSecs ?? this.durationSecs,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (positionSecs.present) {
      map['position_secs'] = Variable<int>(positionSecs.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('positionSecs: $positionSecs, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityType,
    serverId,
    lastSyncedAt,
    etag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, serverId};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final String entityType;
  final int serverId;
  final DateTime lastSyncedAt;
  final String? etag;
  const SyncMetadataData({
    required this.entityType,
    required this.serverId,
    required this.lastSyncedAt,
    this.etag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['server_id'] = Variable<int>(serverId);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      entityType: Value(entityType),
      serverId: Value(serverId),
      lastSyncedAt: Value(lastSyncedAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory SyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      entityType: serializer.fromJson<String>(json['entityType']),
      serverId: serializer.fromJson<int>(json['serverId']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'serverId': serializer.toJson<int>(serverId),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  SyncMetadataData copyWith({
    String? entityType,
    int? serverId,
    DateTime? lastSyncedAt,
    Value<String?> etag = const Value.absent(),
  }) => SyncMetadataData(
    entityType: entityType ?? this.entityType,
    serverId: serverId ?? this.serverId,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    etag: etag.present ? etag.value : this.etag,
  );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('entityType: $entityType, ')
          ..write('serverId: $serverId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, serverId, lastSyncedAt, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.entityType == this.entityType &&
          other.serverId == this.serverId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.etag == this.etag);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> entityType;
  final Value<int> serverId;
  final Value<DateTime> lastSyncedAt;
  final Value<String?> etag;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.entityType = const Value.absent(),
    this.serverId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String entityType,
    required int serverId,
    required DateTime lastSyncedAt,
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       serverId = Value(serverId),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<SyncMetadataData> custom({
    Expression<String>? entityType,
    Expression<int>? serverId,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (serverId != null) 'server_id': serverId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? entityType,
    Value<int>? serverId,
    Value<DateTime>? lastSyncedAt,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      entityType: entityType ?? this.entityType,
      serverId: serverId ?? this.serverId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('entityType: $entityType, ')
          ..write('serverId: $serverId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $EpgProgramsTable epgPrograms = $EpgProgramsTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $WatchHistoryTable watchHistory = $WatchHistoryTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    channels,
    epgPrograms,
    movies,
    seriesTable,
    seasons,
    episodes,
    favorites,
    watchHistory,
    appSettings,
    syncMetadata,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String serverUrl,
      required String username,
      Value<String?> displayName,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> serverUrl,
      Value<String> username,
      Value<String?> displayName,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverUrl = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                serverUrl: serverUrl,
                username: username,
                displayName: displayName,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverUrl,
                required String username,
                Value<String?> displayName = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                serverUrl: serverUrl,
                username: username,
                displayName: displayName,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required int serverId,
      required String type,
      required String name,
      Value<int?> parentId,
      Value<DateTime> cachedAt,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<String> type,
      Value<String> name,
      Value<int?> parentId,
      Value<DateTime> cachedAt,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                serverId: serverId,
                type: type,
                name: name,
                parentId: parentId,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required String type,
                required String name,
                Value<int?> parentId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                serverId: serverId,
                type: type,
                name: name,
                parentId: parentId,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> id,
      required int serverId,
      required int streamId,
      Value<int?> categoryId,
      required String name,
      Value<String?> streamIcon,
      Value<String?> epgChannelId,
      Value<bool> tvArchive,
      Value<int?> tvArchiveDuration,
      Value<String> streamType,
      Value<DateTime> cachedAt,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<int> streamId,
      Value<int?> categoryId,
      Value<String> name,
      Value<String?> streamIcon,
      Value<String?> epgChannelId,
      Value<bool> tvArchive,
      Value<int?> tvArchiveDuration,
      Value<String> streamType,
      Value<DateTime> cachedAt,
    });

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tvArchiveDuration => $composableBuilder(
    column: $table.tvArchiveDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamType => $composableBuilder(
    column: $table.streamType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tvArchiveDuration => $composableBuilder(
    column: $table.tvArchiveDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamType => $composableBuilder(
    column: $table.streamType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tvArchive =>
      $composableBuilder(column: $table.tvArchive, builder: (column) => column);

  GeneratedColumn<int> get tvArchiveDuration => $composableBuilder(
    column: $table.tvArchiveDuration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamType => $composableBuilder(
    column: $table.streamType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          Channel,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (Channel, BaseReferences<_$AppDatabase, $ChannelsTable, Channel>),
          Channel,
          PrefetchHooks Function()
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<int> streamId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<int?> tvArchiveDuration = const Value.absent(),
                Value<String> streamType = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                serverId: serverId,
                streamId: streamId,
                categoryId: categoryId,
                name: name,
                streamIcon: streamIcon,
                epgChannelId: epgChannelId,
                tvArchive: tvArchive,
                tvArchiveDuration: tvArchiveDuration,
                streamType: streamType,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required int streamId,
                Value<int?> categoryId = const Value.absent(),
                required String name,
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<int?> tvArchiveDuration = const Value.absent(),
                Value<String> streamType = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                serverId: serverId,
                streamId: streamId,
                categoryId: categoryId,
                name: name,
                streamIcon: streamIcon,
                epgChannelId: epgChannelId,
                tvArchive: tvArchive,
                tvArchiveDuration: tvArchiveDuration,
                streamType: streamType,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      Channel,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (Channel, BaseReferences<_$AppDatabase, $ChannelsTable, Channel>),
      Channel,
      PrefetchHooks Function()
    >;
typedef $$EpgProgramsTableCreateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      required String epgId,
      Value<int?> channelId,
      required String title,
      Value<String?> description,
      required DateTime start,
      required DateTime end,
      Value<String> lang,
      Value<DateTime> cachedAt,
    });
typedef $$EpgProgramsTableUpdateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      Value<String> epgId,
      Value<int?> channelId,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> start,
      Value<DateTime> end,
      Value<String> lang,
      Value<DateTime> cachedAt,
    });

class $$EpgProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableFilterComposer({
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

  ColumnFilters<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpgProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableOrderingComposer({
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

  ColumnOrderings<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpgProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get epgId =>
      $composableBuilder(column: $table.epgId, builder: (column) => column);

  GeneratedColumn<int> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$EpgProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgProgramsTable,
          EpgProgram,
          $$EpgProgramsTableFilterComposer,
          $$EpgProgramsTableOrderingComposer,
          $$EpgProgramsTableAnnotationComposer,
          $$EpgProgramsTableCreateCompanionBuilder,
          $$EpgProgramsTableUpdateCompanionBuilder,
          (
            EpgProgram,
            BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram>,
          ),
          EpgProgram,
          PrefetchHooks Function()
        > {
  $$EpgProgramsTableTableManager(_$AppDatabase db, $EpgProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> epgId = const Value.absent(),
                Value<int?> channelId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<DateTime> end = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => EpgProgramsCompanion(
                id: id,
                epgId: epgId,
                channelId: channelId,
                title: title,
                description: description,
                start: start,
                end: end,
                lang: lang,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String epgId,
                Value<int?> channelId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required DateTime start,
                required DateTime end,
                Value<String> lang = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => EpgProgramsCompanion.insert(
                id: id,
                epgId: epgId,
                channelId: channelId,
                title: title,
                description: description,
                start: start,
                end: end,
                lang: lang,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpgProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgProgramsTable,
      EpgProgram,
      $$EpgProgramsTableFilterComposer,
      $$EpgProgramsTableOrderingComposer,
      $$EpgProgramsTableAnnotationComposer,
      $$EpgProgramsTableCreateCompanionBuilder,
      $$EpgProgramsTableUpdateCompanionBuilder,
      (
        EpgProgram,
        BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgram>,
      ),
      EpgProgram,
      PrefetchHooks Function()
    >;
typedef $$MoviesTableCreateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> id,
      required int serverId,
      required int streamId,
      Value<int?> categoryId,
      required String name,
      Value<String?> streamIcon,
      Value<String?> rating,
      Value<String?> genre,
      Value<String?> plot,
      Value<String?> cast,
      Value<String?> director,
      Value<int?> releaseDate,
      Value<int?> durationSecs,
      Value<String?> containerExtension,
      Value<DateTime> cachedAt,
    });
typedef $$MoviesTableUpdateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<int> streamId,
      Value<int?> categoryId,
      Value<String> name,
      Value<String?> streamIcon,
      Value<String?> rating,
      Value<String?> genre,
      Value<String?> plot,
      Value<String?> cast,
      Value<String?> director,
      Value<int?> releaseDate,
      Value<int?> durationSecs,
      Value<String?> containerExtension,
      Value<DateTime> cachedAt,
    });

class $$MoviesTableFilterComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<int> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          Movy,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (Movy, BaseReferences<_$AppDatabase, $MoviesTable, Movy>),
          Movy,
          PrefetchHooks Function()
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<int> streamId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> cast = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<int?> releaseDate = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => MoviesCompanion(
                id: id,
                serverId: serverId,
                streamId: streamId,
                categoryId: categoryId,
                name: name,
                streamIcon: streamIcon,
                rating: rating,
                genre: genre,
                plot: plot,
                cast: cast,
                director: director,
                releaseDate: releaseDate,
                durationSecs: durationSecs,
                containerExtension: containerExtension,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required int streamId,
                Value<int?> categoryId = const Value.absent(),
                required String name,
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> cast = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<int?> releaseDate = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => MoviesCompanion.insert(
                id: id,
                serverId: serverId,
                streamId: streamId,
                categoryId: categoryId,
                name: name,
                streamIcon: streamIcon,
                rating: rating,
                genre: genre,
                plot: plot,
                cast: cast,
                director: director,
                releaseDate: releaseDate,
                durationSecs: durationSecs,
                containerExtension: containerExtension,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      Movy,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (Movy, BaseReferences<_$AppDatabase, $MoviesTable, Movy>),
      Movy,
      PrefetchHooks Function()
    >;
typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<int> id,
      required int serverId,
      required int seriesId,
      Value<int?> categoryId,
      required String name,
      Value<String?> cover,
      Value<String?> plot,
      Value<String?> cast,
      Value<String?> director,
      Value<String?> genre,
      Value<String?> rating,
      Value<int?> releaseDate,
      Value<DateTime> cachedAt,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<int> seriesId,
      Value<int?> categoryId,
      Value<String> name,
      Value<String?> cover,
      Value<String?> plot,
      Value<String?> cast,
      Value<String?> director,
      Value<String?> genre,
      Value<String?> rating,
      Value<int?> releaseDate,
      Value<DateTime> cachedAt,
    });

class $$SeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTableTable,
          SeriesTableData,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (
            SeriesTableData,
            BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesTableData>,
          ),
          SeriesTableData,
          PrefetchHooks Function()
        > {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<int> seriesId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> cast = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<int?> releaseDate = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => SeriesTableCompanion(
                id: id,
                serverId: serverId,
                seriesId: seriesId,
                categoryId: categoryId,
                name: name,
                cover: cover,
                plot: plot,
                cast: cast,
                director: director,
                genre: genre,
                rating: rating,
                releaseDate: releaseDate,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required int seriesId,
                Value<int?> categoryId = const Value.absent(),
                required String name,
                Value<String?> cover = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> cast = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<int?> releaseDate = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                id: id,
                serverId: serverId,
                seriesId: seriesId,
                categoryId: categoryId,
                name: name,
                cover: cover,
                plot: plot,
                cast: cast,
                director: director,
                genre: genre,
                rating: rating,
                releaseDate: releaseDate,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTableTable,
      SeriesTableData,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (
        SeriesTableData,
        BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesTableData>,
      ),
      SeriesTableData,
      PrefetchHooks Function()
    >;
typedef $$SeasonsTableCreateCompanionBuilder =
    SeasonsCompanion Function({
      Value<int> id,
      required int seriesLocalId,
      required int seasonNumber,
      Value<String?> name,
      Value<String?> cover,
      Value<DateTime> cachedAt,
    });
typedef $$SeasonsTableUpdateCompanionBuilder =
    SeasonsCompanion Function({
      Value<int> id,
      Value<int> seriesLocalId,
      Value<int> seasonNumber,
      Value<String?> name,
      Value<String?> cover,
      Value<DateTime> cachedAt,
    });

class $$SeasonsTableFilterComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
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

  ColumnFilters<int> get seriesLocalId => $composableBuilder(
    column: $table.seriesLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeasonsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
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

  ColumnOrderings<int> get seriesLocalId => $composableBuilder(
    column: $table.seriesLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeasonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seriesLocalId => $composableBuilder(
    column: $table.seriesLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonsTable,
          Season,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (Season, BaseReferences<_$AppDatabase, $SeasonsTable, Season>),
          Season,
          PrefetchHooks Function()
        > {
  $$SeasonsTableTableManager(_$AppDatabase db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seriesLocalId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => SeasonsCompanion(
                id: id,
                seriesLocalId: seriesLocalId,
                seasonNumber: seasonNumber,
                name: name,
                cover: cover,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seriesLocalId,
                required int seasonNumber,
                Value<String?> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => SeasonsCompanion.insert(
                id: id,
                seriesLocalId: seriesLocalId,
                seasonNumber: seasonNumber,
                name: name,
                cover: cover,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonsTable,
      Season,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (Season, BaseReferences<_$AppDatabase, $SeasonsTable, Season>),
      Season,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      required int seasonLocalId,
      required int episodeNum,
      required String title,
      required int streamId,
      Value<String?> containerExtension,
      Value<int?> durationSecs,
      Value<String?> plot,
      Value<DateTime> cachedAt,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      Value<int> seasonLocalId,
      Value<int> episodeNum,
      Value<String> title,
      Value<int> streamId,
      Value<String?> containerExtension,
      Value<int?> durationSecs,
      Value<String?> plot,
      Value<DateTime> cachedAt,
    });

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
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

  ColumnFilters<int> get seasonLocalId => $composableBuilder(
    column: $table.seasonLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
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

  ColumnOrderings<int> get seasonLocalId => $composableBuilder(
    column: $table.seasonLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seasonLocalId => $composableBuilder(
    column: $table.seasonLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
          Episode,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seasonLocalId = const Value.absent(),
                Value<int> episodeNum = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> streamId = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                seasonLocalId: seasonLocalId,
                episodeNum: episodeNum,
                title: title,
                streamId: streamId,
                containerExtension: containerExtension,
                durationSecs: durationSecs,
                plot: plot,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seasonLocalId,
                required int episodeNum,
                required String title,
                required int streamId,
                Value<String?> containerExtension = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                seasonLocalId: seasonLocalId,
                episodeNum: episodeNum,
                title: title,
                streamId: streamId,
                containerExtension: containerExtension,
                durationSecs: durationSecs,
                plot: plot,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
      Episode,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      required String type,
      required int itemId,
      required String name,
      Value<String?> imageUrl,
      Value<DateTime> addedAt,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<int> itemId,
      Value<String> name,
      Value<String?> imageUrl,
      Value<DateTime> addedAt,
    });

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                type: type,
                itemId: itemId,
                name: name,
                imageUrl: imageUrl,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required int itemId,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FavoritesCompanion.insert(
                id: id,
                type: type,
                itemId: itemId,
                name: name,
                imageUrl: imageUrl,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$WatchHistoryTableCreateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<int> id,
      required String type,
      required int itemId,
      required String name,
      Value<String?> imageUrl,
      Value<int> positionSecs,
      Value<int?> durationSecs,
      Value<DateTime> watchedAt,
    });
typedef $$WatchHistoryTableUpdateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<int> itemId,
      Value<String> name,
      Value<String?> imageUrl,
      Value<int> positionSecs,
      Value<int?> durationSecs,
      Value<DateTime> watchedAt,
    });

class $$WatchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSecs => $composableBuilder(
    column: $table.positionSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSecs => $composableBuilder(
    column: $table.positionSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get positionSecs => $composableBuilder(
    column: $table.positionSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);
}

class $$WatchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchHistoryTable,
          WatchHistoryData,
          $$WatchHistoryTableFilterComposer,
          $$WatchHistoryTableOrderingComposer,
          $$WatchHistoryTableAnnotationComposer,
          $$WatchHistoryTableCreateCompanionBuilder,
          $$WatchHistoryTableUpdateCompanionBuilder,
          (
            WatchHistoryData,
            BaseReferences<_$AppDatabase, $WatchHistoryTable, WatchHistoryData>,
          ),
          WatchHistoryData,
          PrefetchHooks Function()
        > {
  $$WatchHistoryTableTableManager(_$AppDatabase db, $WatchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> positionSecs = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
              }) => WatchHistoryCompanion(
                id: id,
                type: type,
                itemId: itemId,
                name: name,
                imageUrl: imageUrl,
                positionSecs: positionSecs,
                durationSecs: durationSecs,
                watchedAt: watchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required int itemId,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                Value<int> positionSecs = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
              }) => WatchHistoryCompanion.insert(
                id: id,
                type: type,
                itemId: itemId,
                name: name,
                imageUrl: imageUrl,
                positionSecs: positionSecs,
                durationSecs: durationSecs,
                watchedAt: watchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchHistoryTable,
      WatchHistoryData,
      $$WatchHistoryTableFilterComposer,
      $$WatchHistoryTableOrderingComposer,
      $$WatchHistoryTableAnnotationComposer,
      $$WatchHistoryTableCreateCompanionBuilder,
      $$WatchHistoryTableUpdateCompanionBuilder,
      (
        WatchHistoryData,
        BaseReferences<_$AppDatabase, $WatchHistoryTable, WatchHistoryData>,
      ),
      WatchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String entityType,
      required int serverId,
      required DateTime lastSyncedAt,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> entityType,
      Value<int> serverId,
      Value<DateTime> lastSyncedAt,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataData,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataData,
            BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
          ),
          SyncMetadataData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(
                entityType: entityType,
                serverId: serverId,
                lastSyncedAt: lastSyncedAt,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required int serverId,
                required DateTime lastSyncedAt,
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                entityType: entityType,
                serverId: serverId,
                lastSyncedAt: lastSyncedAt,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataData,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataData,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
      ),
      SyncMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db, _db.epgPrograms);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$WatchHistoryTableTableManager get watchHistory =>
      $$WatchHistoryTableTableManager(_db, _db.watchHistory);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
