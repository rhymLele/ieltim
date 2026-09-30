import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/dragon_loader.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_state.dart';

import '../../../../core/widgets/ink_input.dart';
import '../../../../core/widgets/koi_pond.dart';

class AccessKeyPage extends StatefulWidget {
  const AccessKeyPage({super.key});

  @override
  State<AccessKeyPage> createState() => _AccessKeyPageState();
}

class _AccessKeyPageState extends State<AccessKeyPage> {
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<AuthBloc>();
    if (bloc.state is AuthLoading || bloc.state is AuthSuccess) return;
    FocusScope.of(context).unfocus();
    bloc.add(LoginWithAccessKey(key: _keyController.text.trim()));
  }

  void _finishLoading() {
    if (mounted && context.read<AuthBloc>().state is AuthSuccess) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading || state is AuthSuccess;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: loading
              ? SafeArea(
                  child: DragonLoader(
                    // Authentication has no granular progress. Loop until the
                    // token is stored, then finish the transformation once.
                    progress: state is AuthSuccess ? 1 : null,
                    onFinished: _finishLoading,
                  ),
                )
              : Stack(
                  children: [
                    const Positioned.fill(child: KoiPond()),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/app_icon.png',
                                width: 72,
                                height: 72,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'IELTS Hub',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                              InkLineField(
                                controller: _keyController,
                                hint: "Em là ai ?",
                                onSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Continue'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
