import 'package:esp/bloc/cubit/dashboard_cubit.dart';
import 'package:esp/component/Color.dart';
import 'package:esp/router/AppRouter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../component/gradient_progressbar.dart';

class DashboardScreen extends StatelessWidget {
  var dashboardCubit =  DashboardCubit();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: dashboardCubit,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                // Logo icon
                Icon(Icons.water_drop, color: Colors.white),

                const SizedBox(width: 8),

                // App name
                const Text(
                  'SmartSip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Container(
              color: AppColors.greyFE,
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xFF6366F1),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'You are successfully logged in',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Water Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '80%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GradientProgressBar(value: 0.8,),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              children: [
                                const TextSpan(text: 'Your daily goal is '),
                                TextSpan(
                                  text: '2000ml',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6366F1), // primary color
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      _buildActionCard('Profile', Icons.person, () {}),
                      _buildActionCard('Start tracking', Icons.track_changes, () {
                        Navigator.pushNamed(context, AppRouter.trackingScreen);
                      }),
                      _buildActionCard('Set Reminder', Icons.alarm, () {
                        Navigator.pushNamed(context, AppRouter.setReminderScreen);
                      }),
                      _buildActionCard('Analytics', Icons.analytics, () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Color(0xFF6366F1)),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                dashboardCubit.logout();
                Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}