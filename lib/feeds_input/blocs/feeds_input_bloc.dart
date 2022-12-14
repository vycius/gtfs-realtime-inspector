import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:gtfs_realtime_inspector/feeds_input/models/feeds_input.dart';
import 'package:gtfs_realtime_inspector/utils.dart';

class FeedsInputBloc extends FormBloc<FeedsInput, String> {
  final String? initialGtfsUrl;
  final List<String> initialGtfsRealtimeUrls;

  late final gtfsUrl = TextFieldBloc(
    initialValue: initialGtfsUrl ?? '',
    validators: [urlValidator],
  );
  late final gtfsRealtime1Url = TextFieldBloc(
    initialValue: initialGtfsRealtimeUrls.elementAtOrNull(0) ?? '',
    validators: [FieldBlocValidators.required, urlValidator],
  );
  late final gtfsRealtime2Url = TextFieldBloc(
    initialValue: initialGtfsRealtimeUrls.elementAtOrNull(1) ?? '',
    validators: [urlValidator],
  );
  late final gtfsRealtime3Url = TextFieldBloc(
    initialValue: initialGtfsRealtimeUrls.elementAtOrNull(2) ?? '',
    validators: [urlValidator],
  );

  FeedsInputBloc({
    required this.initialGtfsUrl,
    required this.initialGtfsRealtimeUrls,
  }) : super() {
    addFieldBlocs(
      fieldBlocs: [
        gtfsUrl,
        gtfsRealtime1Url,
        gtfsRealtime2Url,
        gtfsRealtime3Url,
      ],
    );
  }

  void updateValues(
    String? gtfsUrlValue,
    List<String> gtfsRealtimeUrlsValue,
  ) {
    gtfsUrl.updateValue(gtfsUrlValue ?? '');
    gtfsRealtime1Url.updateValue(
      gtfsRealtimeUrlsValue.elementAtOrNull(0) ?? '',
    );
    gtfsRealtime2Url.updateValue(
      gtfsRealtimeUrlsValue.elementAtOrNull(1) ?? '',
    );
    gtfsRealtime3Url.updateValue(
      gtfsRealtimeUrlsValue.elementAtOrNull(2) ?? '',
    );
  }

  @override
  FutureOr<void> onSubmitting() {
    final gtfsRealtimeUrls = [
      gtfsRealtime1Url.value,
      gtfsRealtime2Url.value,
      gtfsRealtime3Url.value,
    ].where((u) => u.isNotEmpty).toList();

    final gtfs = gtfsUrl.value.isNotEmpty ? gtfsUrl.value : null;

    emitSuccess(
      successResponse: FeedsInput(
        gtfsUrl: gtfs,
        gtfsRealtimeUrls: gtfsRealtimeUrls,
      ),
    );
  }
}
