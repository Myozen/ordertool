import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'play_page.dart';
import 'deck_detail_page.dart';
import '../data/rules.dart';

class DeckSelectionPage extends StatefulWidget {
  @override
  _DeckSelectionPageState createState() => _DeckSelectionPageState();
}

class _DeckSelectionPageState extends State<DeckSelectionPage> {
  List<String> _deckIds = []; // スタックIDのリスト
  Map<String, String> _deckNames = {}; // スタックIDに対応するスタック名

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  // 保存されたスタック情報をロード
  Future<void> _loadDecks() async {
    final prefs = await SharedPreferences.getInstance();

    // すべてのキーを取得
    final keys = prefs.getKeys().where((key) => key.startsWith('deck_')).toList();
    setState(() {
      _deckIds = keys;
      _deckNames = {
        for (var key in keys)
          key: jsonDecode(prefs.getString(key) ?? '{}')['name'] ?? 'スタック名なし'
      };
    });
  }

  Future<void> _deleteDeck(String delDeckId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(delDeckId);
  }

  // 新しいスタックIDを生成
  String _generateDeckId() {
    final now = DateTime.now();
    return 'deck_${now.toIso8601String()}';
  }

  void _showRule() {
    showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context,setDialogState) {
            return AlertDialog(
              title: const Text("オーダールール説明"),
              content: const RuleWidget(),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("閉じる"),
                ),
              ],
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("スタック選択"),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              trailing: Icon(Icons.clear),
              onTap: (){
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("オーダールール説明"),
              onTap: () {
                Navigator.pop(context);
                _showRule();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildDeckList(),
      ),
    );
  }

  // スタックがある場合のUI
  Widget _buildDeckList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    final mag = screenWidth/screenheight;
    final crossAxisCount = mag>1.5 ? 8 : mag>1.0? 6:4;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _deckIds.length + 1, // スタック数 + 作成ボタン
      itemBuilder: (context, index) {
        if (index == _deckIds.length) {
          // 新しいスタック作成ボタン
          return _createDeckCard();
        } else {
          // 既存のスタックアイコン
          return _buildDeckCard(_deckIds[index]);
        }
      },
    );
  }

  // 新しいスタック作成ボタン
  Widget _createDeckCard() {
    const String assetPath = 'assets/icons/create_icon.png';
    return GestureDetector(
      onTap: () async {
        final newDeckId = _generateDeckId(); // 新しいスタックIDを生成
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeckDetailPage(
              deckId: newDeckId,
              isNew: true, // 新規スタックフラグを設定
            ),
          ),
        ).then((_) => _loadDecks()); // 戻った後にスタックリストを更新
      },
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Expanded(child: Image.asset(assetPath, fit:BoxFit.cover)),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown,
              child: Text( "新規作成",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10)
          ],
        ),
      ),
    );
  }

  // 既存のスタックカードのUI
  Widget _buildDeckCard(String deckId) {
    const String assetPath = 'assets/icons/deck_icon.png';
    final deckName = _deckNames[deckId] ?? "名無し";
    return GestureDetector(
      onTap: () => _showDeckOptions(deckId),
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Expanded(child: Image.asset(assetPath, fit:BoxFit.cover)),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown,
              child: Text( deckName,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10)
          ],
        ),
      ),
    );
  }

  void _showDeckOptions(String deckId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("選択してください"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDeck(deckId);
                _loadDecks();
              },
              child: const Text("破棄"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckDetailPage(
                      deckId: deckId,
                      isNew: false,
                    ),
                  ),
                ).then((_) => _loadDecks());
              },
              child: const Text("編集"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayPage(deckId: deckId),
                  ),
                );
              },
              child: const Text("プレイ"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }
}
