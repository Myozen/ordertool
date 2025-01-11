import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSONエンコード/デコードに必要
import '../data/card_repository.dart';

class DeckDetailPage extends StatefulWidget {
  final String deckId;
  final bool isNew;

  DeckDetailPage({required this.deckId, this.isNew = false});

  @override
  _DeckDetailPageState createState() => _DeckDetailPageState();
}

class _DeckDetailPageState extends State<DeckDetailPage> {
  List<Map<String, String>> _allCards = [];
  Map<int, int> _selectedCardCounts = {}; // カードIDと選択回数を追跡
  late TextEditingController _controller;
  bool isLoading = true; // ローディング状態を管理
  String _deckName = "新しいデッキ"; // 初期デッキ名
  static const int _maxDeckSize = 15;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _deckName);
    _loadCards();
    if (!widget.isNew) {
      _loadDeckData();
    } else {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDeckData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDeckJson = prefs.getString(widget.deckId);

    if (savedDeckJson != null) {
      final savedDeck = jsonDecode(savedDeckJson);

      setState(() {
        _deckName = savedDeck['name'];
        _controller.text = _deckName;
        _selectedCardCounts = (savedDeck['cards'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(int.parse(key), value));
        isLoading = false; // ローディング完了
      });
    }
  }

  Future<void> _saveDeckData() async {
    final prefs = await SharedPreferences.getInstance();

    final deckData = {
      'name': _deckName,
      'cards': _selectedCardCounts.map((key, value) => MapEntry(key.toString(), value)),
    };

    await prefs.setString(widget.deckId, jsonEncode(deckData));

    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text("デッキが保存されました")),
    );
  }

  Future<void> _loadCards() async {
    final cards = await CardRepository.loadCards();
    setState(() {
      _allCards = cards;
    });
  }

  int _getTotalCardCount() {
    return _selectedCardCounts.values.fold(0, (sum, count) => sum + count);
  }

  void _showCardDetails(Map<String, String> card) {
    final cardId = int.parse(card['id']!);
    //final cardName = card['name']!;
    final cardImage = card['image']!;
    int currentCount = _selectedCardCounts[cardId] ?? 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(8),
              
              content: SingleChildScrollView(
                  child:  AspectRatio(
                  aspectRatio: 59/86,
                  child: Image.asset(cardImage, 
                      fit: BoxFit.contain,
                      width: 59,
                      height: 86,
                    ),
                ),
              ),

              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(child: SizedBox()) ,
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (currentCount > 0) {
                                setDialogState(() {
                                  currentCount -= 1;
                                });
                                setState(() {
                                  _selectedCardCounts[cardId] = currentCount;
                                  if (currentCount == 0) {
                                    _selectedCardCounts.remove(cardId);
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            '$currentCount',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_getTotalCardCount() < _maxDeckSize && currentCount < 3) {
                                setDialogState(() {
                                  currentCount += 1;
                                });
                                setState(() {
                                  _selectedCardCounts[cardId] = currentCount;
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("閉じる"),
                      ),
                    )
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    
    // 画面の幅を取得
    final screenWidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    final mag = screenWidth/screenheight;
    final crossAxisCount = mag>1.5 ? 8 : mag>1.0? 6:4;

    return Scaffold(
      appBar: AppBar(
        title:  isLoading? const Text("読み込み中......")
        : Row(
          children: [
            Flexible(
              child: TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() {
                    _deckName = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "デッキ名を入力",
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // デッキ枚数表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                "${_getTotalCardCount()}/$_maxDeckSize",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDeckData,
          ),
        ],
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator())
      : Column(
        children: [
          // 現在のデッキリスト
          Flexible(
            flex: 0,
            child: _selectedCardCounts.isEmpty
                ? const Center(child: Text("空"))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedCardCounts.keys.map((cardId) {
                        final card = _allCards.firstWhere((c) => c['id'] == cardId.toString());
                        return GestureDetector(
                          onTap: () => _showCardDetails(card),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                Card(
                                  elevation: 5,
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        card['image']!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: FittedBox(fit: BoxFit.scaleDown,
                                          child: Text(
                                          card['name']!,
                                          style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:Colors.blue,
                                        child: Text("${_selectedCardCounts[cardId]}",
                                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const Divider(),
          // 全カードリスト
          Expanded(
            child: _allCards.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount, // 動的に計算した列数
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _allCards.length,
                    itemBuilder: (context, index) {
                      final card = _allCards[index];
                      return GestureDetector(
                        onTap: () => _showCardDetails(card),
                        child: Card(
                          elevation: 5,
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.asset(
                                  card['image']!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                  child:FittedBox(fit: BoxFit.scaleDown,
                                    child: Text(
                                    card['name']!,
                                    style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),
                                  ),
                                ), 
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
