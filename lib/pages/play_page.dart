import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/card_repository.dart';
import '../data/rules.dart';

enum CardPlace {
  hand,
  zone,
  graveyard,
}

class PlayPage extends StatefulWidget {
  final String deckId;

  PlayPage({required this.deckId});

  @override
  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  int lifePoints = 4000; // 初期ライフポイント
  int counter = 0; // ゲーム用カウンター
  List<int> counters = [0,0,0,0,0,0];
  String lastRoll = '';

  List<String> graveyard = [];
  List<String> hand = [];
  List<String> deck = [];
  List<String> publicCards = [];
  List<String> declaredCards = [];

  Random random = Random();

  bool isShowingHand = false; // 手札リストを表示中かどうか
  bool isShowingGraveyard = false; // 墓地リストを表示中かどうか

  List<Map<String, String>> _allCards = [];
  int lastFlag = 2; //決着がつくカウンター数
  Color? _buttonColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _loadCards();
    _loadDecks();
  }

  Future<void> _loadCards() async {
    final cards = await CardRepository.loadCards();
    setState(() {
      _allCards = cards;
    });
  }

  Future<void> _loadDecks() async {
    final prefs = await SharedPreferences.getInstance();
    var deckList =  jsonDecode(prefs.getString(widget.deckId) ?? '{}')['cards'];
    setState(() {
      for(String key in deckList.keys){
        for(int i = 0; i < deckList[key]; i++){
          deck.add(key);
        }
      }
      _shuffleDeck();
    });
    _initDraw();
  }

  void _shuffleDeck() {
    deck.shuffle(random);
    //print("シャッフル後のスタック: $deck"); // デバッグ用
  }

  void _initDraw(){
    int loopNum = deck.length < 5 ? deck.length : 5;
    setState(() {
      for(int i=0; i<loopNum; i++){
        hand.add(deck.last);
        deck.removeLast();
      }
    });
    //print(deck);
    //print(hand);
  }

  void _drawCard(){
    setState(() {
      if(deck.isNotEmpty){
        hand.add(deck.last);
        deck.removeLast();
      }
    });
  }

  void _rollDice() {
    final diceResult = Random().nextInt(6) + 1; // 1~6のサイコロ
    setState(() {
      lastRoll = "ダイス：$diceResult";
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(lastRoll)),
    );
  }

  void _flipCoin() {
    final coinResult = Random().nextBool() ? "表" : "裏";
    setState(() {
      lastRoll = "コイン：$coinResult";
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(lastRoll)),
    );
  }

  void _showLifePointCalculator() {
    showDialog(
      context: context,
      builder: (context) {
        int enteredValue = 0; // 入力中の値
        String operatorType = '-';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addDigit(int digit) {
              setDialogState(() {
                enteredValue = enteredValue * 10 + digit;
              });
            }

            void clearEntry() {
              setDialogState(() {
                enteredValue = 0;
              });
            }

            void applyChange(int multiplier) {
              if(enteredValue==0)return;
              setState(() {
                if(operatorType=='÷') {lifePoints = (lifePoints / enteredValue).ceil();}
                else if(operatorType=='×') {lifePoints = (lifePoints * enteredValue).ceil();}
                else if(operatorType=='+') {lifePoints += enteredValue;}
                else {lifePoints = (lifePoints - enteredValue) > 0 ? lifePoints - enteredValue : 0;}
              });
              Navigator.pop(context);
            }

            void addOperator(String op){
              setDialogState(() {
                operatorType = op;
              });
            }

            void reset(){
              setState(() {
                lifePoints = 4000;
              });
            }

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min, // サイズをコンテンツに合わせる
                children: [
                  Text(
                    enteredValue!=0 ? "$lifePoints $operatorType $enteredValue" : "$lifePoints $operatorType",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    width: 400,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        if (index == 0){
                          return ElevatedButton(
                            onPressed: () => {
                              addOperator('÷')
                            },
                            child: const Text("÷", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                          );
                        }else if(index == 1){
                          return ElevatedButton(
                            onPressed: () => {
                              addOperator('×')
                            },
                            child: const Text("×", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                          );
                        }else if(index == 2){
                          return ElevatedButton(
                            onPressed: () => {
                              addOperator('-')
                            },
                            child: const Text("-", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                          );
                        }else{
                          return ElevatedButton(
                            onPressed: () => {
                              addOperator('+')
                            },
                            child: const Text("+", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                          );
                        }
                      },
                    )
                  ),
                  SizedBox(
                    height: 270, 
                    width: 400,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        if (index < 9) {
                          return ElevatedButton(
                            onPressed: () => addDigit(index + 1),
                            child: Text("${index + 1}", style: TextStyle(fontSize: 18)),
                          );
                        } else if (index == 9) {
                          return ElevatedButton(
                            onPressed: clearEntry,
                            child: const Text("C", style: TextStyle(fontSize: 18)),
                          );
                        } else if (index == 10) {
                          return ElevatedButton(
                            onPressed: () => addDigit(0),
                            child: const Text("0", style: TextStyle(fontSize: 18)),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () => applyChange(1),
                            child: const Text("OK", style: TextStyle(fontSize: 18)),
                          );
                        }
                      },
                    )
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    reset();
                    Navigator.pop(context);
                  },
                  child: const Text("リセット"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("閉じる"),
                ),
              ]
            );
          },
        );
      },
    );
  }

  Padding _counterTile(int num) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("C$num",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              setState(() {
                counters[num] = counters[num] > 0 ? counters[num] - 1 : 0;
              });
            },
          ),
          Text(
            "${counters[num]}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                counters[num] += 1;
              });
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // ライフポイント表示
              GestureDetector(
                onTap: () => _showLifePointCalculator(),
                child: Row(
                  children: [
                    const Icon(Icons.favorite),
                    Text("：$lifePoints", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // ゲーム用カウンター
              IconButton(
                onPressed: () {
                  setState(() {
                    counter = counter > 0 ? counter - 1 : 0;
                  });
                },
                icon: const Icon(Icons.remove),
              ),
              const  Icon(Icons.flag),
              const Text('：'),
              Text("$counter", 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: counter < lastFlag ? Colors.black : Colors.red,
                )
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    counter += 1;
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
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

  Drawer _buildSideBar(){
    return Drawer(
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
          const Divider(),
          ListTile(
            title: const Text("ダイス"),
            onTap: () {
              Navigator.pop(context);
              _rollDice();
            },
          ),
          ListTile(
            title: const Text("コイン"),
            onTap: () {
              Navigator.pop(context);
              _flipCoin();
            },
          ),
          const Divider(),
          const ListTile(title: Text("カウンター"),),
          _counterTile(0),
          _counterTile(1),
          _counterTile(2),
          _counterTile(3),
          _counterTile(4),
          _counterTile(5),
        ],
      ),
    );
  }

  void _toggleHandList() {
    setState(() {
      isShowingHand = !isShowingHand;
      isShowingGraveyard = false; // 墓地リストを閉じる
    });
  }

  void _toggleGraveyardList() {
    setState(() {
      isShowingGraveyard = !isShowingGraveyard;
      isShowingHand = false; // 手札リストを閉じる
    });
  }

  void _useCard(Map<String, String> card, int cardIndex){
    final cardId = card['id']!;
    final cardType = card['description']!;
    //print(cardType);
    setState(() {
      if(cardType=='revealment'){
        publicCards.add(cardId);
      }else{
        declaredCards.add(cardId);
      }
      hand.removeAt(cardIndex);
    });
  }

  Widget _buildCardList(List<String> cards, CardPlace usedPlace){
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Flexible(
            flex: 0,
            child: cards.isEmpty ? 
              const SizedBox(height: 16+150,) 
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cards.asMap().entries.map((entry) {
                    final cardId = entry.value;
                    final card = _allCards.firstWhere((c) => c['id'] == cardId);
                    final index = entry.key;
                    return GestureDetector(
                      onTap: () => _showCardDetails(card,index,usedPlace),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 150,
                              width: 100,
                              child:  Card(
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
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ).toList(),
              ),
            ),
          ),
        ]
      )
    );
  }

  void _discardCard(Map<String, String> card,int cardIndex){
    final cardId = card['id']!;
    final cardType = card['description']!;
    setState(() {
      graveyard.add(cardId);
      if(cardType=='revealment'){
        publicCards.removeAt(cardIndex);
      }else{
        declaredCards.removeAt(cardIndex);
      }
    });
  }
  
  void _showCardDetails(Map<String, String> card,int cardIndex,CardPlace usedPlace) {
    final cardImage = card['image']!;

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
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("閉じる"),
                ),
                usedPlace == CardPlace.graveyard ? const SizedBox() 
                : TextButton(
                  onPressed: () {
                    usedPlace == CardPlace.zone ? 
                      _discardCard(card,cardIndex) : 
                      _useCard(card,cardIndex);
                    Navigator.pop(context);
                  },
                  child: usedPlace == CardPlace.zone ? const Text("破棄") : const Text("使用"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        //if (isShowingHand) _buildCardList(hand),//_buildHandList(),
        //if (isShowingGraveyard) _buildCardList(graveyard),//_buildGraveyardList(),
        
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 墓地
              GestureDetector(
                onTap: _toggleGraveyardList,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isShowingGraveyard ? Colors.blue[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete, size: 30),
                      Text("：${graveyard.length}", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // 手札
              GestureDetector(
                onTap: _toggleHandList,
                child: Container(
                  padding: const  EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isShowingHand ? Colors.blue[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pan_tool, size: 30),
                      Text("：${hand.length}",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // スタック
              GestureDetector(
                onTap: _drawCard,
                onTapDown: (TapDownDetails details){
                  setState(() {
                    _buttonColor = Colors.blue[100];
                  });
                },
                onTapUp: (TapUpDetails details){
                  setState(() {
                    _buttonColor = Colors.transparent;
                  });
                },
                onTapCancel: (){
                  setState(() {
                    _buttonColor = Colors.transparent;
                  });
                },
                child: Container(
                  padding: const  EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _buttonColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers, size: 30),
                      Text("：${deck.length}",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
              ),
            ],
          ),
        ),
      ]
    );
  }

  Widget _buildCardListSection({
    required String title,
    required List<String> cards,
    required Color? color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    final mag = screenWidth/screenheight;
    final crossAxisCount = mag>1.5 ? 8 : mag>1.0? 6:4;
    return Container(
      color: color,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const  Divider(),
          Expanded(
            child: cards.isEmpty ? 
            const SizedBox() 
            : GridView.builder(
                padding: const EdgeInsets.all(4.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: cards.length,
                itemBuilder: (context,index){
                  final card = _allCards.firstWhere((c) => c['id'] == cards[index]);
                  return GestureDetector(
                    onTap: () => _showCardDetails(card,index,CardPlace.zone),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      endDrawer: _buildSideBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // 公開されたカードの一覧
              Expanded(
                child: _buildCardListSection(
                  title: "公開：${publicCards.length}",
                  cards: publicCards,
                  color: Colors.green[100],
                ),
              ),
              const Divider(height: 1),
              // 使用を宣言されたカードの一覧
              Expanded(
                child: _buildCardListSection(
                  title: "使用宣言：${declaredCards.length}",
                  cards: declaredCards,
                  color: Colors.orange[100],
                ),
              ),
              const Divider(height: 1),
            ]
          ),
          if (isShowingHand) Positioned(
            bottom:0,
            right:0,
            left:0,
            child: _buildCardList(hand,CardPlace.hand),
          ),
          if (isShowingGraveyard) Positioned(
            bottom:0,
            right:0,
            left:0,
            child: _buildCardList(graveyard,CardPlace.graveyard),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}
