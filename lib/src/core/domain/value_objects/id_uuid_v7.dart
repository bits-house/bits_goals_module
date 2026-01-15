import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure.dart';
import 'package:bits_goals_module/src/core/domain/failures/id_uuid_v7/id_uuid_v7_failure_reason.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class IdUuidV7 extends Equatable {
  final String _value;

  const IdUuidV7(this._value);

  factory IdUuidV7.generate() {
    return IdUuidV7(const Uuid().v7());
  }

  factory IdUuidV7.fromString(String value) {
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (!regex.hasMatch(value)) {
      throw const IdUuidV7Failure(IdUuidV7FailureReason.invalidIdFormat);
    }
    return IdUuidV7(value);
  }

  String get value => _value;

  @override
  List<Object?> get props => [_value];
}
