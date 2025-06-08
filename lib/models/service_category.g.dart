// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceCategoryImpl _$$ServiceCategoryImplFromJson(
  Map<String, dynamic> json,
) => _$ServiceCategoryImpl(
  id: json['id'] as String,
  nameTh: json['nameTh'] as String,
  nameEn: json['nameEn'] as String,
  icon: json['icon'] as String,
  subServices:
      (json['subServices'] as List<dynamic>)
          .map((e) => SubService.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$$ServiceCategoryImplToJson(
  _$ServiceCategoryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameTh': instance.nameTh,
  'nameEn': instance.nameEn,
  'icon': instance.icon,
  'subServices': instance.subServices,
};

_$SubServiceImpl _$$SubServiceImplFromJson(Map<String, dynamic> json) =>
    _$SubServiceImpl(
      id: json['id'] as String,
      nameTh: json['nameTh'] as String,
      nameEn: json['nameEn'] as String,
      icon: json['icon'] as String,
      descriptionTh: json['descriptionTh'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
    );

Map<String, dynamic> _$$SubServiceImplToJson(_$SubServiceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameTh': instance.nameTh,
      'nameEn': instance.nameEn,
      'icon': instance.icon,
      'descriptionTh': instance.descriptionTh,
      'descriptionEn': instance.descriptionEn,
    };
