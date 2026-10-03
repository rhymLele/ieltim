import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routes/redirect_path.dart';
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

  /// The dragon animation has played through. Login may still be waiting on
  /// a slow (cold-starting) server, so navigation needs both to be done.
  bool _dragonDone = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<AuthBloc>();
    if (bloc.state is AuthLoading || bloc.state is AuthSuccess) return;
    FocusScope.of(context).unfocus();
    _dragonDone = false;
    bloc.add(LoginWithAccessKey(key: _keyController.text.trim()));
  }

  void _finishLoading() {
    _dragonDone = true;
    _goHomeIfReady();
  }

  void _goHomeIfReady() {
    if (mounted &&
        _dragonDone &&
        context.read<AuthBloc>().state is AuthSuccess) {
      // Mở từ link cụ thể (vd. /weekly/doc/w12-doc1) thì quay lại trang đó.
      context.go(safeRedirectPath(GoRouterState.of(context).uri.queryParameters['from']) ?? '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Login finishing after the dragon is done must still navigate.
      listenWhen: (_, state) => state is AuthSuccess,
      listener: (_, _) => _goHomeIfReady(),
      builder: (context, state) {
        final loading = state is AuthLoading || state is AuthSuccess;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: loading
              ? SafeArea(
                  child: DragonLoader(
                    playOnce: true,
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
