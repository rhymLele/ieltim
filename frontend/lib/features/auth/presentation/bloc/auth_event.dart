import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginWithAccessKey extends AuthEvent {
  final String key;

  LoginWithAccessKey({required this.key});

  @override
  List<Object?> get props => [key];
}

class Logout extends AuthEvent {}
