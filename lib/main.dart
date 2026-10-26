import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/auth_token_store.dart';
import 'core/catalog_cache.dart';
import 'core/config.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final tokens = AuthTokenStore();
  final dio = buildDio(tokenStore: tokens);
  final auth = AuthRepository(dio, tokens);

  // Мутации требуют роль librarian/admin — логинимся при старте.
  try {
    await auth.loginAsAdmin();
  } catch (e) {
    debugPrint(
      'Не удалось войти в API ($apiBaseUrl): $e. '
      'Запустите mock-server и откройте приложение с --web-port=5555.',
    );
  }

  final books = ApiBookRepository(dio);
  final authors = ApiAuthorRepository(dio);
  final genres = ApiGenreRepository(dio);
  final publishers = ApiPublisherRepository(dio);
  final readers = ApiReaderRepository(dio);
  final loans = LoanRepository(dio);
  final catalog = CatalogCache(
    authors: authors,
    genres: genres,
    publishers: publishers,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<AuthTokenStore>.value(value: tokens),
        Provider<AuthRepository>.value(value: auth),
        Provider<BookRepository>.value(value: books),
        Provider<AuthorRepository>.value(value: authors),
        Provider<GenreRepository>.value(value: genres),
        Provider<PublisherRepository>.value(value: publishers),
        Provider<ReaderRepository>.value(value: readers),
        Provider<LoanRepository>.value(value: loans),
        Provider<CatalogCache>.value(value: catalog),
        ChangeNotifierProvider(
          create: (_) => BookListNotifier(books)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthorListNotifier(authors)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => GenreListNotifier(genres)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => PublisherListNotifier(publishers)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderListNotifier(readers)..load(),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E8C),
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
