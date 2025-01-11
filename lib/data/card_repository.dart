//import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class CardRepository {
  static const String _cardFilePath = 'assets/cards.csv';

  // カードデータを読み込む関数
  static Future<List<Map<String, String>>> loadCards() async {
    try {
      // CSVファイルを読み込む
      final rawCsv = await rootBundle.loadString(_cardFilePath);
      final eol = rawCsv.contains('\r\n') ? '\r\n' : '\n';
      final rows = const CsvToListConverter().convert(rawCsv, eol: eol,fieldDelimiter: ",");

      // ヘッダー行を取得
      final headers = rows.first.map((e) => e.toString()).toList();
      // データ行をマップ形式に変換
      final cards = rows.sublist(1).map((row) {
        return Map.fromIterables(headers, row.map((e) => e.toString()));
      }).toList();
      return cards;
    } catch (e) {
      print('カードデータの読み込みに失敗しました: $e');
      return [];
    }
  }
}
