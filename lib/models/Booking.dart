/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the Booking type in your schema. */
class Booking extends amplify_core.Model {
  static const classType = const _BookingModelType();
  final String id;
  final String? _serviceName;
  final int? _cost;
  final amplify_core.TemporalDate? _date;
  final amplify_core.TemporalTime? _time;
  final amplify_core.TemporalDateTime? _createdAt;
  final String? _owner;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  BookingModelIdentifier get modelIdentifier {
      return BookingModelIdentifier(
        id: id
      );
  }
  
  String get serviceName {
    try {
      return _serviceName!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get cost {
    return _cost;
  }
  
  amplify_core.TemporalDate get date {
    try {
      return _date!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTime get time {
    try {
      return _time!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  String? get owner {
    return _owner;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Booking._internal({required this.id, required serviceName, cost, required date, required time, createdAt, owner, updatedAt}): _serviceName = serviceName, _cost = cost, _date = date, _time = time, _createdAt = createdAt, _owner = owner, _updatedAt = updatedAt;
  
  factory Booking({String? id, required String serviceName, int? cost, required amplify_core.TemporalDate date, required amplify_core.TemporalTime time, amplify_core.TemporalDateTime? createdAt, String? owner}) {
    return Booking._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      serviceName: serviceName,
      cost: cost,
      date: date,
      time: time,
      createdAt: createdAt,
      owner: owner);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Booking &&
      id == other.id &&
      _serviceName == other._serviceName &&
      _cost == other._cost &&
      _date == other._date &&
      _time == other._time &&
      _createdAt == other._createdAt &&
      _owner == other._owner;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Booking {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("serviceName=" + "$_serviceName" + ", ");
    buffer.write("cost=" + (_cost != null ? _cost.toString() : "null") + ", ");
    buffer.write("date=" + (_date != null ? _date.format() : "null") + ", ");
    buffer.write("time=" + (_time != null ? _time.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ");
    buffer.write("owner=" + "$_owner" + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Booking copyWith({String? serviceName, int? cost, amplify_core.TemporalDate? date, amplify_core.TemporalTime? time, amplify_core.TemporalDateTime? createdAt, String? owner}) {
    return Booking._internal(
      id: id,
      serviceName: serviceName ?? this.serviceName,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      owner: owner ?? this.owner);
  }
  
  Booking copyWithModelFieldValues({
    ModelFieldValue<String>? serviceName,
    ModelFieldValue<int?>? cost,
    ModelFieldValue<amplify_core.TemporalDate>? date,
    ModelFieldValue<amplify_core.TemporalTime>? time,
    ModelFieldValue<amplify_core.TemporalDateTime?>? createdAt,
    ModelFieldValue<String?>? owner
  }) {
    return Booking._internal(
      id: id,
      serviceName: serviceName == null ? this.serviceName : serviceName.value,
      cost: cost == null ? this.cost : cost.value,
      date: date == null ? this.date : date.value,
      time: time == null ? this.time : time.value,
      createdAt: createdAt == null ? this.createdAt : createdAt.value,
      owner: owner == null ? this.owner : owner.value
    );
  }
  
  Booking.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _serviceName = json['serviceName'],
      _cost = (json['cost'] as num?)?.toInt(),
      _date = json['date'] != null ? amplify_core.TemporalDate.fromString(json['date']) : null,
      _time = json['time'] != null ? amplify_core.TemporalTime.fromString(json['time']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _owner = json['owner'],
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'serviceName': _serviceName, 'cost': _cost, 'date': _date?.format(), 'time': _time?.format(), 'createdAt': _createdAt?.format(), 'owner': _owner, 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'serviceName': _serviceName,
    'cost': _cost,
    'date': _date,
    'time': _time,
    'createdAt': _createdAt,
    'owner': _owner,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<BookingModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<BookingModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final SERVICENAME = amplify_core.QueryField(fieldName: "serviceName");
  static final COST = amplify_core.QueryField(fieldName: "cost");
  static final DATE = amplify_core.QueryField(fieldName: "date");
  static final TIME = amplify_core.QueryField(fieldName: "time");
  static final CREATEDAT = amplify_core.QueryField(fieldName: "createdAt");
  static final OWNER = amplify_core.QueryField(fieldName: "owner");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Booking";
    modelSchemaDefinition.pluralName = "Bookings";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Booking.SERVICENAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Booking.COST,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Booking.DATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.date)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Booking.TIME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.time)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Booking.CREATEDAT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Booking.OWNER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _BookingModelType extends amplify_core.ModelType<Booking> {
  const _BookingModelType();
  
  @override
  Booking fromJson(Map<String, dynamic> jsonData) {
    return Booking.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Booking';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Booking] in your schema.
 */
class BookingModelIdentifier implements amplify_core.ModelIdentifier<Booking> {
  final String id;

  /** Create an instance of BookingModelIdentifier using [id] the primary key. */
  const BookingModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'BookingModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is BookingModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}