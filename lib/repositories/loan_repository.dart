import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';

/// Минимальный клиент выдач — для демонстрации 409.
class LoanRepository {
  LoanRepository(this._dio);

  final Dio _dio;

  Future<void> createLoan({
    required int readerId,
    required int bookId,
    int days = 14,
  }) =>
      guard(
        () => _dio.post(
          '/loans',
          data: {'readerId': readerId, 'bookId': bookId, 'days': days},
        ),
      );
}
