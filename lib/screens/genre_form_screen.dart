import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/catalog_cache.dart';
import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import '../state/genre_list_notifier.dart';
import '../utils/form_api_errors.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';

class GenreFormScreen extends StatefulWidget {
  const GenreFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _name = TextEditingController();
  Genre? _existing;
  var _loading = true;
  String? _nameServerError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      _existing = await context.read<GenreRepository>().findById(widget.id!);
      if (_existing != null) _name.text = _existing!.name;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() => _nameServerError = null);
    final repo = context.read<GenreRepository>();
    final draft = Genre(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      description: _existing?.description,
      deletedAt: _existing?.deletedAt,
    );
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
    } catch (e) {
      if (!mounted) return false;
      return handleFormApiError(
        context,
        error: e,
        onValidation: (errors) => setState(() {
          _nameServerError = errors['name'];
        }),
      );
    }
    if (!mounted) return false;
    context.read<CatalogCache>().invalidate();
    await context.read<GenreListNotifier>().load();
    if (!mounted) return false;
    context.go('/genres');
    return true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return EntityFormScaffold(
        title: widget.isEditing ? 'Изменить жанр' : 'Новый жанр',
        fields: const [],
        isLoading: true,
        onSubmit: () async => false,
      );
    }
    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить жанр' : 'Новый жанр',
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSubmit: _save,
      fields: [
        TextFormField(
          controller: _name,
          decoration: InputDecoration(
            labelText: 'Название',
            border: const OutlineInputBorder(),
            errorText: _nameServerError,
          ),
          validator: Validators.compose([
            (v) => _nameServerError,
            (v) => Validators.required(v, label: 'Название'),
            (v) => Validators.maxLength(v, 80, label: 'Название'),
            (v) => Validators.minLength(v, 2, label: 'Название'),
          ]),
        ),
      ],
    );
  }
}
