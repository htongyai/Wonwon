// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ServiceCategory _$ServiceCategoryFromJson(Map<String, dynamic> json) {
  return _ServiceCategory.fromJson(json);
}

/// @nodoc
mixin _$ServiceCategory {
  String get id => throw _privateConstructorUsedError;
  String get nameTh => throw _privateConstructorUsedError;
  String get nameEn => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  List<SubService> get subServices => throw _privateConstructorUsedError;

  /// Serializes this ServiceCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceCategoryCopyWith<ServiceCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceCategoryCopyWith<$Res> {
  factory $ServiceCategoryCopyWith(
    ServiceCategory value,
    $Res Function(ServiceCategory) then,
  ) = _$ServiceCategoryCopyWithImpl<$Res, ServiceCategory>;
  @useResult
  $Res call({
    String id,
    String nameTh,
    String nameEn,
    String icon,
    List<SubService> subServices,
  });
}

/// @nodoc
class _$ServiceCategoryCopyWithImpl<$Res, $Val extends ServiceCategory>
    implements $ServiceCategoryCopyWith<$Res> {
  _$ServiceCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameTh = null,
    Object? nameEn = null,
    Object? icon = null,
    Object? subServices = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            nameTh:
                null == nameTh
                    ? _value.nameTh
                    : nameTh // ignore: cast_nullable_to_non_nullable
                        as String,
            nameEn:
                null == nameEn
                    ? _value.nameEn
                    : nameEn // ignore: cast_nullable_to_non_nullable
                        as String,
            icon:
                null == icon
                    ? _value.icon
                    : icon // ignore: cast_nullable_to_non_nullable
                        as String,
            subServices:
                null == subServices
                    ? _value.subServices
                    : subServices // ignore: cast_nullable_to_non_nullable
                        as List<SubService>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceCategoryImplCopyWith<$Res>
    implements $ServiceCategoryCopyWith<$Res> {
  factory _$$ServiceCategoryImplCopyWith(
    _$ServiceCategoryImpl value,
    $Res Function(_$ServiceCategoryImpl) then,
  ) = __$$ServiceCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String nameTh,
    String nameEn,
    String icon,
    List<SubService> subServices,
  });
}

/// @nodoc
class __$$ServiceCategoryImplCopyWithImpl<$Res>
    extends _$ServiceCategoryCopyWithImpl<$Res, _$ServiceCategoryImpl>
    implements _$$ServiceCategoryImplCopyWith<$Res> {
  __$$ServiceCategoryImplCopyWithImpl(
    _$ServiceCategoryImpl _value,
    $Res Function(_$ServiceCategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameTh = null,
    Object? nameEn = null,
    Object? icon = null,
    Object? subServices = null,
  }) {
    return _then(
      _$ServiceCategoryImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        nameTh:
            null == nameTh
                ? _value.nameTh
                : nameTh // ignore: cast_nullable_to_non_nullable
                    as String,
        nameEn:
            null == nameEn
                ? _value.nameEn
                : nameEn // ignore: cast_nullable_to_non_nullable
                    as String,
        icon:
            null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                    as String,
        subServices:
            null == subServices
                ? _value._subServices
                : subServices // ignore: cast_nullable_to_non_nullable
                    as List<SubService>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceCategoryImpl implements _ServiceCategory {
  const _$ServiceCategoryImpl({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.icon,
    required final List<SubService> subServices,
  }) : _subServices = subServices;

  factory _$ServiceCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String nameTh;
  @override
  final String nameEn;
  @override
  final String icon;
  final List<SubService> _subServices;
  @override
  List<SubService> get subServices {
    if (_subServices is EqualUnmodifiableListView) return _subServices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subServices);
  }

  @override
  String toString() {
    return 'ServiceCategory(id: $id, nameTh: $nameTh, nameEn: $nameEn, icon: $icon, subServices: $subServices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameTh, nameTh) || other.nameTh == nameTh) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(
              other._subServices,
              _subServices,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nameTh,
    nameEn,
    icon,
    const DeepCollectionEquality().hash(_subServices),
  );

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceCategoryImplCopyWith<_$ServiceCategoryImpl> get copyWith =>
      __$$ServiceCategoryImplCopyWithImpl<_$ServiceCategoryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceCategoryImplToJson(this);
  }
}

abstract class _ServiceCategory implements ServiceCategory {
  const factory _ServiceCategory({
    required final String id,
    required final String nameTh,
    required final String nameEn,
    required final String icon,
    required final List<SubService> subServices,
  }) = _$ServiceCategoryImpl;

  factory _ServiceCategory.fromJson(Map<String, dynamic> json) =
      _$ServiceCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get nameTh;
  @override
  String get nameEn;
  @override
  String get icon;
  @override
  List<SubService> get subServices;

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceCategoryImplCopyWith<_$ServiceCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubService _$SubServiceFromJson(Map<String, dynamic> json) {
  return _SubService.fromJson(json);
}

/// @nodoc
mixin _$SubService {
  String get id => throw _privateConstructorUsedError;
  String get nameTh => throw _privateConstructorUsedError;
  String get nameEn => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  String? get descriptionTh => throw _privateConstructorUsedError;
  String? get descriptionEn => throw _privateConstructorUsedError;

  /// Serializes this SubService to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubService
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubServiceCopyWith<SubService> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubServiceCopyWith<$Res> {
  factory $SubServiceCopyWith(
    SubService value,
    $Res Function(SubService) then,
  ) = _$SubServiceCopyWithImpl<$Res, SubService>;
  @useResult
  $Res call({
    String id,
    String nameTh,
    String nameEn,
    String icon,
    String? descriptionTh,
    String? descriptionEn,
  });
}

/// @nodoc
class _$SubServiceCopyWithImpl<$Res, $Val extends SubService>
    implements $SubServiceCopyWith<$Res> {
  _$SubServiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubService
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameTh = null,
    Object? nameEn = null,
    Object? icon = null,
    Object? descriptionTh = freezed,
    Object? descriptionEn = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            nameTh:
                null == nameTh
                    ? _value.nameTh
                    : nameTh // ignore: cast_nullable_to_non_nullable
                        as String,
            nameEn:
                null == nameEn
                    ? _value.nameEn
                    : nameEn // ignore: cast_nullable_to_non_nullable
                        as String,
            icon:
                null == icon
                    ? _value.icon
                    : icon // ignore: cast_nullable_to_non_nullable
                        as String,
            descriptionTh:
                freezed == descriptionTh
                    ? _value.descriptionTh
                    : descriptionTh // ignore: cast_nullable_to_non_nullable
                        as String?,
            descriptionEn:
                freezed == descriptionEn
                    ? _value.descriptionEn
                    : descriptionEn // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubServiceImplCopyWith<$Res>
    implements $SubServiceCopyWith<$Res> {
  factory _$$SubServiceImplCopyWith(
    _$SubServiceImpl value,
    $Res Function(_$SubServiceImpl) then,
  ) = __$$SubServiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String nameTh,
    String nameEn,
    String icon,
    String? descriptionTh,
    String? descriptionEn,
  });
}

/// @nodoc
class __$$SubServiceImplCopyWithImpl<$Res>
    extends _$SubServiceCopyWithImpl<$Res, _$SubServiceImpl>
    implements _$$SubServiceImplCopyWith<$Res> {
  __$$SubServiceImplCopyWithImpl(
    _$SubServiceImpl _value,
    $Res Function(_$SubServiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubService
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameTh = null,
    Object? nameEn = null,
    Object? icon = null,
    Object? descriptionTh = freezed,
    Object? descriptionEn = freezed,
  }) {
    return _then(
      _$SubServiceImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        nameTh:
            null == nameTh
                ? _value.nameTh
                : nameTh // ignore: cast_nullable_to_non_nullable
                    as String,
        nameEn:
            null == nameEn
                ? _value.nameEn
                : nameEn // ignore: cast_nullable_to_non_nullable
                    as String,
        icon:
            null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                    as String,
        descriptionTh:
            freezed == descriptionTh
                ? _value.descriptionTh
                : descriptionTh // ignore: cast_nullable_to_non_nullable
                    as String?,
        descriptionEn:
            freezed == descriptionEn
                ? _value.descriptionEn
                : descriptionEn // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubServiceImpl implements _SubService {
  const _$SubServiceImpl({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.icon,
    this.descriptionTh,
    this.descriptionEn,
  });

  factory _$SubServiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubServiceImplFromJson(json);

  @override
  final String id;
  @override
  final String nameTh;
  @override
  final String nameEn;
  @override
  final String icon;
  @override
  final String? descriptionTh;
  @override
  final String? descriptionEn;

  @override
  String toString() {
    return 'SubService(id: $id, nameTh: $nameTh, nameEn: $nameEn, icon: $icon, descriptionTh: $descriptionTh, descriptionEn: $descriptionEn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubServiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameTh, nameTh) || other.nameTh == nameTh) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.descriptionTh, descriptionTh) ||
                other.descriptionTh == descriptionTh) &&
            (identical(other.descriptionEn, descriptionEn) ||
                other.descriptionEn == descriptionEn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nameTh,
    nameEn,
    icon,
    descriptionTh,
    descriptionEn,
  );

  /// Create a copy of SubService
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubServiceImplCopyWith<_$SubServiceImpl> get copyWith =>
      __$$SubServiceImplCopyWithImpl<_$SubServiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubServiceImplToJson(this);
  }
}

abstract class _SubService implements SubService {
  const factory _SubService({
    required final String id,
    required final String nameTh,
    required final String nameEn,
    required final String icon,
    final String? descriptionTh,
    final String? descriptionEn,
  }) = _$SubServiceImpl;

  factory _SubService.fromJson(Map<String, dynamic> json) =
      _$SubServiceImpl.fromJson;

  @override
  String get id;
  @override
  String get nameTh;
  @override
  String get nameEn;
  @override
  String get icon;
  @override
  String? get descriptionTh;
  @override
  String? get descriptionEn;

  /// Create a copy of SubService
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubServiceImplCopyWith<_$SubServiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
