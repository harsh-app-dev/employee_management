import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/utils/util.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../data/models/leave/leave_response.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:employee_management/core/widgets/document_web_viewer.dart';
import 'package:employee_management/features/data/models/leave/leave_type.dart';
import 'package:employee_management/features/data/models/leave/role_user.dart';
import 'package:employee_management/features/data/repositories/leave_repository.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/features/data/models/leave/leave_apply_request.dart';
import 'dart:io';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveType> _leaveTypes = [];
  List<RoleUser> _hrList = [];
  List<RoleUser> _managerList = [];
  bool _isLoadingLeaveTypes = true;
  bool _isLoadingRoles = true;
  double _casualUsed = 3;
  int _shortUsed = 0;
  final double _casualTotal = 12;
  final int _shortTotal = 1;
  final List<LeaveResponse> _leaveRequests = [];
  Map<DateTime, List<LeaveResponse>> _events = {};
  String _selectedStatusFilter = 'All';
  String _selectedTypeFilter = 'All';
  DateTimeRange? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    _fetchLeaveTypes();
    _fetchUsersByRole();
    _fetchLeaveHistory();
  }

  void _fetchLeaveTypes() async {
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchLeaveTypes();
    if (result is NetworkSuccess<Map<String, dynamic>>) {
      setState(() {
        _leaveTypes = result.data['leaveTypes'];
        _isLoadingLeaveTypes = false;
      });
    } else {
      setState(() {_isLoadingLeaveTypes = false;});
    }
  }

  void _fetchUsersByRole() async {
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchUsersByRole();
    if (result is NetworkSuccess<Map<String, List<RoleUser>>>) {
      setState(() {
        _hrList = result.data['hr'] ?? [];
        _managerList = result.data['manager'] ?? [];
        _isLoadingRoles = false;
      });
    } else {
      setState(() {_isLoadingRoles = false;});
    }
  }

  Future<void> _fetchLeaveHistory() async {
    setState(() {});
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchLeaveApplications();
    if (result is NetworkSuccess<List<LeaveResponse>>) {
      setState(() {
        _leaveRequests.clear();
        _leaveRequests.addAll(result.data);
        _initializeEvents();
      });
    } else if (result is NetworkError) {
      setState(() {
      });
    }
  }

  void _initializeEvents() {
    _events.clear();
    for (var leave in _leaveRequests) {
      for (int i = 0; i <= leave.dateRange.duration.inDays; i++) {
        final date = leave.dateRange.start.add(Duration(days: i));
        if (_events[date] == null) _events[date] = [];
        _events[date]!.add(leave);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addLeaveRequest(LeaveResponse request, {double casualDeduct = 0, int sickDeduct = 0, int shortDeduct = 0}) {
    setState(() {
      _leaveRequests.insert(0, request.copyWith(isNewlyApplied: true));
      print('Leave added: ${request.leaveType}, total: ${_leaveRequests.length}');
      _casualUsed += casualDeduct;
      _shortUsed += shortDeduct;
      _initializeEvents();
    });
  }

  List<LeaveResponse> get _filteredLeaveRequests {
    final filtered = _leaveRequests.where((leave) {
      bool statusMatch = _selectedStatusFilter == 'All' || leave.status == _selectedStatusFilter;
      bool typeMatch = _selectedTypeFilter == 'All' || leave.leaveTypeName == _selectedTypeFilter;
      bool dateMatch = _selectedDateFilter == null || (
          leave.dateRange.start.isAfter(_selectedDateFilter!.start.subtract(const Duration(days: 1))) &&
              leave.dateRange.end.isBefore(_selectedDateFilter!.end.add(const Duration(days: 1)))
      );
      return statusMatch && typeMatch && dateMatch;
    }).toList();
    print('Filtered leaves: ${filtered.length}');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLeaveTypes || _isLoadingRoles) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);

          // 👇 Attach listener once
          tabController.addListener(() {
            if (mounted) setState(() {}); // rebuild when tab changes
          });

          return Scaffold(
            drawer: AppSideDrawer(),
            appBar: AppBar(
              title: const Text(
                'Leave Management',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 1,
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.history), text: 'My Leaves'),
                  Tab(icon: Icon(Icons.approval), text: 'Leave Requests'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 4,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              ),
            ),
            backgroundColor: const Color(0xFFF5F7FA),
            body: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeaveBalanceSection(),
                      const SizedBox(height: 8),
                      _buildFilterSection(),
                      const SizedBox(height: 8),
                      SizedBox(height: 500, child: _buildLeaveHistoryList()),
                    ],
                  ),
                ),
                _StaticLeaveRequestTab(),
              ],
            ),
            floatingActionButton: tabController.index == 0
                ? FloatingActionButton(
              onPressed: () => _showLeaveApplicationBottomSheet(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.add, size: 28),
            )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLeaveBalanceSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _cleanBalanceItem(Icons.beach_access, 'Casual', _casualUsed, _casualTotal, Colors.green),
            _cleanBalanceItem(Icons.timelapse, 'Short', _shortUsed, _shortTotal, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _cleanBalanceItem(IconData icon, String label, num used, num total, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text('$used/$total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  void _showLeaveApplicationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2),),),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      const Text('Apply for Leave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 16),
                    child: _LeaveApplicationForm(
                      leaveTypes: _leaveTypes.map((e) => e.name).toList(),
                      leaveTypeObjects: _leaveTypes,
                      hrList: _hrList,
                      managerList: _managerList,
                      existingLeaveRequests: _leaveRequests,
                      onLeaveSubmitted: (request, {casualDeduct = 0, sickDeduct = 0, shortDeduct = 0}) {
                        _addLeaveRequest(request, casualDeduct: casualDeduct, sickDeduct: sickDeduct, shortDeduct: shortDeduct);
                        Navigator.pop(context);
                      },
                      onSubmissionSuccess: _fetchLeaveHistory,
                    ),
                  ),
                ), const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Status',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        value: _selectedStatusFilter,
                        items: ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'].map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        )).toList(),
                        selectedItemBuilder: (context) {
                          return ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'].map(
                                (item) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ).toList();
                        },
                        onChanged: (value) {
                          setState(() {_selectedStatusFilter = value!;});
                        },
                        buttonStyleData: const ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 30, width: double.infinity,),
                        iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down), iconSize: 24,),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 400,
                          width: 180,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white, border: Border.all(color: Colors.grey),),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Leave Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const SizedBox(
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Leave Type',
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ),
                        value: _selectedTypeFilter,
                        items: ['All', ..._leaveTypes.map((e) => e.name)].map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: SizedBox(
                              width: double.infinity,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  type,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                        selectedItemBuilder: (context) {
                          return ['All', ..._leaveTypes.map((e) => e.name)].map((type) => SizedBox(
                              width: double.infinity,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  type,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ).toList();
                        },
                        onChanged: (value) {
                          setState(() {_selectedTypeFilter = value!;});
                        },
                        buttonStyleData: const ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 30, width: double.infinity,),
                        iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down), iconSize: 24,),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 400,
                          width: 180,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white, border: Border.all(color: Colors.grey),),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatusFilter = 'All';
                      _selectedTypeFilter = 'All';
                      _selectedDateFilter = null;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 22),
                  tooltip: 'Clear All',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {_selectedDateFilter = picked;});
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date Range',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        controller: TextEditingController(
                          text: _selectedDateFilter == null ? 'Select date range'
                              : '${DateFormat('dd MMM yyyy').format(_selectedDateFilter!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateFilter!.end)}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistoryList() {
    final filteredRequests = _filteredLeaveRequests;
    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No leave requests found.', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: filteredRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final leave = filteredRequests[index];
        return GestureDetector(
          onTap: () => _showLeaveDetailBottomSheet(leave, index),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: _getStatusColor(leave.leaveType).withValues(alpha: 0.13),
                        radius: 18,
                        child: Icon(_getLeaveTypeIcon(leave.leaveTypeName), color: _getStatusColor(leave.leaveType), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(leave.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(leave.dateRange.start)} - '
                                  '${DateFormat('dd MMM yyyy').format(leave.dateRange.end)}\n'
                                  '(${leave.totalDays.toStringAsFixed(1)} day${leave.totalDays != 1 ? 's' : ''})',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildStatusIndicator(leave.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(child: Icon(Icons.expand_more, color: Colors.grey, size: 22),),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLeaveDetailBottomSheet(LeaveResponse leave, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      builder: (context) {
        // final isEditable = leave.status == 'Pending';
        final isEditable = !leave.dateRange.start.isBefore(DateTime.now());
        if (isEditable) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
                child: Column(
                  children: [
                    Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2),),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.blue, size: 24),
                          const SizedBox(width: 8),
                          const Text('Edit Leave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _LeaveApplicationForm(
                              leaveTypes: _leaveTypes.map((e) => e.name).toList(),
                              leaveTypeObjects: _leaveTypes,
                              hrList: _hrList,
                              managerList: _managerList,
                              existingLeaveRequests: _leaveRequests,
                              onLeaveSubmitted: (request, {casualDeduct = 0, sickDeduct = 0, shortDeduct = 0}) {

                                setState(() {_leaveRequests[index] = request;_initializeEvents();});

                                Navigator.pop(context);
                                showGlobalSnackBar('Leave request updated successfully!');
                              },
                              onSubmissionSuccess: _fetchLeaveHistory,
                              initialLeave: leave,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: leave.status == 'Cancelled' ? null : () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(child: CircularProgressIndicator()),
                                  );
                                  final leaveRepository = getIt<LeaveRepository>();
                                  final result = await leaveRepository.withdrawLeave(leave.id);
                                  Navigator.of(context, rootNavigator: true).pop(); // Hide loader
                                  if (result is NetworkSuccess) {
                                    setState(() {
                                      _leaveRequests[index] = LeaveResponse(
                                        id: leave.id,
                                        dateRange: leave.dateRange,
                                        leaveType: leave.leaveType,
                                        reason: leave.reason,
                                        attachmentPath: leave.attachmentPath,
                                        hr: leave.hr,
                                        teamLead: leave.teamLead,
                                        status: 'Cancelled',
                                        appliedDate: leave.appliedDate,
                                        managerComment: leave.managerComment,
                                        processedDate: DateTime.now(),
                                        totalDays: leave.totalDays,
                                        leaveTypeName: leave.leaveTypeName,
                                      );
                                      _initializeEvents();
                                    });
                                    Navigator.pop(context);
                                    showGlobalSnackBar('Leave request withdrawn.');
                                  } else if (result is NetworkError) {
                                    showGlobalSnackBar('Failed to withdraw leave: ${result.message}');
                                  }
                                },
                                icon: const Icon(Icons.cancel),
                                label: Text(
                                  leave.status == 'Cancelled' ? 'Already Withdrawn' : 'Withdraw Leave',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: leave.status == 'Cancelled' ? Colors.grey : Colors.red, foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ), const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding( padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2),),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(_getLeaveTypeIcon(leave.leaveTypeName), color: _getStatusColor(leave.leaveType), size: 28),
                          const SizedBox(width: 10),
                          Text(leave.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),

                          const Spacer(),
                          _buildStatusIndicator(leave.status),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context),),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${DateFormat('dd MMM yyyy').format(leave.dateRange.start)} - ${DateFormat('dd MMM yyyy').format(leave.dateRange.end)}'),
                      const SizedBox(height: 10),
                      if (leave.leaveTypeName == 'Half Day Leave' && leave.halfDayType != null) ...[
                        Text('Half Day:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(leave.halfDayType!),
                        const SizedBox(height: 10),
                      ],
                      if (leave.leaveTypeName == 'Short Leave' && leave.shortLeaveTime != null) ...[
                        Text('Short Leave Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(leave.shortLeaveTime!),
                        const SizedBox(height: 10),
                      ],
                      Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(leave.reason),
                      const SizedBox(height: 10),
                      if (leave.attachmentPath != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attachment:', style: TextStyle(fontWeight: FontWeight.bold)),
                            DocumentWebViewer(filePath: leave.attachmentPath!),
                            const SizedBox(height: 10),
                          ],
                        ),
                      Text('HR:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(leave.hr),
                      const SizedBox(height: 10),
                      Text('Team Lead:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(leave.teamLead),
                      const SizedBox(height: 10),
                      Text('Applied Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd MMM yyyy').format(leave.appliedDate)),
                      const SizedBox(height: 10),
                      if (leave.managerComment != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manager Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(leave.managerComment!),
                            const SizedBox(height: 10),
                          ],
                        ),
                      if (leave.processedDate != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Processed Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(DateFormat('dd MMM yyyy').format(leave.processedDate!)),
                            const SizedBox(height: 10),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500,),),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getLeaveTypeIcon(String type) {
    switch (type) {
      case 'Sick Leave':
      case 'Medical Leave':
        return Icons.sick;
      case 'Casual Leave':
        return Icons.beach_access;
      case 'Half Day Leave':
        return Icons.wb_sunny;
      case 'Short Leave':
        return Icons.timelapse;
      case 'Emergency Leave':
        return Icons.warning_amber_rounded;
      case 'Maternity Leave':
        return Icons.pregnant_woman;
      case 'Paternity Leave':
        return Icons.family_restroom;
      case 'Wedding Leave':
        return Icons.favorite;
      case 'Bereavement Leave':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.category;
    }
  }

}

class _LeaveApplicationForm extends StatefulWidget {
  final List<String> leaveTypes;
  final List<LeaveType> leaveTypeObjects;
  final List<RoleUser> hrList;
  final List<RoleUser> managerList;
  final List<LeaveResponse> existingLeaveRequests;
  final Function(LeaveResponse, {double casualDeduct, int sickDeduct, int shortDeduct}) onLeaveSubmitted;
  final VoidCallback onSubmissionSuccess;
  final LeaveResponse? initialLeave;
  const _LeaveApplicationForm({
    required this.leaveTypes,
    required this.leaveTypeObjects,
    required this.hrList,
    required this.managerList,
    required this.existingLeaveRequests,
    required this.onLeaveSubmitted,
    required this.onSubmissionSuccess,
    this.initialLeave,
  });

  @override
  State<_LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<_LeaveApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedLeaveType;
  String? _selectedHR;
  List<RoleUser> _selectedManagers = [];
  DateTimeRange? _dateRange;
  String? _attachmentPath;
  bool _isSubmitting = false;
  TimeOfDay? _shortLeaveStartTime;
  TimeOfDay? _shortLeaveEndTime;
  String? _selectedHalf;

  int get _totalDays {
    if (_dateRange == null) return 0;
    return _dateRange!.duration.inDays + 1;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLeave != null) {
      _selectedLeaveType = widget.initialLeave!.leaveTypeName;
      _selectedHR = widget.initialLeave!.hr;
      final initialManager = widget.managerList.firstWhere(
            (m) => m.fullName == widget.initialLeave!.teamLead,
        orElse: () => widget.managerList.first,
      );
      _selectedManagers = [initialManager];
      _dateRange = widget.initialLeave!.dateRange;
      _attachmentPath = widget.initialLeave!.attachmentPath;
      _reasonController.text = widget.initialLeave!.reason;
      _shortLeaveStartTime = TimeOfDay.fromDateTime(widget.initialLeave!.dateRange.start);
      _shortLeaveEndTime = TimeOfDay.fromDateTime(widget.initialLeave!.dateRange.start.add(const Duration(hours: 2)));
      if (_selectedLeaveType == 'Half Day Leave' && widget.initialLeave!.halfDayType != null) {
        if (widget.initialLeave!.halfDayType == 'FH') {
          _selectedHalf = 'First Half';
        } else if (widget.initialLeave!.halfDayType == 'SH') {
          _selectedHalf = 'Second Half';
        }
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() {_attachmentPath = result.files.single.path;});
      }
    } catch (e) {
      showGlobalSnackBar('Error picking file: $e');
    }
  }

  void _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') && _dateRange!.start != _dateRange!.end) {
      showGlobalSnackBarOverlay('Short Leave and Half Day can only be applied for a single day.');
      return;
    }

    final currentLeaveId = widget.initialLeave?.id;

    for (final existingLeave in widget.existingLeaveRequests) {
      if (currentLeaveId != null && existingLeave.id == currentLeaveId) {
        continue;
      }
      if (_dateRange!.start.isBefore(existingLeave.dateRange.end.add(const Duration(days: 1))) &&
          _dateRange!.end.isAfter(existingLeave.dateRange.start.subtract(const Duration(days: 1)))) {
        showGlobalSnackBarOverlay('Leave request already exists for the selected date range. Please choose different dates.');
        return;
      }
    }

    /*  change the above for loop for this to manage for apply future and current date in the case of half day

    for (final existingLeave in widget.existingLeaveRequests) {
      if (currentLeaveId != null && existingLeave.id == currentLeaveId) {
        continue; // Skip leave being edited
      }

      if (DateUtils.isSameDay(_dateRange!.start, existingLeave.dateRange.start)) {
        final newIsHalfDay = _selectedLeaveType == 'Half Day Leave';

        // ✅ Derive half-day status from leaveTypeName or halfDayType
        final existingIsHalfDay = existingLeave.leaveTypeName == 'Half Day Leave';
        final existingHalf = existingLeave.halfDayType; // 'FH' or 'SH'

        // ❌ Full-day case — block
        if (!newIsHalfDay || !existingIsHalfDay) {
          showGlobalSnackBarOverlay('A leave already exists for this date.');
          return;
        }

        // ✅ Both half-day — check halves
        if ((_selectedHalf == 'First Half' && existingHalf == 'FH') ||
            (_selectedHalf == 'Second Half' && existingHalf == 'SH')) {
          showGlobalSnackBarOverlay('You have already applied for this half on this date.');
          return;
        }
        // Opposite half → allowed
      }
    }*/

    setState(() {_isSubmitting = true;});

    final selectedLeaveType = widget.leaveTypeObjects.firstWhere((t) => t.name == _selectedLeaveType);
    final selectedHr = widget.hrList.firstWhere((hr) => hr.fullName == _selectedHR);
    final selectedManagerIds = _selectedManagers.map((m) => m.id).toList();

    final request = LeaveApplyRequest(
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      hrId: selectedHr.id,
      managerIds: selectedManagerIds,
      leaveTypeId: selectedLeaveType.id.toString(),
      reason: _reasonController.text.trim(),
      attachment: _attachmentPath != null ? File(_attachmentPath!) : null,
      isHalfDay: _selectedLeaveType == 'Half Day Leave',
      halfDaySession: _selectedHalf == 'First Half' ? 'FH' : _selectedHalf == 'Second Half' ? 'SH' : null,
      startTime: _shortLeaveStartTime != null ? '${_shortLeaveStartTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveStartTime!.minute.toString().padLeft(2, '0')}' : null,
      endTime: _shortLeaveEndTime != null ? '${_shortLeaveEndTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveEndTime!.minute.toString().padLeft(2, '0')}' : null,
    );

    final repo = getIt<LeaveRepository>();
    final result = await repo.applyLeave(request);

    setState(() {_isSubmitting = false;});

    if (result is NetworkSuccess) {
      widget.onSubmissionSuccess();
      showGlobalSnackBar('Leave application submitted successfully!');
      Navigator.pop(context);
    } else if (result is NetworkError) {
      showGlobalSnackBar('Error: ${result.message}');
    }
  }

  @override
  Widget build(BuildContext context) {

    final Debouncer submitDebouncer = Debouncer(delay: Duration(seconds: 2));

    final uniqueLeaveTypes = widget.leaveTypes.toSet().toList();
    if (_selectedLeaveType != null && !uniqueLeaveTypes.contains(_selectedLeaveType)) {
      _selectedLeaveType = null;
    }
    final uniqueHRs = widget.hrList.map((hr) => hr.fullName).toSet().toList();
    if (_selectedHR != null && !uniqueHRs.contains(_selectedHR)) {
      _selectedHR = null;
    }
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField2<String>(
            decoration: const InputDecoration(
              labelText: 'Leave Type *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            value: _selectedLeaveType,
            hint: const Text('Select Leave Type', style: TextStyle(fontSize: 14, color: Colors.black54), overflow: TextOverflow.ellipsis,),
            items: uniqueLeaveTypes.map((type) => DropdownMenuItem<String>(
                value: type,
                child: Text(type, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis,),
              ),
            ).toList(),
            onChanged: (value) {
              setState(() {
                final wasSingleDay = _selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave';
                final isSingleDay = value == 'Short Leave' || value == 'Half Day Leave';
                if (wasSingleDay != isSingleDay) {
                  _dateRange = null;
                }
                _selectedLeaveType = value;
                if (value != 'Half Day Leave') _selectedHalf = null;
              });
            },
            validator: (value) =>
            value == null || value.isEmpty ? 'Please select leave type' : null,
            buttonStyleData: const ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 30, width: double.infinity,),
            iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down), iconSize: 24,),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white, border: Border.all(color: Colors.grey),),
            ),
          ),
          if (_selectedLeaveType == 'Half Day Leave') ...[
            const SizedBox(height: 10),
            FormField<String>(
              validator: (value) {
                if (_selectedLeaveType == 'Half Day Leave' && (_selectedHalf == null || _selectedHalf!.isEmpty)) {
                  return 'Please select which half for Half Day leave';
                }
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'First Half',
                              groupValue: _selectedHalf,
                              onChanged: (value) {setState(() => _selectedHalf = value); field.didChange(value);},
                            ),
                            const Text('First Half', style: TextStyle(fontSize: 16),),
                          ],
                        ),
                        SizedBox(width: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'Second Half',
                              groupValue: _selectedHalf,
                              onChanged: (value) {setState(() => _selectedHalf = value); field.didChange(value);},
                            ),
                            const Text('Second Half',style: TextStyle(fontSize: 16),),
                          ],
                        ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child: Text(field.errorText ?? '', style: const TextStyle(color: Colors.red, fontSize: 12),),
                      ),
                  ],
                );
              },
            ),
          ],
          if (_selectedLeaveType == 'Short Leave') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _shortLeaveStartTime ?? TimeOfDay.now(),);
                if (picked != null) {
                  setState(() {
                    _shortLeaveStartTime = picked;
                    _shortLeaveEndTime = TimeOfDay(hour: (picked.hour + 2) % 24, minute: picked.minute);
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Short Leave Start Time *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  controller: TextEditingController(text: _shortLeaveStartTime == null ? 'Select start time' : _shortLeaveStartTime!.format(context),),
                  validator: (_) => _selectedLeaveType == 'Short Leave' && _shortLeaveStartTime == null ? 'Please select start time' : null,
                ),
              ),
            ),
            if (_shortLeaveEndTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('End Time: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_shortLeaveEndTime!.format(context), style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              if (_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateRange?.start ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {_dateRange = DateTimeRange(start: picked, end: picked);});
                }
              } else {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _dateRange,
                );
                if (picked != null) {
                  setState(() {_dateRange = picked;});
                }
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: (_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') ? 'Select date *' : 'Select date range *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.date_range),
                  suffixIcon: const Icon(Icons.calendar_today),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(
                  text: _dateRange == null
                      ? (_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave'? 'Select date': 'Select date range')
                      : (_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave'
                      ? DateFormat('dd MMM yyyy').format(_dateRange!.start)
                      : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}'),
                ),
                validator: (_) => _dateRange == null ? 'Please select date${(_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') ? '' : ' range'}' : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!),),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Total Days: $_totalDays', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),),
                ],
              ),
            ),
          if (_dateRange != null) const SizedBox(height: 12),

          DropdownButtonFormField2<String>(
            decoration: const InputDecoration(
              labelText: 'HR *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            value: _selectedHR,
            hint: const Text('Select HR', style: TextStyle(fontSize: 14, color: Colors.black54), overflow: TextOverflow.ellipsis,),
            items: uniqueHRs.map((hr) => DropdownMenuItem<String>(
                value: hr,
                child: Text(hr, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis,),
              ),
            ).toList(),
            onChanged: (value) => setState(() => _selectedHR = value),
            validator: (value) =>
            value == null || value.isEmpty ? 'Please select an HR' : null,
            buttonStyleData: const ButtonStyleData(padding: EdgeInsets.symmetric(horizontal: 10), height: 30, width: double.infinity,),
            iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down), iconSize: 24,),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white, border: Border.all(color: Colors.grey),),
            ),
          ),

          const SizedBox(height: 12),
          FormField<List<RoleUser>>(
            initialValue: _selectedManagers,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least one manager.';
              }
              return null;
            },
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton2(
                      isExpanded: true,
                      customButton: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Team Lead(s) *',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          errorText: field.errorText,
                        ),
                        child: Text(
                          _selectedManagers.isEmpty ? 'Select one or more managers' : _selectedManagers.map((e) => e.fullName).join(', '),
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white, border: Border.all(color: Colors.grey),),
                      ),
                      onChanged: (_) {},
                      items: widget.managerList.map((manager) {
                        return DropdownMenuItem(
                          value: manager,
                          child: StatefulBuilder(
                            builder: (context, setStateSB) {
                              final isSelected = _selectedManagers.any((m) => m.id == manager.id);
                              return CheckboxListTile(
                                dense: true,
                                value: isSelected,
                                title: Text(manager.fullName, style: const TextStyle(fontSize: 14)),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedManagers.add(manager);
                                    } else {
                                      _selectedManagers.removeWhere((m) => m.id == manager.id);
                                    }
                                    field.didChange(_selectedManagers);
                                  });
                                  setStateSB(() {});
                                },
                              );
                            },
                          ),
                        );
                      }).toList(),
                      iconStyleData: const IconStyleData(icon: Icon(Icons.arrow_drop_down), iconSize: 24,),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter reason' : null,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8),),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attachment (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Choose File', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8),),
                      ),
                    ),
                  ],
                ),
                if (_attachmentPath != null) ...[
                  const SizedBox(height: 10),
                  DocumentWebViewer(filePath: _attachmentPath!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () {
                submitDebouncer.run(() async {
                  if (widget.initialLeave != null) {
                    if (!_formKey.currentState!.validate()) return;
                    if ((_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') &&
                        _dateRange!.start != _dateRange!.end) {
                      showGlobalSnackBarOverlay('Short Leave and Half Day can only be applied for a single day.');
                      return;
                    }

                    setState(() {_isSubmitting = true;});

                    final selectedLeaveType =
                    widget.leaveTypeObjects.firstWhere((t) => t.name == _selectedLeaveType);
                    final selectedHr = widget.hrList.firstWhere((hr) => hr.fullName == _selectedHR);
                    final selectedManagerIds = _selectedManagers.map((m) => m.id).toList();

                    final request = LeaveApplyRequest(
                      startDate: _dateRange!.start,
                      endDate: _dateRange!.end,
                      hrId: selectedHr.id,
                      managerIds: selectedManagerIds,
                      leaveTypeId: selectedLeaveType.id.toString(),
                      reason: _reasonController.text.trim(),
                      attachment: _attachmentPath != null ? File(_attachmentPath!) : null,
                      isHalfDay: _selectedLeaveType == 'Half Day Leave',
                      halfDaySession: _selectedHalf == 'First Half' ? 'FH' : _selectedHalf == 'Second Half' ? 'SH' : null,
                      startTime: _shortLeaveStartTime != null ? "${_shortLeaveStartTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveStartTime!.minute.toString().padLeft(2, '0')}" : null,
                      endTime: _shortLeaveEndTime != null ? "${_shortLeaveEndTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveEndTime!.minute.toString().padLeft(2, '0')}" : null,
                    );

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final repo = getIt<LeaveRepository>();
                    final result = await repo.updateLeave(widget.initialLeave!.id, request);

                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() {_isSubmitting = false;});

                    if (result is NetworkSuccess) {
                      widget.onSubmissionSuccess();
                      showGlobalSnackBar('Leave request updated successfully!');
                      Navigator.pop(context);
                    } else if (result is NetworkError) {
                      showGlobalSnackBar('Error: ${result.message}');
                    }
                  } else {
                    _submitLeaveRequest();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting ? const SizedBox(height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
              ) : Text(
                widget.initialLeave != null ? 'Update Leave Request' : 'Submit Leave Request',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticLeaveRequestTab extends StatefulWidget {
  const _StaticLeaveRequestTab();

  @override
  State<_StaticLeaveRequestTab> createState() => _StaticLeaveRequestTabState();
}

class _StaticLeaveRequestTabState extends State<_StaticLeaveRequestTab> {
  final List<Map<String, String>> staticRequests = [
    {
      'name': 'John Doe',
      'type': 'Casual Leave',
      'date': '12 Sep 2025',
      'reason': 'Family function',
      'status': 'Pending',
    },
    {
      'name': 'Jane Smith',
      'type': 'Sick Leave',
      'date': '14 Sep 2025',
      'reason': 'Fever',
      'status': 'Pending',
    },
  ];

  void _updateStatus(int index, String newStatus) {
    setState(() {
      staticRequests[index]['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Leave $newStatus!"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: staticRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final req = staticRequests[index];
        final status = req['status']!;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header Row (Name + Status)
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      req['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _statusColor(status).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text('Type: ${req['type']}'),
                Text('Date: ${req['date']}'),
                Text('Reason: ${req['reason']}'),

                const SizedBox(height: 12),

                /// Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'Pending' || status == 'Rejected') ...[
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(index, 'Approved'),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(status == 'Rejected' ? 'Re-Approve' : 'Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (status == 'Pending' || status == 'Approved')
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(index, 'Rejected'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
