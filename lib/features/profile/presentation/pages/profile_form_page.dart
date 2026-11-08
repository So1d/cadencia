import 'package:flutter/material.dart';

import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/profile_focus.dart';
import '../../domain/entities/user_profile.dart';
import '../profile_scope.dart';
import '../widgets/discard_changes_dialog.dart';
import '../widgets/focus_field.dart';
import '../widgets/profile_privacy_note.dart';

/// Formulário de perfil: nome, prioridades, meta e início da semana.
class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  /// Um só lugar sabe como abrir o formulário: Home e aba Perfil usam este.
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ProfileFormPage());
  }

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final UserProfile _original;
  late UserProfile _draft;
  late final TextEditingController _nameController;
  bool _submitted = false;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _original = ProfileScope.read(context).profile;
    _draft = _original;
    _nameController = TextEditingController(text: _original.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasChanges => !_saved && _draft != _original;

  void _onNameChanged(String text) {
    final name = text.trim();
    setState(() {
      _draft = name.isEmpty
          ? _draft.copyWith(clearName: true)
          : _draft.copyWith(name: name);
    });
  }

  void _onFocusChanged(Set<ProfileFocus> focus) {
    setState(() => _draft = _draft.copyWith(focus: focus));
  }

  void _onGoalChanged(double value) {
    setState(() => _draft = _draft.copyWith(dailyGoal: value.round()));
  }

  void _onWeekStartChanged(bool mondayFirst) {
    setState(
      () => _draft = _draft.copyWith(weekStartsMonday: mondayFirst),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ProfileScope.read(context);

    try {
      await controller.save(_draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.'),
          ),
        );
      return;
    }

    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Perfil salvo')));

    // Marca como salvo antes de sair: assim o `PopScope` libera a rota e o
    // diálogo de "descartar alterações?" não aparece depois de salvar.
    setState(() {
      _isSaving = false;
      _saved = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    });
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await confirmDiscardChanges(context);
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isNotEmpty && name.length < 2) {
      return 'Use pelo menos 2 letras.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    AppSpacing.md,
                    horizontal,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Como podemos te chamar?'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildNameField(),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        title: 'O que você quer ver primeiro?',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: FocusField(
                            initialValue: _original.focus,
                            onChanged: _onFocusChanged,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'Sua meta diária'),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Quantas tarefas você quer concluir por dia?',
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _draft.dailyGoal.toDouble(),
                                      min: 1,
                                      max: 10,
                                      divisions: 9,
                                      label: '${_draft.dailyGoal}',
                                      semanticFormatterCallback: (value) =>
                                          '${value.round()} tarefas por dia',
                                      onChanged: _onGoalChanged,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${_draft.dailyGoal}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Semana começa na segunda'),
                                subtitle: const Text(
                                  'Muda o primeiro dia exibido no calendário.',
                                ),
                                value: _draft.weekStartsMonday,
                                onChanged: _onWeekStartChanged,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const ProfilePrivacyNote(),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveButton(horizontal),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      key: const Key('profile-name'),
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nome (opcional)',
        helperText: 'Aparece só na saudação do app.',
      ),
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.givenName],
      maxLength: 30,
      validator: _validateName,
      onChanged: _onNameChanged,
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }

  Widget _buildSaveButton(double horizontal) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.sm,
          horizontal,
          AppSpacing.md,
        ),
        child: FilledButton(
          key: const Key('profile-save'),
          onPressed: _hasChanges && !_isSaving ? _save : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Salvando',
                  ),
                )
              : const Text('Salvar perfil'),
        ),
      ),
    );
  }
}
