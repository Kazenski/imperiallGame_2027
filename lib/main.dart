import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase apenas quando há credenciais. Sem elas, o app abre
  // em modo demonstração (dados locais, nenhuma conta necessária).
  //
  // `publishableKey` aceita tanto a chave anon (legada) quanto a publishable.
  if (AppConfig.hasSupabaseCredentials) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: ImperiallGameApp()));
}
