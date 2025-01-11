import 'package:flutter/material.dart';
import 'pages/deck_selection_page.dart';
import 'pages/deck_detail_page.dart';
import 'pages/play_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'オーダーゲームツール',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // ページ遷移の管理
        if (settings.name == '/deck_detail') {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (context) => DeckDetailPage(
              deckId: args['deckId'],
              isNew: args['isNew'] ?? false,
            ),
          );
        } else if (settings.name == '/play') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PlayPage(deckId: args['deckId']),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => DeckSelectionPage(),
      },
    );
  }
}

