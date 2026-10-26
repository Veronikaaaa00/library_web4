import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';

/// Кэш справочников: один запрос на сессию приложения.
class CatalogCache {
  CatalogCache({
    required this._authors,
    required this._genres,
    required this._publishers,
  });

  final AuthorRepository _authors;
  final GenreRepository _genres;
  final PublisherRepository _publishers;

  List<Author>? _authorList;
  List<Genre>? _genreList;
  List<Publisher>? _publisherList;

  Future<List<Author>> authors({bool force = false}) async {
    if (!force && _authorList != null) return _authorList!;
    _authorList = await _authors.findAll();
    return _authorList!;
  }

  Future<List<Genre>> genres({bool force = false}) async {
    if (!force && _genreList != null) return _genreList!;
    _genreList = await _genres.findAll();
    return _genreList!;
  }

  Future<List<Publisher>> publishers({bool force = false}) async {
    if (!force && _publisherList != null) return _publisherList!;
    _publisherList = await _publishers.findAll();
    return _publisherList!;
  }

  void invalidate() {
    _authorList = null;
    _genreList = null;
    _publisherList = null;
  }
}
