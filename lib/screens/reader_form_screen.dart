import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../state/reader_list_notifier.dart';
import '../utils/form_api_errors.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';

class ReaderFormScreen extends StatefulWidget {
  const ReaderFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cardNumber = TextEditingController();
  final _issuedAt = TextEditingController();
  final _expiresAt = TextEditingController();
  var _cardActive = true;
  Reader? _existing;
  var _loading = true;
  String? _emailUniqueError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    if (widget.isEditing) {
      _existing = await context.read<ReaderRepository>().findById(widget.id!);
      final r = _existing;
      if (r != null) {
        _firstName.text = r.firstName;
        _lastName.text = r.lastName;
        _email.text = r.email;
        _phone.text = r.phone;
        _cardNumber.text = r.card.number;
        _issuedAt.text = _fmt(r.card.issuedAt);
        _expiresAt.text = _fmt(r.card.expiresAt);
        _cardActive = r.card.isActive;
      }
    } else {
      final now = DateTime.now();
      _issuedAt.text = _fmt(now);
      _expiresAt.text = _fmt(now.add(const Duration(days: 365)));
    }
    if (mounted) setState(() => _loading = false);
  }

  String? _dateValidator(String? value, {required String label}) {
    final base = Validators.required(value, label: label);
    if (base != null) return base;
    if (DateTime.tryParse(value!.trim()) == null) {
      return '$label: формат ГГГГ-ММ-ДД';
    }
    return null;
  }

  Future<bool> _save() async {
    setState(() => _emailUniqueError = null);
    final repo = context.read<ReaderRepository>();
    final taken = await repo.isEmailTaken(_email.text, excludeId: widget.id);
    if (taken) {
      setState(() => _emailUniqueError = 'Email уже используется');
      return false;
    }

    final issued = DateTime.parse(_issuedAt.text.trim());
    final expires = DateTime.parse(_expiresAt.text.trim());
    if (!expires.isAfter(issued)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Срок действия должен быть позже выдачи'),
          ),
        );
      }
      return false;
    }

    final draft = Reader(
      id: widget.id ?? 0,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      card: LibraryCard(
        number: _cardNumber.text.trim(),
        issuedAt: issued,
        expiresAt: expires,
        isActive: _cardActive,
      ),
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
        onValidation: (errors) {
          setState(() {
            if (errors['email'] != null) {
              _emailUniqueError = errors['email'];
            }
          });
        },
      );
    }
    if (!mounted) return false;
    await context.read<ReaderListNotifier>().load();
    if (!mounted) return false;
    context.go('/readers');
    return true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    _issuedAt.dispose();
    _expiresAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return EntityFormScaffold(
        title: widget.isEditing ? 'Изменить читателя' : 'Новый читатель',
        fields: const [],
        isLoading: true,
        onSubmit: () async => false,
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить читателя' : 'Новый читатель',
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSubmit: _save,
      fields: [
        TextFormField(
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Фамилия',
            border: OutlineInputBorder(),
          ),
          validator: Validators.compose([
            (v) => Validators.required(v, label: 'Фамилия'),
            (v) => Validators.maxLength(v, 80, label: 'Фамилия'),
          ]),
        ),
        TextFormField(
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          validator: Validators.compose([
            (v) => Validators.required(v, label: 'Имя'),
            (v) => Validators.maxLength(v, 80, label: 'Имя'),
          ]),
        ),
        TextFormField(
          controller: _email,
          decoration: InputDecoration(
            labelText: 'Email',
            border: const OutlineInputBorder(),
            errorText: _emailUniqueError,
          ),
          validator: (v) => _emailUniqueError ?? Validators.email(v),
        ),
        TextFormField(
          controller: _phone,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
          ),
          validator: Validators.phone,
        ),
        const Divider(),
        Text(
          'Читательский билет',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextFormField(
          controller: _cardNumber,
          decoration: const InputDecoration(
            labelText: 'Номер билета',
            border: OutlineInputBorder(),
          ),
          validator: Validators.compose([
            (v) => Validators.required(v, label: 'Номер билета'),
            (v) => Validators.maxLength(v, 40, label: 'Номер билета'),
          ]),
        ),
        TextFormField(
          controller: _issuedAt,
          decoration: const InputDecoration(
            labelText: 'Выдан (ГГГГ-ММ-ДД)',
            border: OutlineInputBorder(),
          ),
          validator: (v) => _dateValidator(v, label: 'Дата выдачи'),
        ),
        TextFormField(
          controller: _expiresAt,
          decoration: const InputDecoration(
            labelText: 'Действует до (ГГГГ-ММ-ДД)',
            border: OutlineInputBorder(),
          ),
          validator: (v) => _dateValidator(v, label: 'Срок действия'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Билет активен'),
          value: _cardActive,
          onChanged: (v) => setState(() => _cardActive = v),
        ),
      ],
    );
  }
}
