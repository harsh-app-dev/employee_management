import 'package:employee_management/core/configs/strings.dart';
import 'package:flutter/material.dart';
import 'package:employee_management/features/presentation/screens/punch_history_screen.dart';
import 'package:employee_management/features/presentation/screens/task_history_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.history,
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary,),
        ),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
          tabs: [
            Tab(
              icon: Icon(Icons.access_time, size: 24),
              text: AppStrings.punchHistory,
            ),
            Tab(
              icon: Icon(Icons.assignment_turned_in, size: 24),
              text: AppStrings.taskHistory,
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: TabBarView(
        controller: _tabController,
        children: [
          PunchHistoryScreen(),
          TaskHistoryScreen(),
        ],
      ),
    );
  }
} 