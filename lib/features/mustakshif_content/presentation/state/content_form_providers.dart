import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'content_form_notifier.dart';
import 'content_list_providers.dart';

final mustakshifContentFormProvider = StateNotifierProvider.autoDispose<ContentFormNotifier, ContentFormState>(
  (ref) {
    final repo = ref.watch(mustakshifContentRepositoryProvider);
    return ContentFormNotifier(repo);
  },
);
