import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class IdUuidV7 extends Equatable {
  final String _value;

  const IdUuidV7(this._value);

  factory IdUuidV7.generate() {
    return IdUuidV7(const Uuid().v7());
  }

  factory IdUuidV7.fromString(String value) {
    return IdUuidV7(value);
  }

  String get value => _value;

  @override
  List<Object?> get props => [_value];
}
