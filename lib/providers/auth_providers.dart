import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

/// Há autenticação configurada? (credenciais presentes e modo demo desligado)
final authEnabledProvider = Provider<bool>(
  (ref) => !AppConfig.useDemoData && AppConfig.hasSupabaseCredentials,
);

/// Cliente Supabase — `null` quando o app roda sem backend (modo demo).
final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => AppConfig.hasSupabaseCredentials ? Supabase.instance.client : null,
);

/// Fluxo de eventos de sessão do Supabase. Mantém os providers reativos a
/// login, logout e refresh de token.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream<Session?>.empty();
  return client.auth.onAuthStateChange.map((event) => event.session);
});

/// Usuário tem sessão ativa?
///
/// Em modo demonstração sempre é `true` — não existe tela de login.
final isAuthenticatedProvider = Provider<bool>((ref) {
  if (!AppConfig.hasSupabaseCredentials) return true;
  if (AppConfig.useDemoData) return true;

  final client = ref.watch(supabaseClientProvider);
  if (client == null) return true;

  // Recalcula a cada evento de auth; o `bool` só muda de fato no login/logout.
  ref.watch(authSessionProvider);
  return client.auth.currentSession != null;
});

/// Id do usuário autenticado (ou `'demo-player'` no modo demonstração).
///
/// O `GameController` observa este valor: ao trocar de usuário, recarrega tudo.
final currentUserIdProvider = Provider<String?>((ref) {
  if (AppConfig.useDemoData) return 'demo-player';
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  ref.watch(authSessionProvider);
  return client.auth.currentUser?.id;
});

/// Desfecho de um cadastro.
enum SignUpStatus { signedIn, awaitingEmailConfirmation, failed }

class SignUpResult {
  const SignUpResult(this.status, [this.message]);

  final SignUpStatus status;
  final String? message;
}

/// Ações de autenticação, com mensagens já em português.
class AuthController {
  AuthController(this._client);

  final SupabaseClient _client;

  /// Entra com e-mail e senha. Retorna `null` em caso de sucesso, ou a
  /// mensagem de erro a ser exibida.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on AuthException catch (error) {
      return _translate(error.message);
    } catch (_) {
      return 'Não foi possível entrar agora. Verifique a conexão.';
    }
  }

  /// Cria a conta. Se a confirmação de e-mail estiver ligada no projeto,
  /// retorna [SignUpStatus.awaitingEmailConfirmation].
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      if (response.session == null) {
        return const SignUpResult(SignUpStatus.awaitingEmailConfirmation);
      }
      return const SignUpResult(SignUpStatus.signedIn);
    } on AuthException catch (error) {
      return SignUpResult(SignUpStatus.failed, _translate(error.message));
    } catch (_) {
      return const SignUpResult(
        SignUpStatus.failed,
        'Não foi possível criar a conta agora. Verifique a conexão.',
      );
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  String _translate(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (lower.contains('already registered') ||
        lower.contains('already been registered')) {
      return 'Este e-mail já está cadastrado. Faça login.';
    }
    if (lower.contains('password should be')) {
      return 'A senha precisa ter ao menos 6 caracteres.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Muitas tentativas. Aguarde um instante e tente de novo.';
    }
    if (lower.contains('unable to validate email')) {
      return 'Informe um e-mail válido.';
    }
    return message;
  }
}

final authControllerProvider = Provider<AuthController?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AuthController(client);
});
