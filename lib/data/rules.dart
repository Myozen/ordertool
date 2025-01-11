import 'package:flutter/material.dart';

class RuleWidget extends StatelessWidget{

  const RuleWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('　オーダールールでは通常のカードにオーダーカードを加えて行う。'),
          Divider(),
          Text('オーダールールの終了条件',style: TextStyle(fontSize: 18)),
          Text('　ライフポイント4000で始まり、3度ライフポイントが0になったプレイヤーは敗北する。'),
          Text('　ライフポイントが0になったプレイヤーは次の自分のターン開始時にライフポイントを4000に戻す。'),
          Text('　ライフポイントが0になった回数をフラグ，戻す処理を回復処理と呼ぶ。'),
          Text('　回復処理を挟まずにフラグを進めることはできない。'),
          Text('　回復処理や後述するデッキにカードを戻す処理はルールによって行われるため、カードの発動のトリガーにできない。'),
          Text('特殊勝利の場合',style: TextStyle(fontSize: 16)),
          Text('　条件を満たしたプレイヤーはそのタイミングで特殊勝利効果を適用したカードを自身のデッキに戻す。'),
          Text('　他のプレイヤーはライフポイントが0になった場合と同じ処理を行う。'),
          Text('デッキ切れの場合',style: TextStyle(fontSize: 16)),
          Text('　墓地、除外状態、EXデッキ表側のいずれか一か所以上を選び、指定した場所のカード全てをデッキに戻す。その後ライフポイントが0になった場合と同じ処理を行う。'),
          Divider(),
          Text('オーダーカードの特徴',style: TextStyle(fontSize: 18)),
          Text('　デッキ、墓地、手札を別で管理する。'),
          Text('　オーダーカード専用のデッキ、墓地、手札、ドロー、墓地送りには異なる名称を用いる。'),
          Text('　　・山札：スタック'),
          Text('　　・手札：リスト'),
          Text('　　・墓地：トラッシュ'),
          Text('　　・ドロー：ポップ'),
          Text('　　・墓地送り：破棄'),
          Text('　スタックは最大15枚まで。'),
          Text('　ゲーム開始時、互いにリストに5枚加えて始める。'),
          Text('　自分のドローフェイズに通常ドローの前に1枚ポップする（先行1ターン目はなし）。'),
          Text('　フラグ数が相手より多いプレイヤーは加えてもう1枚ポップする。'),
          Text('　指定がない限り、自分や相手のターン問わず、いかなるタイミングでも発動できる。'),
          Text('　発動するためにゾーンは必要ない（魔法罠ゾーン、モンスターゾーンが埋まっていても発動できる）。'),
          Text('　スペルスピードに関係なく発動できる（チェーンを組んだカードと同じスペルスピードになる）。'),
          Text('　チェーン不可能なカードに対してもチェーンできる（その後はオーダーカードだけしかチェーンできない）。'),
          Text('　指定がない限り、オーダーカードはオーダーカード以外の効果を受けない。'),
        ],
      ),
    );
  }
}