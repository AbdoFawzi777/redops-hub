import 'package:hive/hive.dart';
import '../../domain/entities/vulnerability.dart';

class VulnModel extends HiveObject {
  VulnModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severityIndex,
    required this.statusIndex,
    required this.typeIndex,
    required this.projectName,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.cveId,
    this.assignedTo,
    this.reproductionSteps,
    this.remediationCode,
    this.pocCode,
    this.tags = const [],
    this.commentsJson = const [],
  });

  final String id;
  final String title;
  final String description;
  final int severityIndex;
  final int statusIndex;
  final int typeIndex;
  final String projectName;
  final String? cveId;
  final String? assignedTo;
  final String? reproductionSteps;
  final String? remediationCode;
  final String? pocCode;
  final List<String> tags;
  final List<Map<String, dynamic>> commentsJson;
  final int createdAtMs;
  final int updatedAtMs;

  Vulnerability toEntity() {
    return Vulnerability(
      id: id,
      title: title,
      description: description,
      severity: VulnSeverity.values[severityIndex],
      status: VulnStatus.values[statusIndex],
      type: VulnType.values[typeIndex],
      projectName: projectName,
      cveId: cveId,
      assignedTo: assignedTo,
      reproductionSteps: reproductionSteps,
      remediationCode: remediationCode,
      pocCode: pocCode,
      tags: List<String>.from(tags),
      comments: commentsJson.map(_commentFromJson).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }

  static VulnModel fromEntity(Vulnerability entity) {
    return VulnModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      severityIndex: entity.severity.index,
      statusIndex: entity.status.index,
      typeIndex: entity.type.index,
      projectName: entity.projectName,
      cveId: entity.cveId,
      assignedTo: entity.assignedTo,
      reproductionSteps: entity.reproductionSteps,
      remediationCode: entity.remediationCode,
      pocCode: entity.pocCode,
      tags: entity.tags,
      commentsJson: entity.comments.map(_commentToJson).toList(),
      createdAtMs: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMs: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  static VulnComment _commentFromJson(Map<String, dynamic> json) {
    return VulnComment(
      id: json['id'] as String,
      author: json['author'] as String,
      role: json['role'] as String? ?? 'Red Team',
      text: json['text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAtMs'] as int),
    );
  }

  static Map<String, dynamic> _commentToJson(VulnComment comment) {
    return {
      'id': comment.id,
      'author': comment.author,
      'role': comment.role,
      'text': comment.text,
      'createdAtMs': comment.createdAt.millisecondsSinceEpoch,
    };
  }
}

class VulnModelAdapter extends TypeAdapter<VulnModel> {
  @override
  final int typeId = 0;

  @override
  VulnModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VulnModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      severityIndex: fields[3] as int,
      statusIndex: fields[4] as int,
      typeIndex: fields[5] as int,
      projectName: fields[6] as String,
      cveId: fields[7] as String?,
      assignedTo: fields[8] as String?,
      reproductionSteps: fields[9] as String?,
      remediationCode: fields[10] as String?,
      pocCode: fields[11] as String?,
      tags: (fields[12] as List?)?.cast<String>() ?? const [],
      commentsJson: (fields[13] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      createdAtMs: fields[14] as int,
      updatedAtMs: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VulnModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.severityIndex)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.typeIndex)
      ..writeByte(6)
      ..write(obj.projectName)
      ..writeByte(7)
      ..write(obj.cveId)
      ..writeByte(8)
      ..write(obj.assignedTo)
      ..writeByte(9)
      ..write(obj.reproductionSteps)
      ..writeByte(10)
      ..write(obj.remediationCode)
      ..writeByte(11)
      ..write(obj.pocCode)
      ..writeByte(12)
      ..write(obj.tags)
      ..writeByte(13)
      ..write(obj.commentsJson)
      ..writeByte(14)
      ..write(obj.createdAtMs)
      ..writeByte(15)
      ..write(obj.updatedAtMs);
  }
}
