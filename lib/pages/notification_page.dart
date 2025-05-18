import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Mark all as read'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Today's Notifications
              _buildSectionTitle('Today'),
              _buildNotificationItem(
                title: 'New Trip Alert',
                description: 'Your trip to Paris has been confirmed',
                time: '2 hours ago',
                icon: Icons.flight_takeoff,
                isUnread: true,
              ),
              _buildNotificationItem(
                title: 'Weather Update',
                description: 'Sunny weather expected at your destination',
                time: '5 hours ago',
                icon: Icons.wb_sunny,
                isUnread: true,
              ),
              
              const SizedBox(height: 24),
              
              // Yesterday's Notifications
              _buildSectionTitle('Yesterday'),
              _buildNotificationItem(
                title: 'Booking Successful',
                description: 'Your hotel booking has been confirmed',
                time: '1 day ago',
                icon: Icons.hotel,
                isUnread: false,
              ),
              _buildNotificationItem(
                title: 'Travel Tips',
                description: 'Check out our latest travel recommendations',
                time: '1 day ago',
                icon: Icons.tips_and_updates,
                isUnread: false,
              ),
              
              const SizedBox(height: 24),
              
              // This Week's Notifications
              _buildSectionTitle('This Week'),
              _buildNotificationItem(
                title: 'Price Drop Alert',
                description: 'Flights to Tokyo are now 20% off',
                time: '2 days ago',
                icon: Icons.local_offer,
                isUnread: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required bool isUnread,
  }) {
    return Dismissible(
      key: Key(title), // Use a unique key for each notification
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Handle notification dismissal
      },
      child: Card(
        elevation: 0,
        color: isUnread ? Colors.blue.shade50 : Colors.grey[50],
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnread ? Colors.blue.shade100 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isUnread ? Colors.blue : Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}