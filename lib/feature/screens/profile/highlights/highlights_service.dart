import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatloop/core/models/highlight_model.dart';

class HighlightsService {
  static const _key = 'profile_highlights';

  static Future<List<HighlightModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) {
      try {
        return HighlightModel.fromMap(jsonDecode(e));
      } catch (_) {
        return null;
      }
    }).whereType<HighlightModel>().toList();
  }

  static Future<void> save(List<HighlightModel> highlights) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = highlights.map((h) => jsonEncode(h.toMap())).toList();
    await prefs.setStringList(_key, raw);
  }

  static Future<void> add(HighlightModel highlight) async {
    final list = await load();
    list.add(highlight);
    await save(list);
  }

  static Future<void> delete(String id) async {
    final list = await load();
    list.removeWhere((h) => h.id == id);
    await save(list);
  }
}

class HighlightsNotifier extends ChangeNotifier {
  List<HighlightModel> _highlights = [];

  List<HighlightModel> get highlights => List.unmodifiable(_highlights);

  HighlightsNotifier() {
    _load();
  }

  Future<void> _load() async {
    _highlights = await HighlightsService.load();
    notifyListeners();
  }

  Future<void> add(HighlightModel highlight) async {
    await HighlightsService.add(highlight);
    _highlights = await HighlightsService.load();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await HighlightsService.delete(id);
    _highlights = await HighlightsService.load();
    notifyListeners();
  }

  Future<void> refresh() async {
    await _load();
  }
}
