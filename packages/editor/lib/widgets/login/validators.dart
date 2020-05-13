import 'package:flutter/material.dart';
import 'package:rive_api/auth.dart';

class FormValidator {
  final List<FieldValidator> validators;
  const FormValidator(this.validators);

  void validate(AuthResponse response) {
    for (final val in validators) {
      val.validate(response);
    }
  }
}


abstract class FieldValidator {
  final ValueChanged<String> onFieldError;
  const FieldValidator({@required this.onFieldError});

  String get errorField;
  void validate(AuthResponse response);
}

class NameValidator extends FieldValidator {
  const NameValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'username';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      switch (error) {
        case 'in-use':
          return onFieldError('Not available');
        case 'too-short':
          return onFieldError('Too short.');
        case 'bad-characters':
          return onFieldError('Only alphanumeric and . or - are allowed.');
        default:
          return onFieldError('Unknown error, please try again later.');
      }
    }

    // Valid.
    return onFieldError(null);
  }
}

class PasswordValidator extends FieldValidator {
  const PasswordValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'password';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      switch (error) {
        case 'invalid':
          return onFieldError('Must be at least 3 characters long.');
        case 'too-short':
          return onFieldError('Too short.');
        default:
          return onFieldError('Unknown error, please try again later.');
      }
    }

    // Valid.
    return onFieldError(null);
  }
}

class EmailValidator extends FieldValidator {
  const EmailValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'email';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      switch (error) {
        case 'invalid':
          return onFieldError('Not a valid email');
        case 'in-use':
          return onFieldError('Aready registered');
        case 'missing':
          return onFieldError('Please fill this in!');
        default:
          return onFieldError('Unknown error, please try again later.');
      }
    }

    // Valid.
    return onFieldError(null);
  }
}

class ErrorValidator extends FieldValidator {
  const ErrorValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'error';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      return onFieldError(error);
    }

    // Valid.
    return onFieldError(null);
  }
}
