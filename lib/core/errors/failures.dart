sealed class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('Connection timed out', code: 'TIMEOUT');
}

final class NoInternetFailure extends Failure {
  const NoInternetFailure()
      : super('No internet connection', code: 'NO_INTERNET');
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

final class BiometricFailure extends Failure {
  const BiometricFailure(super.message, {super.code});
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

final class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message, {super.code});
}

final class VulnValidationFailure extends Failure {
  const VulnValidationFailure(super.message, {super.code});
}

final class C2ConnectionFailure extends Failure {
  const C2ConnectionFailure(super.message, {super.code});
}

final class VoicePermissionFailure extends Failure {
  const VoicePermissionFailure()
      : super('Microphone permission denied', code: 'MIC_DENIED');
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error occurred'])
      : super(code: 'UNEXPECTED');
}