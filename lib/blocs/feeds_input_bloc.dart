import 'dart:async';

import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:gtfs_realtime_inspector/screens/input/feeds_input_screen.dart';
import 'package:gtfs_realtime_inspector/utils.dart';

class FeedsInputBloc extends FormBloc<FeedsInput, String> {
  final gtfsUrl = TextFieldBloc(
    validators: [FieldBlocValidators.required, urlValidator],
  );
  final gtfsRealtime1Url = TextFieldBloc(
    validators: [FieldBlocValidators.required, urlValidator],
  );
  final gtfsRealtime2Url = TextFieldBloc(validators: [urlValidator]);
  final gtfsRealtime3Url = TextFieldBloc(validators: [urlValidator]);

  FeedsInputBloc() : super() {
    addFieldBlocs(
      fieldBlocs: [
        gtfsUrl,
        gtfsRealtime1Url,
        gtfsRealtime2Url,
        gtfsRealtime3Url,
      ],
    );
  }

  @override
  FutureOr<void> onSubmitting() {
    final gtfsRealtimeUrls = [
      gtfsRealtime1Url.value,
      gtfsRealtime2Url.value,
      gtfsRealtime3Url.value,
    ].where((u) => u.isNotEmpty).toList();

    emitSuccess(
      successResponse: FeedsInput(
        gtfsUrl: gtfsUrl.value,
        gtfsRealtimeUrls: gtfsRealtimeUrls,
      ),
    );
  }
}
