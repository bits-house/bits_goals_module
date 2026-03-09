import 'package:equatable/equatable.dart';

class AppVersion extends Equatable {
  final String value;

  const AppVersion(this.value);

  // =================================================================
  // Equatable Overrides
  // =================================================================

  @override
  List<Object?> get props => [value];

  @override
  bool? get stringify => true;
}
