import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';

class SyncSelectorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectCubit, InspectScreenState>(
      buildWhen: (p, c) => p.realtimeSyncState != c.realtimeSyncState,
      builder: (context, state) {
        return Card(
          child: ToggleButtons(
            onPressed: (int index) {
              if (index == 0) {
                context.read<InspectCubit>().disableSync();
              } else {
                context.read<InspectCubit>().enableSync();
              }
            },
            isSelected: _getIsSelectedList(state.realtimeSyncState),
            children: const [
              Tooltip(
                message: 'Disable sync',
                child: Icon(Icons.sync_disabled),
              ),
              Tooltip(
                message: 'Sync every 20s',
                child: Icon(Icons.sync),
              ),
            ],
          ),
        );
      },
    );
  }

  List<bool> _getIsSelectedList(RealtimeSyncState realtimeSyncState) {
    switch (realtimeSyncState) {
      case RealtimeSyncState.disabled:
        return [true, false];
      case RealtimeSyncState.syncing:
        return [false, true];
    }
  }
}
