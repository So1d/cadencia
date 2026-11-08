import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/profile_focus.dart';

/// Campo de escolha das prioridades do perfil.
///
/// É um `FormField` de verdade: participa da validação do formulário e mostra
/// o erro no lugar certo, em vez de um `setState` solto.
class FocusField extends FormField<Set<ProfileFocus>> {
  FocusField({
    super.key,
    required Set<ProfileFocus> super.initialValue,
    required ValueChanged<Set<ProfileFocus>> onChanged,
  }) : super(
          validator: (value) => (value == null || value.isEmpty)
              ? 'Escolha pelo menos uma prioridade.'
              : null,
          builder: (state) {
            final selected = state.value ?? const <ProfileFocus>{};
            final error = state.errorText;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final focus in ProfileFocus.values)
                  CheckboxListTile(
                    value: selected.contains(focus),
                    title: Text(focus.label),
                    subtitle: Text(focus.description),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (checked) {
                      final next = {...selected};
                      if (checked ?? false) {
                        next.add(focus);
                      } else {
                        next.remove(focus);
                      }
                      state.didChange(next);
                      onChanged(next);
                    },
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: Theme.of(state.context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(state.context)
                                  .colorScheme
                                  .error,
                            ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}
