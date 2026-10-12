/// Configuração de ambiente do app.
///
/// Todos os valores vêm de `--dart-define` (ou de `--dart-define-from-file=.env`),
/// nunca de código versionado. Ver `docs/SECURITY.md`.
class AppConfig {
  const AppConfig._();

  /// URL pública do projeto Supabase. Vazio => modo demonstração.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Chave `anon` (pública por design, protegida por RLS).
  ///
  /// A chave `service_role` NUNCA deve aparecer no app.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Liga/desliga explicitamente o modo demonstração (dados mockados).
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  /// Ambiente de execução: `dev`, `staging` ou `prod`.
  static const String env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Há credenciais suficientes para falar com o Supabase?
  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// O app roda com dados mockados (sem backend)?
  static bool get useDemoData => demoMode || !hasSupabaseCredentials;

  /// Versão exibida na UI — mantenha em sincronia com o `pubspec.yaml`.
  static const String appVersion = '0.1.0';

  static const String appName = 'Imperiall Game';
}
