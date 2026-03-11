import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'application/providers/app_providers.dart';
import 'core/utils/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/viewmodels/settings_view_model.dart';
import 'presentation/widgets/upper_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: IAprendeApp()));
}

class IAprendeApp extends ConsumerWidget {
  const IAprendeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    return startup.when(
      data: (_) {
        final settings = ref.watch(settingsViewModelProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'IAprende',
          theme: buildAppTheme(settings),
          home: const HomeScreen(),
        );
      },
      error: (error, stack) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: UpperText('ERROR DE INICIO: $error'),
              ),
            ),
          ),
        );
      },
      loading: () {
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      child: Image(
                        image: AssetImage('assets/images/image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  UpperText('IAprende'),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  UpperText('CARGANDO CONTENIDO OFFLINE...'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
