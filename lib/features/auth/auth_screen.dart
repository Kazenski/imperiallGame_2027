import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_providers.dart';

/// Tela de entrada (login/cadastro) por e-mail e senha.
///
/// Só aparece quando há credenciais Supabase e o modo demonstração está
/// desligado (ver `isAuthenticatedProvider`).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authControllerProvider);
    if (auth == null) {
      setState(() => _error = 'Backend não configurado.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (_isSignUp) {
      final result = await auth.signUp(
        email: email,
        password: password,
        displayName: _nameController.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);

      switch (result.status) {
        case SignUpStatus.signedIn:
          // O redirect do roteador cuida da navegação.
          break;
        case SignUpStatus.awaitingEmailConfirmation:
          _showInfo(
            'Conta criada! Enviamos um link de confirmação para $email. '
            'Confirme o e-mail e depois entre.',
          );
        case SignUpStatus.failed:
          setState(() => _error = result.message);
      }
      return;
    }

    final error = await auth.signIn(email: email, password: password);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Brand(),
                      const SizedBox(height: AppSpacing.xxl),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        child: _isSignUp
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome de herói',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (!_isSignUp) return null;
                                    if ((value ?? '').trim().length < 2) {
                                      return 'Escolha um nome com 2+ letras.';
                                    }
                                    return null;
                                  },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return 'Informe seu e-mail.';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'E-mail inválido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'A senha precisa ter 6+ caracteres.';
                          }
                          return null;
                        },
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _ErrorBanner(message: _error!),
                      ],

                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Color(0xFF2A1A00),
                                ),
                              )
                            : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: _busy ? null : _toggleMode,
                        child: Text(
                          _isSignUp
                              ? 'Já tem conta? Entrar'
                              : 'Ainda não tem conta? Criar',
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Seus dados ficam protegidos por Row Level Security: '
                        'só você acessa o seu progresso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 84,
          width: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.goldGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_martial_arts,
            size: 42,
            color: Color(0xFF2A1A00),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConfig.appName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Treine na vida real. Evolua seu herói.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
