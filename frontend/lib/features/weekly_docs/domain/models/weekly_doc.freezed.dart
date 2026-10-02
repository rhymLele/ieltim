// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_doc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VocabItem {

 String get word; String get partOfSpeech; String get ipa; String get meaning;
/// Create a copy of VocabItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VocabItemCopyWith<VocabItem> get copyWith => _$VocabItemCopyWithImpl<VocabItem>(this as VocabItem, _$identity);

  /// Serializes this VocabItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VocabItem&&(identical(other.word, word) || other.word == word)&&(identical(other.partOfSpeech, partOfSpeech) || other.partOfSpeech == partOfSpeech)&&(identical(other.ipa, ipa) || other.ipa == ipa)&&(identical(other.meaning, meaning) || other.meaning == meaning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,partOfSpeech,ipa,meaning);

@override
String toString() {
  return 'VocabItem(word: $word, partOfSpeech: $partOfSpeech, ipa: $ipa, meaning: $meaning)';
}


}

/// @nodoc
abstract mixin class $VocabItemCopyWith<$Res>  {
  factory $VocabItemCopyWith(VocabItem value, $Res Function(VocabItem) _then) = _$VocabItemCopyWithImpl;
@useResult
$Res call({
 String word, String partOfSpeech, String ipa, String meaning
});




}
/// @nodoc
class _$VocabItemCopyWithImpl<$Res>
    implements $VocabItemCopyWith<$Res> {
  _$VocabItemCopyWithImpl(this._self, this._then);

  final VocabItem _self;
  final $Res Function(VocabItem) _then;

/// Create a copy of VocabItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? word = null,Object? partOfSpeech = null,Object? ipa = null,Object? meaning = null,}) {
  return _then(_self.copyWith(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,partOfSpeech: null == partOfSpeech ? _self.partOfSpeech : partOfSpeech // ignore: cast_nullable_to_non_nullable
as String,ipa: null == ipa ? _self.ipa : ipa // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VocabItem].
extension VocabItemPatterns on VocabItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VocabItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VocabItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VocabItem value)  $default,){
final _that = this;
switch (_that) {
case _VocabItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VocabItem value)?  $default,){
final _that = this;
switch (_that) {
case _VocabItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String word,  String partOfSpeech,  String ipa,  String meaning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VocabItem() when $default != null:
return $default(_that.word,_that.partOfSpeech,_that.ipa,_that.meaning);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String word,  String partOfSpeech,  String ipa,  String meaning)  $default,) {final _that = this;
switch (_that) {
case _VocabItem():
return $default(_that.word,_that.partOfSpeech,_that.ipa,_that.meaning);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String word,  String partOfSpeech,  String ipa,  String meaning)?  $default,) {final _that = this;
switch (_that) {
case _VocabItem() when $default != null:
return $default(_that.word,_that.partOfSpeech,_that.ipa,_that.meaning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VocabItem implements VocabItem {
  const _VocabItem({required this.word, this.partOfSpeech = '', this.ipa = '', this.meaning = ''});
  factory _VocabItem.fromJson(Map<String, dynamic> json) => _$VocabItemFromJson(json);

@override final  String word;
@override@JsonKey() final  String partOfSpeech;
@override@JsonKey() final  String ipa;
@override@JsonKey() final  String meaning;

/// Create a copy of VocabItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VocabItemCopyWith<_VocabItem> get copyWith => __$VocabItemCopyWithImpl<_VocabItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VocabItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VocabItem&&(identical(other.word, word) || other.word == word)&&(identical(other.partOfSpeech, partOfSpeech) || other.partOfSpeech == partOfSpeech)&&(identical(other.ipa, ipa) || other.ipa == ipa)&&(identical(other.meaning, meaning) || other.meaning == meaning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,partOfSpeech,ipa,meaning);

@override
String toString() {
  return 'VocabItem(word: $word, partOfSpeech: $partOfSpeech, ipa: $ipa, meaning: $meaning)';
}


}

/// @nodoc
abstract mixin class _$VocabItemCopyWith<$Res> implements $VocabItemCopyWith<$Res> {
  factory _$VocabItemCopyWith(_VocabItem value, $Res Function(_VocabItem) _then) = __$VocabItemCopyWithImpl;
@override @useResult
$Res call({
 String word, String partOfSpeech, String ipa, String meaning
});




}
/// @nodoc
class __$VocabItemCopyWithImpl<$Res>
    implements _$VocabItemCopyWith<$Res> {
  __$VocabItemCopyWithImpl(this._self, this._then);

  final _VocabItem _self;
  final $Res Function(_VocabItem) _then;

/// Create a copy of VocabItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? word = null,Object? partOfSpeech = null,Object? ipa = null,Object? meaning = null,}) {
  return _then(_VocabItem(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,partOfSpeech: null == partOfSpeech ? _self.partOfSpeech : partOfSpeech // ignore: cast_nullable_to_non_nullable
as String,ipa: null == ipa ? _self.ipa : ipa // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocMeta {

 String get title; int get week; int get order; List<String> get skills; int get estimatedMinutes; DocStatus get status; DocViewMode get defaultView; List<DocViewMode> get allowedViews; bool get allowUserSwitchView; String? get publishAt; String? get id; int get version; String? get createdAt; String? get updatedAt;
/// Create a copy of DocMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocMetaCopyWith<DocMeta> get copyWith => _$DocMetaCopyWithImpl<DocMeta>(this as DocMeta, _$identity);

  /// Serializes this DocMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocMeta&&(identical(other.title, title) || other.title == title)&&(identical(other.week, week) || other.week == week)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.skills, skills)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.defaultView, defaultView) || other.defaultView == defaultView)&&const DeepCollectionEquality().equals(other.allowedViews, allowedViews)&&(identical(other.allowUserSwitchView, allowUserSwitchView) || other.allowUserSwitchView == allowUserSwitchView)&&(identical(other.publishAt, publishAt) || other.publishAt == publishAt)&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,week,order,const DeepCollectionEquality().hash(skills),estimatedMinutes,status,defaultView,const DeepCollectionEquality().hash(allowedViews),allowUserSwitchView,publishAt,id,version,createdAt,updatedAt);

@override
String toString() {
  return 'DocMeta(title: $title, week: $week, order: $order, skills: $skills, estimatedMinutes: $estimatedMinutes, status: $status, defaultView: $defaultView, allowedViews: $allowedViews, allowUserSwitchView: $allowUserSwitchView, publishAt: $publishAt, id: $id, version: $version, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DocMetaCopyWith<$Res>  {
  factory $DocMetaCopyWith(DocMeta value, $Res Function(DocMeta) _then) = _$DocMetaCopyWithImpl;
@useResult
$Res call({
 String title, int week, int order, List<String> skills, int estimatedMinutes, DocStatus status, DocViewMode defaultView, List<DocViewMode> allowedViews, bool allowUserSwitchView, String? publishAt, String? id, int version, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$DocMetaCopyWithImpl<$Res>
    implements $DocMetaCopyWith<$Res> {
  _$DocMetaCopyWithImpl(this._self, this._then);

  final DocMeta _self;
  final $Res Function(DocMeta) _then;

/// Create a copy of DocMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? week = null,Object? order = null,Object? skills = null,Object? estimatedMinutes = null,Object? status = null,Object? defaultView = null,Object? allowedViews = null,Object? allowUserSwitchView = null,Object? publishAt = freezed,Object? id = freezed,Object? version = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedMinutes: null == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocStatus,defaultView: null == defaultView ? _self.defaultView : defaultView // ignore: cast_nullable_to_non_nullable
as DocViewMode,allowedViews: null == allowedViews ? _self.allowedViews : allowedViews // ignore: cast_nullable_to_non_nullable
as List<DocViewMode>,allowUserSwitchView: null == allowUserSwitchView ? _self.allowUserSwitchView : allowUserSwitchView // ignore: cast_nullable_to_non_nullable
as bool,publishAt: freezed == publishAt ? _self.publishAt : publishAt // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocMeta].
extension DocMetaPatterns on DocMeta {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocMeta() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocMeta value)  $default,){
final _that = this;
switch (_that) {
case _DocMeta():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocMeta value)?  $default,){
final _that = this;
switch (_that) {
case _DocMeta() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int week,  int order,  List<String> skills,  int estimatedMinutes,  DocStatus status,  DocViewMode defaultView,  List<DocViewMode> allowedViews,  bool allowUserSwitchView,  String? publishAt,  String? id,  int version,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocMeta() when $default != null:
return $default(_that.title,_that.week,_that.order,_that.skills,_that.estimatedMinutes,_that.status,_that.defaultView,_that.allowedViews,_that.allowUserSwitchView,_that.publishAt,_that.id,_that.version,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int week,  int order,  List<String> skills,  int estimatedMinutes,  DocStatus status,  DocViewMode defaultView,  List<DocViewMode> allowedViews,  bool allowUserSwitchView,  String? publishAt,  String? id,  int version,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DocMeta():
return $default(_that.title,_that.week,_that.order,_that.skills,_that.estimatedMinutes,_that.status,_that.defaultView,_that.allowedViews,_that.allowUserSwitchView,_that.publishAt,_that.id,_that.version,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int week,  int order,  List<String> skills,  int estimatedMinutes,  DocStatus status,  DocViewMode defaultView,  List<DocViewMode> allowedViews,  bool allowUserSwitchView,  String? publishAt,  String? id,  int version,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocMeta() when $default != null:
return $default(_that.title,_that.week,_that.order,_that.skills,_that.estimatedMinutes,_that.status,_that.defaultView,_that.allowedViews,_that.allowUserSwitchView,_that.publishAt,_that.id,_that.version,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocMeta extends DocMeta {
  const _DocMeta({this.title = '', this.week = 1, this.order = 1, final  List<String> skills = const [], this.estimatedMinutes = 10, this.status = DocStatus.draft, this.defaultView = DocViewMode.slide, final  List<DocViewMode> allowedViews = const [DocViewMode.slide, DocViewMode.doc], this.allowUserSwitchView = true, this.publishAt, this.id, this.version = 1, this.createdAt, this.updatedAt}): _skills = skills,_allowedViews = allowedViews,super._();
  factory _DocMeta.fromJson(Map<String, dynamic> json) => _$DocMetaFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  int week;
@override@JsonKey() final  int order;
 final  List<String> _skills;
@override@JsonKey() List<String> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

@override@JsonKey() final  int estimatedMinutes;
@override@JsonKey() final  DocStatus status;
@override@JsonKey() final  DocViewMode defaultView;
 final  List<DocViewMode> _allowedViews;
@override@JsonKey() List<DocViewMode> get allowedViews {
  if (_allowedViews is EqualUnmodifiableListView) return _allowedViews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedViews);
}

@override@JsonKey() final  bool allowUserSwitchView;
@override final  String? publishAt;
@override final  String? id;
@override@JsonKey() final  int version;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of DocMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocMetaCopyWith<_DocMeta> get copyWith => __$DocMetaCopyWithImpl<_DocMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocMeta&&(identical(other.title, title) || other.title == title)&&(identical(other.week, week) || other.week == week)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._skills, _skills)&&(identical(other.estimatedMinutes, estimatedMinutes) || other.estimatedMinutes == estimatedMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.defaultView, defaultView) || other.defaultView == defaultView)&&const DeepCollectionEquality().equals(other._allowedViews, _allowedViews)&&(identical(other.allowUserSwitchView, allowUserSwitchView) || other.allowUserSwitchView == allowUserSwitchView)&&(identical(other.publishAt, publishAt) || other.publishAt == publishAt)&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,week,order,const DeepCollectionEquality().hash(_skills),estimatedMinutes,status,defaultView,const DeepCollectionEquality().hash(_allowedViews),allowUserSwitchView,publishAt,id,version,createdAt,updatedAt);

@override
String toString() {
  return 'DocMeta(title: $title, week: $week, order: $order, skills: $skills, estimatedMinutes: $estimatedMinutes, status: $status, defaultView: $defaultView, allowedViews: $allowedViews, allowUserSwitchView: $allowUserSwitchView, publishAt: $publishAt, id: $id, version: $version, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocMetaCopyWith<$Res> implements $DocMetaCopyWith<$Res> {
  factory _$DocMetaCopyWith(_DocMeta value, $Res Function(_DocMeta) _then) = __$DocMetaCopyWithImpl;
@override @useResult
$Res call({
 String title, int week, int order, List<String> skills, int estimatedMinutes, DocStatus status, DocViewMode defaultView, List<DocViewMode> allowedViews, bool allowUserSwitchView, String? publishAt, String? id, int version, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$DocMetaCopyWithImpl<$Res>
    implements _$DocMetaCopyWith<$Res> {
  __$DocMetaCopyWithImpl(this._self, this._then);

  final _DocMeta _self;
  final $Res Function(_DocMeta) _then;

/// Create a copy of DocMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? week = null,Object? order = null,Object? skills = null,Object? estimatedMinutes = null,Object? status = null,Object? defaultView = null,Object? allowedViews = null,Object? allowUserSwitchView = null,Object? publishAt = freezed,Object? id = freezed,Object? version = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DocMeta(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedMinutes: null == estimatedMinutes ? _self.estimatedMinutes : estimatedMinutes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocStatus,defaultView: null == defaultView ? _self.defaultView : defaultView // ignore: cast_nullable_to_non_nullable
as DocViewMode,allowedViews: null == allowedViews ? _self._allowedViews : allowedViews // ignore: cast_nullable_to_non_nullable
as List<DocViewMode>,allowUserSwitchView: null == allowUserSwitchView ? _self.allowUserSwitchView : allowUserSwitchView // ignore: cast_nullable_to_non_nullable
as bool,publishAt: freezed == publishAt ? _self.publishAt : publishAt // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$DocSection {

 String? get id; int? get number; String get title; List<DocBlock> get blocks;
/// Create a copy of DocSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocSectionCopyWith<DocSection> get copyWith => _$DocSectionCopyWithImpl<DocSection>(this as DocSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocSection&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.blocks, blocks));
}


@override
int get hashCode => Object.hash(runtimeType,id,number,title,const DeepCollectionEquality().hash(blocks));

@override
String toString() {
  return 'DocSection(id: $id, number: $number, title: $title, blocks: $blocks)';
}


}

/// @nodoc
abstract mixin class $DocSectionCopyWith<$Res>  {
  factory $DocSectionCopyWith(DocSection value, $Res Function(DocSection) _then) = _$DocSectionCopyWithImpl;
@useResult
$Res call({
 String? id, int? number, String title, List<DocBlock> blocks
});




}
/// @nodoc
class _$DocSectionCopyWithImpl<$Res>
    implements $DocSectionCopyWith<$Res> {
  _$DocSectionCopyWithImpl(this._self, this._then);

  final DocSection _self;
  final $Res Function(DocSection) _then;

/// Create a copy of DocSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? number = freezed,Object? title = null,Object? blocks = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<DocBlock>,
  ));
}

}


/// Adds pattern-matching-related methods to [DocSection].
extension DocSectionPatterns on DocSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocSection value)  $default,){
final _that = this;
switch (_that) {
case _DocSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocSection value)?  $default,){
final _that = this;
switch (_that) {
case _DocSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  int? number,  String title,  List<DocBlock> blocks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocSection() when $default != null:
return $default(_that.id,_that.number,_that.title,_that.blocks);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  int? number,  String title,  List<DocBlock> blocks)  $default,) {final _that = this;
switch (_that) {
case _DocSection():
return $default(_that.id,_that.number,_that.title,_that.blocks);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  int? number,  String title,  List<DocBlock> blocks)?  $default,) {final _that = this;
switch (_that) {
case _DocSection() when $default != null:
return $default(_that.id,_that.number,_that.title,_that.blocks);case _:
  return null;

}
}

}

/// @nodoc


class _DocSection implements DocSection {
  const _DocSection({this.id = null, this.number = null, this.title = '', final  List<DocBlock> blocks = const []}): _blocks = blocks;
  

@override@JsonKey() final  String? id;
@override@JsonKey() final  int? number;
@override@JsonKey() final  String title;
 final  List<DocBlock> _blocks;
@override@JsonKey() List<DocBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}


/// Create a copy of DocSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocSectionCopyWith<_DocSection> get copyWith => __$DocSectionCopyWithImpl<_DocSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocSection&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._blocks, _blocks));
}


@override
int get hashCode => Object.hash(runtimeType,id,number,title,const DeepCollectionEquality().hash(_blocks));

@override
String toString() {
  return 'DocSection(id: $id, number: $number, title: $title, blocks: $blocks)';
}


}

/// @nodoc
abstract mixin class _$DocSectionCopyWith<$Res> implements $DocSectionCopyWith<$Res> {
  factory _$DocSectionCopyWith(_DocSection value, $Res Function(_DocSection) _then) = __$DocSectionCopyWithImpl;
@override @useResult
$Res call({
 String? id, int? number, String title, List<DocBlock> blocks
});




}
/// @nodoc
class __$DocSectionCopyWithImpl<$Res>
    implements _$DocSectionCopyWith<$Res> {
  __$DocSectionCopyWithImpl(this._self, this._then);

  final _DocSection _self;
  final $Res Function(_DocSection) _then;

/// Create a copy of DocSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? number = freezed,Object? title = null,Object? blocks = null,}) {
  return _then(_DocSection(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<DocBlock>,
  ));
}


}

/// @nodoc
mixin _$WeeklyDoc {

 String get id; DocMeta get meta; List<DocSection> get sections;
/// Create a copy of WeeklyDoc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyDocCopyWith<WeeklyDoc> get copyWith => _$WeeklyDocCopyWithImpl<WeeklyDoc>(this as WeeklyDoc, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyDoc&&(identical(other.id, id) || other.id == id)&&(identical(other.meta, meta) || other.meta == meta)&&const DeepCollectionEquality().equals(other.sections, sections));
}


@override
int get hashCode => Object.hash(runtimeType,id,meta,const DeepCollectionEquality().hash(sections));

@override
String toString() {
  return 'WeeklyDoc(id: $id, meta: $meta, sections: $sections)';
}


}

/// @nodoc
abstract mixin class $WeeklyDocCopyWith<$Res>  {
  factory $WeeklyDocCopyWith(WeeklyDoc value, $Res Function(WeeklyDoc) _then) = _$WeeklyDocCopyWithImpl;
@useResult
$Res call({
 String id, DocMeta meta, List<DocSection> sections
});


$DocMetaCopyWith<$Res> get meta;

}
/// @nodoc
class _$WeeklyDocCopyWithImpl<$Res>
    implements $WeeklyDocCopyWith<$Res> {
  _$WeeklyDocCopyWithImpl(this._self, this._then);

  final WeeklyDoc _self;
  final $Res Function(WeeklyDoc) _then;

/// Create a copy of WeeklyDoc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? meta = null,Object? sections = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as DocMeta,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<DocSection>,
  ));
}
/// Create a copy of WeeklyDoc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocMetaCopyWith<$Res> get meta {
  
  return $DocMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeeklyDoc].
extension WeeklyDocPatterns on WeeklyDoc {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyDoc value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyDoc() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyDoc value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyDoc():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyDoc value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyDoc() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DocMeta meta,  List<DocSection> sections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyDoc() when $default != null:
return $default(_that.id,_that.meta,_that.sections);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DocMeta meta,  List<DocSection> sections)  $default,) {final _that = this;
switch (_that) {
case _WeeklyDoc():
return $default(_that.id,_that.meta,_that.sections);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DocMeta meta,  List<DocSection> sections)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyDoc() when $default != null:
return $default(_that.id,_that.meta,_that.sections);case _:
  return null;

}
}

}

/// @nodoc


class _WeeklyDoc extends WeeklyDoc {
  const _WeeklyDoc({required this.id, required this.meta, final  List<DocSection> sections = const []}): _sections = sections,super._();
  

@override final  String id;
@override final  DocMeta meta;
 final  List<DocSection> _sections;
@override@JsonKey() List<DocSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}


/// Create a copy of WeeklyDoc
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyDocCopyWith<_WeeklyDoc> get copyWith => __$WeeklyDocCopyWithImpl<_WeeklyDoc>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyDoc&&(identical(other.id, id) || other.id == id)&&(identical(other.meta, meta) || other.meta == meta)&&const DeepCollectionEquality().equals(other._sections, _sections));
}


@override
int get hashCode => Object.hash(runtimeType,id,meta,const DeepCollectionEquality().hash(_sections));

@override
String toString() {
  return 'WeeklyDoc(id: $id, meta: $meta, sections: $sections)';
}


}

/// @nodoc
abstract mixin class _$WeeklyDocCopyWith<$Res> implements $WeeklyDocCopyWith<$Res> {
  factory _$WeeklyDocCopyWith(_WeeklyDoc value, $Res Function(_WeeklyDoc) _then) = __$WeeklyDocCopyWithImpl;
@override @useResult
$Res call({
 String id, DocMeta meta, List<DocSection> sections
});


@override $DocMetaCopyWith<$Res> get meta;

}
/// @nodoc
class __$WeeklyDocCopyWithImpl<$Res>
    implements _$WeeklyDocCopyWith<$Res> {
  __$WeeklyDocCopyWithImpl(this._self, this._then);

  final _WeeklyDoc _self;
  final $Res Function(_WeeklyDoc) _then;

/// Create a copy of WeeklyDoc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? meta = null,Object? sections = null,}) {
  return _then(_WeeklyDoc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as DocMeta,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<DocSection>,
  ));
}

/// Create a copy of WeeklyDoc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocMetaCopyWith<$Res> get meta {
  
  return $DocMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}

/// @nodoc
mixin _$DocBlock {

 String? get id;
/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocBlockCopyWith<DocBlock> get copyWith => _$DocBlockCopyWithImpl<DocBlock>(this as DocBlock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocBlock&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'DocBlock(id: $id)';
}


}

/// @nodoc
abstract mixin class $DocBlockCopyWith<$Res>  {
  factory $DocBlockCopyWith(DocBlock value, $Res Function(DocBlock) _then) = _$DocBlockCopyWithImpl;
@useResult
$Res call({
 String? id
});




}
/// @nodoc
class _$DocBlockCopyWithImpl<$Res>
    implements $DocBlockCopyWith<$Res> {
  _$DocBlockCopyWithImpl(this._self, this._then);

  final DocBlock _self;
  final $Res Function(DocBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocBlock].
extension DocBlockPatterns on DocBlock {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HeadingBlock value)?  heading,TResult Function( ParagraphBlock value)?  paragraph,TResult Function( CalloutBlock value)?  callout,TResult Function( StepsBlock value)?  steps,TResult Function( PassageBlock value)?  passage,TResult Function( QuizBlock value)?  quiz,TResult Function( VocabBlock value)?  vocab,TResult Function( PatternBlock value)?  pattern,TResult Function( ImageBlock value)?  image,TResult Function( SlideBreakBlock value)?  slideBreak,TResult Function( UnknownBlock value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that);case ParagraphBlock() when paragraph != null:
return paragraph(_that);case CalloutBlock() when callout != null:
return callout(_that);case StepsBlock() when steps != null:
return steps(_that);case PassageBlock() when passage != null:
return passage(_that);case QuizBlock() when quiz != null:
return quiz(_that);case VocabBlock() when vocab != null:
return vocab(_that);case PatternBlock() when pattern != null:
return pattern(_that);case ImageBlock() when image != null:
return image(_that);case SlideBreakBlock() when slideBreak != null:
return slideBreak(_that);case UnknownBlock() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HeadingBlock value)  heading,required TResult Function( ParagraphBlock value)  paragraph,required TResult Function( CalloutBlock value)  callout,required TResult Function( StepsBlock value)  steps,required TResult Function( PassageBlock value)  passage,required TResult Function( QuizBlock value)  quiz,required TResult Function( VocabBlock value)  vocab,required TResult Function( PatternBlock value)  pattern,required TResult Function( ImageBlock value)  image,required TResult Function( SlideBreakBlock value)  slideBreak,required TResult Function( UnknownBlock value)  unknown,}){
final _that = this;
switch (_that) {
case HeadingBlock():
return heading(_that);case ParagraphBlock():
return paragraph(_that);case CalloutBlock():
return callout(_that);case StepsBlock():
return steps(_that);case PassageBlock():
return passage(_that);case QuizBlock():
return quiz(_that);case VocabBlock():
return vocab(_that);case PatternBlock():
return pattern(_that);case ImageBlock():
return image(_that);case SlideBreakBlock():
return slideBreak(_that);case UnknownBlock():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HeadingBlock value)?  heading,TResult? Function( ParagraphBlock value)?  paragraph,TResult? Function( CalloutBlock value)?  callout,TResult? Function( StepsBlock value)?  steps,TResult? Function( PassageBlock value)?  passage,TResult? Function( QuizBlock value)?  quiz,TResult? Function( VocabBlock value)?  vocab,TResult? Function( PatternBlock value)?  pattern,TResult? Function( ImageBlock value)?  image,TResult? Function( SlideBreakBlock value)?  slideBreak,TResult? Function( UnknownBlock value)?  unknown,}){
final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that);case ParagraphBlock() when paragraph != null:
return paragraph(_that);case CalloutBlock() when callout != null:
return callout(_that);case StepsBlock() when steps != null:
return steps(_that);case PassageBlock() when passage != null:
return passage(_that);case QuizBlock() when quiz != null:
return quiz(_that);case VocabBlock() when vocab != null:
return vocab(_that);case PatternBlock() when pattern != null:
return pattern(_that);case ImageBlock() when image != null:
return image(_that);case SlideBreakBlock() when slideBreak != null:
return slideBreak(_that);case UnknownBlock() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? id,  String text)?  heading,TResult Function( String? id,  String text)?  paragraph,TResult Function( String? id,  String text)?  callout,TResult Function( String? id,  List<String> items)?  steps,TResult Function( String? id,  String label,  String text)?  passage,TResult Function( String? id,  String question,  List<String> options,  int correctIndex,  String explanation)?  quiz,TResult Function( String? id,  List<VocabItem> items)?  vocab,TResult Function( String? id,  String text)?  pattern,TResult Function( String? id,  String url,  String alt)?  image,TResult Function( String? id)?  slideBreak,TResult Function( String? id,  String type,  Map<String, dynamic> raw)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that.id,_that.text);case ParagraphBlock() when paragraph != null:
return paragraph(_that.id,_that.text);case CalloutBlock() when callout != null:
return callout(_that.id,_that.text);case StepsBlock() when steps != null:
return steps(_that.id,_that.items);case PassageBlock() when passage != null:
return passage(_that.id,_that.label,_that.text);case QuizBlock() when quiz != null:
return quiz(_that.id,_that.question,_that.options,_that.correctIndex,_that.explanation);case VocabBlock() when vocab != null:
return vocab(_that.id,_that.items);case PatternBlock() when pattern != null:
return pattern(_that.id,_that.text);case ImageBlock() when image != null:
return image(_that.id,_that.url,_that.alt);case SlideBreakBlock() when slideBreak != null:
return slideBreak(_that.id);case UnknownBlock() when unknown != null:
return unknown(_that.id,_that.type,_that.raw);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? id,  String text)  heading,required TResult Function( String? id,  String text)  paragraph,required TResult Function( String? id,  String text)  callout,required TResult Function( String? id,  List<String> items)  steps,required TResult Function( String? id,  String label,  String text)  passage,required TResult Function( String? id,  String question,  List<String> options,  int correctIndex,  String explanation)  quiz,required TResult Function( String? id,  List<VocabItem> items)  vocab,required TResult Function( String? id,  String text)  pattern,required TResult Function( String? id,  String url,  String alt)  image,required TResult Function( String? id)  slideBreak,required TResult Function( String? id,  String type,  Map<String, dynamic> raw)  unknown,}) {final _that = this;
switch (_that) {
case HeadingBlock():
return heading(_that.id,_that.text);case ParagraphBlock():
return paragraph(_that.id,_that.text);case CalloutBlock():
return callout(_that.id,_that.text);case StepsBlock():
return steps(_that.id,_that.items);case PassageBlock():
return passage(_that.id,_that.label,_that.text);case QuizBlock():
return quiz(_that.id,_that.question,_that.options,_that.correctIndex,_that.explanation);case VocabBlock():
return vocab(_that.id,_that.items);case PatternBlock():
return pattern(_that.id,_that.text);case ImageBlock():
return image(_that.id,_that.url,_that.alt);case SlideBreakBlock():
return slideBreak(_that.id);case UnknownBlock():
return unknown(_that.id,_that.type,_that.raw);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? id,  String text)?  heading,TResult? Function( String? id,  String text)?  paragraph,TResult? Function( String? id,  String text)?  callout,TResult? Function( String? id,  List<String> items)?  steps,TResult? Function( String? id,  String label,  String text)?  passage,TResult? Function( String? id,  String question,  List<String> options,  int correctIndex,  String explanation)?  quiz,TResult? Function( String? id,  List<VocabItem> items)?  vocab,TResult? Function( String? id,  String text)?  pattern,TResult? Function( String? id,  String url,  String alt)?  image,TResult? Function( String? id)?  slideBreak,TResult? Function( String? id,  String type,  Map<String, dynamic> raw)?  unknown,}) {final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that.id,_that.text);case ParagraphBlock() when paragraph != null:
return paragraph(_that.id,_that.text);case CalloutBlock() when callout != null:
return callout(_that.id,_that.text);case StepsBlock() when steps != null:
return steps(_that.id,_that.items);case PassageBlock() when passage != null:
return passage(_that.id,_that.label,_that.text);case QuizBlock() when quiz != null:
return quiz(_that.id,_that.question,_that.options,_that.correctIndex,_that.explanation);case VocabBlock() when vocab != null:
return vocab(_that.id,_that.items);case PatternBlock() when pattern != null:
return pattern(_that.id,_that.text);case ImageBlock() when image != null:
return image(_that.id,_that.url,_that.alt);case SlideBreakBlock() when slideBreak != null:
return slideBreak(_that.id);case UnknownBlock() when unknown != null:
return unknown(_that.id,_that.type,_that.raw);case _:
  return null;

}
}

}

/// @nodoc


class HeadingBlock extends DocBlock {
  const HeadingBlock({this.id = null, required this.text}): super._();
  

@override@JsonKey() final  String? id;
 final  String text;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeadingBlockCopyWith<HeadingBlock> get copyWith => _$HeadingBlockCopyWithImpl<HeadingBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeadingBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'DocBlock.heading(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $HeadingBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $HeadingBlockCopyWith(HeadingBlock value, $Res Function(HeadingBlock) _then) = _$HeadingBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String text
});




}
/// @nodoc
class _$HeadingBlockCopyWithImpl<$Res>
    implements $HeadingBlockCopyWith<$Res> {
  _$HeadingBlockCopyWithImpl(this._self, this._then);

  final HeadingBlock _self;
  final $Res Function(HeadingBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? text = null,}) {
  return _then(HeadingBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ParagraphBlock extends DocBlock {
  const ParagraphBlock({this.id = null, required this.text}): super._();
  

@override@JsonKey() final  String? id;
 final  String text;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParagraphBlockCopyWith<ParagraphBlock> get copyWith => _$ParagraphBlockCopyWithImpl<ParagraphBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParagraphBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'DocBlock.paragraph(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $ParagraphBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $ParagraphBlockCopyWith(ParagraphBlock value, $Res Function(ParagraphBlock) _then) = _$ParagraphBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String text
});




}
/// @nodoc
class _$ParagraphBlockCopyWithImpl<$Res>
    implements $ParagraphBlockCopyWith<$Res> {
  _$ParagraphBlockCopyWithImpl(this._self, this._then);

  final ParagraphBlock _self;
  final $Res Function(ParagraphBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? text = null,}) {
  return _then(ParagraphBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CalloutBlock extends DocBlock {
  const CalloutBlock({this.id = null, required this.text}): super._();
  

@override@JsonKey() final  String? id;
 final  String text;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalloutBlockCopyWith<CalloutBlock> get copyWith => _$CalloutBlockCopyWithImpl<CalloutBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalloutBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'DocBlock.callout(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $CalloutBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $CalloutBlockCopyWith(CalloutBlock value, $Res Function(CalloutBlock) _then) = _$CalloutBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String text
});




}
/// @nodoc
class _$CalloutBlockCopyWithImpl<$Res>
    implements $CalloutBlockCopyWith<$Res> {
  _$CalloutBlockCopyWithImpl(this._self, this._then);

  final CalloutBlock _self;
  final $Res Function(CalloutBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? text = null,}) {
  return _then(CalloutBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StepsBlock extends DocBlock {
  const StepsBlock({this.id = null, final  List<String> items = const []}): _items = items,super._();
  

@override@JsonKey() final  String? id;
 final  List<String> _items;
@JsonKey() List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepsBlockCopyWith<StepsBlock> get copyWith => _$StepsBlockCopyWithImpl<StepsBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepsBlock&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'DocBlock.steps(id: $id, items: $items)';
}


}

/// @nodoc
abstract mixin class $StepsBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $StepsBlockCopyWith(StepsBlock value, $Res Function(StepsBlock) _then) = _$StepsBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, List<String> items
});




}
/// @nodoc
class _$StepsBlockCopyWithImpl<$Res>
    implements $StepsBlockCopyWith<$Res> {
  _$StepsBlockCopyWithImpl(this._self, this._then);

  final StepsBlock _self;
  final $Res Function(StepsBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? items = null,}) {
  return _then(StepsBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class PassageBlock extends DocBlock {
  const PassageBlock({this.id = null, this.label = '', required this.text}): super._();
  

@override@JsonKey() final  String? id;
@JsonKey() final  String label;
 final  String text;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PassageBlockCopyWith<PassageBlock> get copyWith => _$PassageBlockCopyWithImpl<PassageBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PassageBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,text);

@override
String toString() {
  return 'DocBlock.passage(id: $id, label: $label, text: $text)';
}


}

/// @nodoc
abstract mixin class $PassageBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $PassageBlockCopyWith(PassageBlock value, $Res Function(PassageBlock) _then) = _$PassageBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String label, String text
});




}
/// @nodoc
class _$PassageBlockCopyWithImpl<$Res>
    implements $PassageBlockCopyWith<$Res> {
  _$PassageBlockCopyWithImpl(this._self, this._then);

  final PassageBlock _self;
  final $Res Function(PassageBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? label = null,Object? text = null,}) {
  return _then(PassageBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class QuizBlock extends DocBlock {
  const QuizBlock({this.id = null, required this.question, final  List<String> options = const [], this.correctIndex = 0, this.explanation = ''}): _options = options,super._();
  

@override@JsonKey() final  String? id;
 final  String question;
 final  List<String> _options;
@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@JsonKey() final  int correctIndex;
@JsonKey() final  String explanation;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizBlockCopyWith<QuizBlock> get copyWith => _$QuizBlockCopyWithImpl<QuizBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.correctIndex, correctIndex) || other.correctIndex == correctIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}


@override
int get hashCode => Object.hash(runtimeType,id,question,const DeepCollectionEquality().hash(_options),correctIndex,explanation);

@override
String toString() {
  return 'DocBlock.quiz(id: $id, question: $question, options: $options, correctIndex: $correctIndex, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $QuizBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $QuizBlockCopyWith(QuizBlock value, $Res Function(QuizBlock) _then) = _$QuizBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String question, List<String> options, int correctIndex, String explanation
});




}
/// @nodoc
class _$QuizBlockCopyWithImpl<$Res>
    implements $QuizBlockCopyWith<$Res> {
  _$QuizBlockCopyWithImpl(this._self, this._then);

  final QuizBlock _self;
  final $Res Function(QuizBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? question = null,Object? options = null,Object? correctIndex = null,Object? explanation = null,}) {
  return _then(QuizBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,correctIndex: null == correctIndex ? _self.correctIndex : correctIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class VocabBlock extends DocBlock {
  const VocabBlock({this.id = null, final  List<VocabItem> items = const []}): _items = items,super._();
  

@override@JsonKey() final  String? id;
 final  List<VocabItem> _items;
@JsonKey() List<VocabItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VocabBlockCopyWith<VocabBlock> get copyWith => _$VocabBlockCopyWithImpl<VocabBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VocabBlock&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'DocBlock.vocab(id: $id, items: $items)';
}


}

/// @nodoc
abstract mixin class $VocabBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $VocabBlockCopyWith(VocabBlock value, $Res Function(VocabBlock) _then) = _$VocabBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, List<VocabItem> items
});




}
/// @nodoc
class _$VocabBlockCopyWithImpl<$Res>
    implements $VocabBlockCopyWith<$Res> {
  _$VocabBlockCopyWithImpl(this._self, this._then);

  final VocabBlock _self;
  final $Res Function(VocabBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? items = null,}) {
  return _then(VocabBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<VocabItem>,
  ));
}


}

/// @nodoc


class PatternBlock extends DocBlock {
  const PatternBlock({this.id = null, required this.text}): super._();
  

@override@JsonKey() final  String? id;
 final  String text;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatternBlockCopyWith<PatternBlock> get copyWith => _$PatternBlockCopyWithImpl<PatternBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatternBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'DocBlock.pattern(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $PatternBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $PatternBlockCopyWith(PatternBlock value, $Res Function(PatternBlock) _then) = _$PatternBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String text
});




}
/// @nodoc
class _$PatternBlockCopyWithImpl<$Res>
    implements $PatternBlockCopyWith<$Res> {
  _$PatternBlockCopyWithImpl(this._self, this._then);

  final PatternBlock _self;
  final $Res Function(PatternBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? text = null,}) {
  return _then(PatternBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ImageBlock extends DocBlock {
  const ImageBlock({this.id = null, required this.url, this.alt = ''}): super._();
  

@override@JsonKey() final  String? id;
 final  String url;
@JsonKey() final  String alt;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageBlockCopyWith<ImageBlock> get copyWith => _$ImageBlockCopyWithImpl<ImageBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.alt, alt) || other.alt == alt));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,alt);

@override
String toString() {
  return 'DocBlock.image(id: $id, url: $url, alt: $alt)';
}


}

/// @nodoc
abstract mixin class $ImageBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $ImageBlockCopyWith(ImageBlock value, $Res Function(ImageBlock) _then) = _$ImageBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String url, String alt
});




}
/// @nodoc
class _$ImageBlockCopyWithImpl<$Res>
    implements $ImageBlockCopyWith<$Res> {
  _$ImageBlockCopyWithImpl(this._self, this._then);

  final ImageBlock _self;
  final $Res Function(ImageBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? url = null,Object? alt = null,}) {
  return _then(ImageBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,alt: null == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SlideBreakBlock extends DocBlock {
  const SlideBreakBlock({this.id = null}): super._();
  

@override@JsonKey() final  String? id;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlideBreakBlockCopyWith<SlideBreakBlock> get copyWith => _$SlideBreakBlockCopyWithImpl<SlideBreakBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlideBreakBlock&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'DocBlock.slideBreak(id: $id)';
}


}

/// @nodoc
abstract mixin class $SlideBreakBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $SlideBreakBlockCopyWith(SlideBreakBlock value, $Res Function(SlideBreakBlock) _then) = _$SlideBreakBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id
});




}
/// @nodoc
class _$SlideBreakBlockCopyWithImpl<$Res>
    implements $SlideBreakBlockCopyWith<$Res> {
  _$SlideBreakBlockCopyWithImpl(this._self, this._then);

  final SlideBreakBlock _self;
  final $Res Function(SlideBreakBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,}) {
  return _then(SlideBreakBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnknownBlock extends DocBlock {
  const UnknownBlock({this.id = null, required this.type, required final  Map<String, dynamic> raw}): _raw = raw,super._();
  

@override@JsonKey() final  String? id;
 final  String type;
 final  Map<String, dynamic> _raw;
 Map<String, dynamic> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownBlockCopyWith<UnknownBlock> get copyWith => _$UnknownBlockCopyWithImpl<UnknownBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._raw, _raw));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(_raw));

@override
String toString() {
  return 'DocBlock.unknown(id: $id, type: $type, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $UnknownBlockCopyWith<$Res> implements $DocBlockCopyWith<$Res> {
  factory $UnknownBlockCopyWith(UnknownBlock value, $Res Function(UnknownBlock) _then) = _$UnknownBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String type, Map<String, dynamic> raw
});




}
/// @nodoc
class _$UnknownBlockCopyWithImpl<$Res>
    implements $UnknownBlockCopyWith<$Res> {
  _$UnknownBlockCopyWithImpl(this._self, this._then);

  final UnknownBlock _self;
  final $Res Function(UnknownBlock) _then;

/// Create a copy of DocBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? type = null,Object? raw = null,}) {
  return _then(UnknownBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
