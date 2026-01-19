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


/** This is an auto generated class representing the SalonService type in your schema. */
class SalonService extends amplify_core.Model {
  static const classType = const _SalonServiceModelType();
  final String id;
  final String? _category;
  final String? _service_name;
  final int? _cost;
  final String? _description;
  final int? _duration;
  final String? _gender;
  final String? _imageUrl;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  SalonServiceModelIdentifier get modelIdentifier {
      return SalonServiceModelIdentifier(
        id: id
      );
  }
  
  String get category {
    try {
      return _category!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get service_name {
    try {
      return _service_name!;
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
  
  String? get description {
    return _description;
  }
  
  int? get duration {
    return _duration;
  }
  
  String get gender {
    try {
      return _gender!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get imageUrl {
    return _imageUrl;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const SalonService._internal({required this.id, required category, required service_name, cost, description, duration, required gender, imageUrl, createdAt, updatedAt}): _category = category, _service_name = service_name, _cost = cost, _description = description, _duration = duration, _gender = gender, _imageUrl = imageUrl, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory SalonService({String? id, required String category, required String service_name, int? cost, String? description, int? duration, required String gender, String? imageUrl}) {
    return SalonService._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      category: category,
      service_name: service_name,
      cost: cost,
      description: description,
      duration: duration,
      gender: gender,
      imageUrl: imageUrl);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SalonService &&
      id == other.id &&
      _category == other._category &&
      _service_name == other._service_name &&
      _cost == other._cost &&
      _description == other._description &&
      _duration == other._duration &&
      _gender == other._gender &&
      _imageUrl == other._imageUrl;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("SalonService {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("category=" + "$_category" + ", ");
    buffer.write("service_name=" + "$_service_name" + ", ");
    buffer.write("cost=" + (_cost != null ? _cost.toString() : "null") + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("duration=" + (_duration != null ? _duration.toString() : "null") + ", ");
    buffer.write("gender=" + "$_gender" + ", ");
    buffer.write("imageUrl=" + "$_imageUrl" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  SalonService copyWith({String? category, String? service_name, int? cost, String? description, int? duration, String? gender, String? imageUrl}) {
    return SalonService._internal(
      id: id,
      category: category ?? this.category,
      service_name: service_name ?? this.service_name,
      cost: cost ?? this.cost,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      gender: gender ?? this.gender,
      imageUrl: imageUrl ?? this.imageUrl);
  }
  
  SalonService copyWithModelFieldValues({
    ModelFieldValue<String>? category,
    ModelFieldValue<String>? service_name,
    ModelFieldValue<int?>? cost,
    ModelFieldValue<String?>? description,
    ModelFieldValue<int?>? duration,
    ModelFieldValue<String>? gender,
    ModelFieldValue<String?>? imageUrl
  }) {
    return SalonService._internal(
      id: id,
      category: category == null ? this.category : category.value,
      service_name: service_name == null ? this.service_name : service_name.value,
      cost: cost == null ? this.cost : cost.value,
      description: description == null ? this.description : description.value,
      duration: duration == null ? this.duration : duration.value,
      gender: gender == null ? this.gender : gender.value,
      imageUrl: imageUrl == null ? this.imageUrl : imageUrl.value
    );
  }
  
  SalonService.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _category = json['category'],
      _service_name = json['service_name'],
      _cost = (json['cost'] as num?)?.toInt(),
      _description = json['description'],
      _duration = (json['duration'] as num?)?.toInt(),
      _gender = json['gender'],
      _imageUrl = json['imageUrl'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'category': _category, 'service_name': _service_name, 'cost': _cost, 'description': _description, 'duration': _duration, 'gender': _gender, 'imageUrl': _imageUrl, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'category': _category,
    'service_name': _service_name,
    'cost': _cost,
    'description': _description,
    'duration': _duration,
    'gender': _gender,
    'imageUrl': _imageUrl,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<SalonServiceModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<SalonServiceModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final CATEGORY = amplify_core.QueryField(fieldName: "category");
  static final SERVICE_NAME = amplify_core.QueryField(fieldName: "service_name");
  static final COST = amplify_core.QueryField(fieldName: "cost");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final DURATION = amplify_core.QueryField(fieldName: "duration");
  static final GENDER = amplify_core.QueryField(fieldName: "gender");
  static final IMAGEURL = amplify_core.QueryField(fieldName: "imageUrl");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "SalonService";
    modelSchemaDefinition.pluralName = "SalonServices";
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.CATEGORY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.SERVICE_NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.COST,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.DESCRIPTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.DURATION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.GENDER,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: SalonService.IMAGEURL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _SalonServiceModelType extends amplify_core.ModelType<SalonService> {
  const _SalonServiceModelType();
  
  @override
  SalonService fromJson(Map<String, dynamic> jsonData) {
    return SalonService.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'SalonService';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [SalonService] in your schema.
 */
class SalonServiceModelIdentifier implements amplify_core.ModelIdentifier<SalonService> {
  final String id;

  /** Create an instance of SalonServiceModelIdentifier using [id] the primary key. */
  const SalonServiceModelIdentifier({
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
  String toString() => 'SalonServiceModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is SalonServiceModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}