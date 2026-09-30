import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_state.dart';

class AccessKeyPage extends StatelessWidget {
  const AccessKeyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'IELTS Knowledge Hub',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your access key to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (state is AuthFailure)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _AccessKeyInput(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () => _submit(context),
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final key = _keyController.text.trim();
    context.read<AuthBloc>().add(LoginWithAccessKey(key: key));
  }
}

final _keyController = TextEditingController();

class _AccessKeyInput extends StatefulWidget {
  @override
  State<_AccessKeyInput> createState() => _AccessKeyInputState();
}

class _AccessKeyInputState extends State<_AccessKeyInput> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, next) => next is AuthSuccess,
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.go('/home');
        }
      },
      child: TextFormField(
        controller: _keyController,
        decoration: const InputDecoration(
          hintText: 'Enter your access key',
          prefixIcon: Icon(Icons.key),
          border: OutlineInputBorder(),
        ),
        onFieldSubmitted: (_) {
          final key = _keyController.text.trim();
          context.read<AuthBloc>().add(LoginWithAccessKey(key: key));
        },
      ),
    );
  }
}
