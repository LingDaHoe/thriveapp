import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:thriveapp/features/activities/services/social_activity_service.dart';
import 'package:thriveapp/features/activities/models/social_activity.dart';

class SocialActivityReminder extends StatelessWidget {
  const SocialActivityReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final socialActivityService = SocialActivityService();
    
    return FutureBuilder<List<SocialActivity>>(
      future: socialActivityService.getUpcomingSocialActivities(days: 7),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final upcomingActivities = snapshot.data!;
        final nextActivity = upcomingActivities.first;
        
        final timeUntil = nextActivity.scheduledTime.difference(DateTime.now());
        final daysUntil = timeUntil.inDays;
        final hoursUntil = timeUntil.inHours;
        
        String timeText;
        if (daysUntil > 0) {
          timeText = '$daysUntil day${daysUntil == 1 ? '' : 's'}';
        } else if (hoursUntil > 0) {
          timeText = '$hoursUntil hour${hoursUntil == 1 ? '' : 's'}';
        } else {
          timeText = 'Today';
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00BCD4).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to activities screen - could be enhanced to go directly to social activities
              context.push('/activities');
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Social Activity',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00BCD4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextActivity.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM d, y • h:mm a').format(nextActivity.scheduledTime)} • In $timeText',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF00BCD4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


