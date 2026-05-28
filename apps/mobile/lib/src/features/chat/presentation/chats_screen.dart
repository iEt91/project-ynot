import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/section_header.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedActivities = ref.watch(appStateProvider).activities.where((activity) {
      return activity.myStatus == ParticipantStatus.joinedPendingConfirmation ||
          activity.myStatus == ParticipantStatus.confirmed;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const SectionHeader(
          title: 'Temporal chats',
          subtitle: 'Sprint 1 reserves this space for the activity-based chat loop.',
        ),
        const SizedBox(height: 14),
        if (joinedActivities.isEmpty)
          const KawaiiCard(
            child: Text('Join and confirm an activity to unlock its temporary chat.'),
          )
        else
          ...joinedActivities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KawaiiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Chat will unlock for confirmed participants.'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
