import 'package:flutter/foundation.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../core/api_exceptions.dart';
import '../repositories/genre_repository.dart';
import '../repositories/related_records_exception.dart';
import 'load_status.dart';

class GenreListNotifier extends ChangeNotifier {
  GenreListNotifier(this._repository);

  final GenreRepository _repository;

  GenreQuery _query = const GenreQuery();
  PageResult<Genre> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  GenreQuery get query => _query;
  PageResult<Genre> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(GenreQuery next) async {
    if (next == _query && _status == LoadStatus.success) return;
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  Future<String?> softDelete(int id) async {
    try {
      await _repository.softDelete(id);
      _selected.remove(id);
      await load();
      return null;
    } on RelatedRecordsException catch (e) {
      return e.toString();
    } on ConflictException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> hardDelete(int id) async {
    try {
      await _repository.hardDelete(id);
      _selected.remove(id);
      await load();
      return null;
    } on ConflictException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  Future<String?> deleteSelected() async {
    final before = _selected.length;
    final deleted = await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
    if (deleted < before) {
      return 'Удалено $deleted из $before. Остальные связаны с книгами.';
    }
    return null;
  }
}
