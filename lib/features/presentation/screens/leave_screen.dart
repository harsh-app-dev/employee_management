import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/utils/util.dart';
import '../../data/models/leave/leave_response.dart';
import '../../../core/widgets/app_side_drawer.dart';
import 'package:employee_management/core/widgets/document_web_viewer.dart';
import 'package:employee_management/features/data/models/leave/leave_type.dart';
import 'package:employee_management/features/data/models/leave/role_user.dart';
import 'package:employee_management/features/data/repositories/leave_repository.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import '../../data/models/leave/leave_balance_response.dart';
import 'LeaveRequestTab.dart';
import 'leave_application_form.dart';

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
  List<LeaveBalance> _leaveBalances = [];
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
    _fetchLeaveBalance();
  }

  void _fetchLeaveTypes() async {
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchLeaveTypes();

    if (result is NetworkSuccess<List<LeaveType>>) {
      setState(() {
        _leaveTypes = result.data;
        _isLoadingLeaveTypes = false;
      });
    } else {
      setState(() {
        _isLoadingLeaveTypes = false;
      });
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
  Future<void> _fetchLeaveBalance() async {
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchLeaveBalance();

    if (result is NetworkSuccess<List<LeaveBalance>>) {
      setState(() {
        _leaveBalances = result.data;
      });
    }
  }


  void _initializeEvents() {
    _events.clear();
    for (var leave in _leaveRequests) {
      for (int i = 0; i < leave.totalDays; i++) {
        final date = leave.fromDateTime.add(Duration(days: i));
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
      _leaveRequests.insert(0, request);
      print('Leave added: ${request.leaveType}, total: ${_leaveRequests.length}');
      _initializeEvents();
    });
  }

  List<LeaveResponse> get _filteredLeaveRequests {
    final filtered = _leaveRequests.where((leave) {
      bool statusMatch = _selectedStatusFilter == 'All' || leave.status == _selectedStatusFilter;
      bool typeMatch = _selectedTypeFilter == 'All' || leave.leaveTypeName == _selectedTypeFilter;
      bool dateMatch = _selectedDateFilter == null || (
          leave.fromDateTime.isAfter(_selectedDateFilter!.start.subtract(const Duration(days: 1))) &&
              leave.toDateTime.isBefore(_selectedDateFilter!.end.add(const Duration(days: 1)))
      );
      if (!(statusMatch && typeMatch && dateMatch)) {
        print('Filtered out leave: id=${leave.id}, type=${leave.leaveTypeName}, status=${leave.status}, from=${leave.fromDate}, to=${leave.toDate}');
      }
      return statusMatch && typeMatch && dateMatch;
    }).toList();
    print('Filtered leaves count: ${filtered.length}');
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

          tabController.addListener(() {
            if (mounted) setState(() {});
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeaveBalanceSection(),
                      const SizedBox(height: 8),
                      _buildFilterSection(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildLeaveHistoryList(),),
                    ],
                  ),
                  LeaveRequestTab(),
                ],
              ),
              floatingActionButton: tabController.index == 0
                ? FloatingActionButton(
              onPressed: () => _showLeaveApplicationBottomSheet(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.add, size: 28),
            ) : null,
          );
        },
      ),
    );
  }

  Widget _buildLeaveBalanceSection() {
    bool _showAllLeaves = false;

    return StatefulBuilder(
      builder: (context, setState) {
        if (_leaveBalances.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            color: Colors.white,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No Data Found', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),),
              ),
            ),
          );
        }

        // Initially only show Casual and Short Leave
        final visibleLeaves = _showAllLeaves
            ? _leaveBalances
            : _leaveBalances.where((leave) =>
        leave.leaveTypeName.toLowerCase() == 'casual leave' || leave.leaveTypeName.toLowerCase() == 'short leave').toList();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: visibleLeaves.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    final leave = visibleLeaves[index];

                    IconData icon;
                    Color color;

                    switch (leave.leaveTypeName.toLowerCase()) {
                      case 'casual leave':
                        icon = Icons.beach_access;
                        color = Colors.green;
                        break;
                      case 'short leave':
                        icon = Icons.timer;
                        color = Colors.orange;
                        break;
                      case 'wedding leave':
                        icon = Icons.favorite;
                        color = Colors.pink;
                        break;
                      case 'maternity leave':
                        icon = Icons.pregnant_woman;
                        color = Colors.red;
                        break;
                      case 'paternity leave':
                        icon = Icons.child_friendly;
                        color = Colors.teal;
                        break;
                      case 'bereavement leave':
                        icon = Icons.sentiment_dissatisfied;
                        color = Colors.purple;
                        break;
                      default:
                        icon = Icons.calendar_today;
                        color = Colors.blueGrey;
                    }

                    return _cleanBalanceItem(icon, leave.leaveTypeName, num.tryParse(leave.balance)?.toInt() ?? 0, num.tryParse(leave.totalLeaves)?.toInt() ?? 0, color,);
                  },
                ),

                const SizedBox(height: 2),
                if (_leaveBalances.length > 2)
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
                      ),
                      onPressed: () {
                        setState(() => _showAllLeaves = !_showAllLeaves);
                      },
                      icon: Icon(_showAllLeaves ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.black87,),
                      label: Text(
                        _showAllLeaves ? "Show Less" : "Show More",
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500,),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close),),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 16),
                    child: LeaveApplicationForm(
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Status', style: TextStyle(fontSize: 14, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,),
                        ),
                        value: _selectedStatusFilter,
                        items: ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'].map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(item, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,),
                          ),
                        )).toList(),
                        selectedItemBuilder: (context) {
                          return ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'].map(
                                (item) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(item, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,),
                            ),
                          ).toList();
                        },
                        onChanged: (value) {setState(() {_selectedStatusFilter = value!;});},
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
                    decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const SizedBox(
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Leave Type', style: TextStyle(fontSize: 14, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,),
                          ),
                        ),
                        value: _selectedTypeFilter,
                        items: ['All', ..._leaveTypes.map((e) => e.name)].map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: SizedBox(
                              width: double.infinity,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(type, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,),
                              ),
                            ),
                          ),
                        ).toList(),
                        selectedItemBuilder: (context) {
                          return ['All', ..._leaveTypes.map((e) => e.name)].map((type) => SizedBox(
                              width: double.infinity,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(type, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.start,),
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
                          text: _selectedDateFilter == null ? 'Select date range' : '${DateFormat('dd MMM yyyy').format(_selectedDateFilter!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateFilter!.end)}',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        backgroundColor: getStatusColor(leave.status).withValues(alpha: 0.13),
                        radius: 18,
                        child: Icon(getLeaveTypeIcon(leave.leaveTypeName), color: getStatusColor(leave.status), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(leave.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              '${leave.fromDate} - ${leave.toDate}\n(${leave.totalDays.toStringAsFixed(1)} day${leave.totalDays != 1 ? 's' : ''})',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            if (leave.managerDetails != null && leave.managerDetails.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.group, size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        leave.managerDetails.map((m) => '${m.firstName} ${m.lastName}').join(', '),
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      buildStatusIndicator(leave.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(child: Icon(Icons.expand_more, color: Colors.grey, size: 22)),
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
        final isEditable = !leave.fromDateTime.isBefore(DateTime.now()) && leave.status != "Cancelled";
        if (isEditable) {
          // Editable leave bottom sheet
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
                    Container(
                      margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
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
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close),),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            LeaveApplicationForm(
                              leaveTypes: _leaveTypes.map((e) => e.name).toList(),
                              leaveTypeObjects: _leaveTypes,
                              hrList: _hrList,
                              managerList: _managerList,
                              existingLeaveRequests: _leaveRequests,
                              onLeaveSubmitted: (request, {casualDeduct = 0, sickDeduct = 0, shortDeduct = 0}) {
                                setState(() {
                                  _leaveRequests[index] = request;
                                  _initializeEvents();
                                });
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
                                onPressed: leave.status == 'Cancelled'
                                    ? null : () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                    const Center(child: CircularProgressIndicator()),
                                  );
                                  final leaveRepository = getIt<LeaveRepository>();
                                  final result = await leaveRepository.withdrawLeave(leave.id);
                                  Navigator.of(context, rootNavigator: true).pop(); // Hide loader
                                  if (result is NetworkSuccess) {
                                    setState(() {
                                      _leaveRequests[index] = LeaveResponse(
                                        id: leave.id,
                                        leaveType: leave.leaveType,
                                        leaveTypeName: leave.leaveTypeName,
                                        fromTime: leave.fromTime,
                                        toTime: leave.toTime,
                                        fromDate: leave.fromDate,
                                        toDate: leave.toDate,
                                        appliedDate: leave.appliedDate,
                                        managers: leave.managers,
                                        hr: leave.hr,
                                        reason: leave.reason,
                                        status: 'Cancelled',
                                        attachment: leave.attachment,
                                        managerDetails: leave.managerDetails,
                                        userDetails: leave.userDetails,
                                        managerComment: leave.managerComment,
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
                                  backgroundColor: leave.status == 'Cancelled' ? Colors.grey : Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),),
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
        // Non-editable leave bottom sheet
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2),),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(getLeaveTypeIcon(leave.leaveTypeName), color: getStatusColor(leave.status), size: 28,),
                          const SizedBox(width: 10),
                          Text(leave.leaveTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                          const Spacer(),
                          buildStatusIndicator(leave.status),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context),),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Date Range:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatLeaveDateRange(leave)),
                      // Show time for Half Day or Short Leave
                      if (leave.leaveTypeName.toLowerCase().contains('short')) ...[
                        const SizedBox(height: 16),
                        const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatLeaveTimeFromTimestamp(
                            int.tryParse(leave.fromTime ?? ''),
                            int.tryParse(leave.toTime ?? ''),
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],


                      if (leave.leaveTypeName.toLowerCase().contains('half')) ...[
                        const SizedBox(height: 16),
                      Text('Time:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        formatLeaveTimeFromTimestamp(int.tryParse(leave.fromTime ?? ''), int.tryParse(leave.toTime ?? '')),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],

                      const SizedBox(height: 10),
                      Text('Reason:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(leave.reason),
                      const SizedBox(height: 10),
                      Text('Applied Date:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(leave.appliedDate),
                      const SizedBox(height: 10),
                      if (leave.attachment != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attachment:', style: const TextStyle(fontWeight: FontWeight.bold)),
                            DocumentWebViewer(filePath: leave.attachment!),
                            const SizedBox(height: 10),
                          ],
                        ),
                      Text('HR:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(leave.hr),
                      const SizedBox(height: 10),
                      Text('Managers:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        leave.managerDetails.isNotEmpty
                            ? leave.managerDetails.map((m) => '${m.firstName} ${m.lastName}').join(', ')
                            : 'No manager assigned',
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manager Comment:', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(leave.managerComment.join(', ')),
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

// --- Helper to format timestamp in seconds ---
  String formatLeaveTimeFromTimestamp(int? from, [int? to, bool isShortLeave = true]) {
    if (from == null) return 'Time: Not available';

    DateTime fromTime = DateTime.fromMillisecondsSinceEpoch(from * 1000, isUtc: true).toLocal();
    String fromStr = DateFormat('hh:mm a').format(fromTime);

    if (isShortLeave && to != null) {
      DateTime toTime = DateTime.fromMillisecondsSinceEpoch(to * 1000, isUtc: true).toLocal();
      String toStr = DateFormat('hh:mm a').format(toTime);
      return '$fromStr to $toStr';
    }

    return fromStr;
  }

// --- Helper to format full date range ---
  String _formatLeaveDateRange(LeaveResponse leave) {
    return '${leave.fromDate} - ${leave.toDate}';
  }
}
/// Helper extension for LeaveResponse
extension LeaveResponseHelpers on LeaveResponse {
  DateTime get fromDateTime => DateTime.parse(fromDate);
  DateTime get toDateTime => DateTime.parse(toDate);
  int get totalDays => fromDateTime.difference(toDateTime).inDays.abs() + 1;
}
