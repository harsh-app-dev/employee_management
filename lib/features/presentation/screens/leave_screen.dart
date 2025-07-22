import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/utils/util.dart';
import '../../data/models/leave/leave_response.dart';
import 'app_side_drawer.dart';
import 'package:employee_management/core/widgets/document_web_viewer.dart';
import 'package:employee_management/features/data/models/leave/leave_type.dart';
import 'package:employee_management/features/data/models/leave/role_user.dart';
import 'package:employee_management/features/data/repositories/leave_repository.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/features/data/models/leave/leave_apply_request.dart';
import 'dart:io';

class LeaveBalance {
  final String leaveType;
  final int total;
  final int used;
  final int remaining;
  final int carryForward;

  LeaveBalance({
    required this.leaveType,
    required this.total,
    required this.used,
    required this.remaining,
    required this.carryForward,
  });
}

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({Key? key}) : super(key: key);

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveType> _leaveTypes = [];
  List<HalfDayOption> _halfDayOptions = [];
  List<RoleUser> _hrList = [];
  List<RoleUser> _managerList = [];
  bool _isLoadingLeaveTypes = true;
  bool _isLoadingRoles = true;

  double _casualUsed = 3;
  int _shortUsed = 0;
  final double _casualTotal = 12;
  final int _shortTotal = 1;

  bool _isLoadingLeaveHistory = false;
  String? _leaveHistoryError;

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
    // _initializeEvents(); // now called after fetching
  }

  void _fetchLeaveTypes() async {
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchLeaveTypes();
    if (result is NetworkSuccess<Map<String, dynamic>>) {
      setState(() {
        _leaveTypes = result.data['leaveTypes'];
        _halfDayOptions = result.data['halfDayOptions'];
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
      setState(() {
        _isLoadingRoles = false;
      });
    }
  }

  Future<void> _fetchLeaveHistory() async {
    setState(() {
      _isLoadingLeaveHistory = true;
      _leaveHistoryError = null;
    });
    final leaveRepository = getIt<LeaveRepository>();
    final result = await leaveRepository.fetchLeaveApplications();
    if (result is NetworkSuccess<List<LeaveResponse>>) {
      setState(() {
        _leaveRequests.clear();
        _leaveRequests.addAll(result.data);
        _initializeEvents();
        _isLoadingLeaveHistory = false;
      });
    } else if (result is NetworkError) {
      setState(() {
        _isLoadingLeaveHistory = false;
        // _leaveHistoryError = result..toString();
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
      bool typeMatch = _selectedTypeFilter == 'All' || leave.leaveType == _selectedTypeFilter;
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
    return Scaffold(
      drawer: AppSideDrawer(),
      appBar: AppBar(
        title: const Text('Leave Management', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeaveBalanceSection(),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 8),
            SizedBox(height: 500,
              child: _buildLeaveHistoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLeaveApplicationBottomSheet(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildLeaveBalanceSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2),),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      onSubmissionSuccess: _fetchLeaveHistory, // Add this line
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    value: _selectedStatusFilter,
                    items: ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusFilter = value!;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Leave Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    value: _selectedTypeFilter,
                    items: ['All', ..._leaveTypes.map((e) => e.name)]
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTypeFilter = value!;
                      });
                    },
                    isExpanded: true,
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
                        setState(() {
                          _selectedDateFilter = picked;
                        });
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
                          text: _selectedDateFilter == null
                              ? 'Select date range'
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        backgroundColor: _getStatusColor(leave.leaveType).withOpacity(0.13),
                        radius: 22,
                        child: Icon(_getLeaveTypeIcon(leave.leaveType), color: _getStatusColor(leave.leaveType), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.leaveType,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(leave.dateRange.start)} - ${DateFormat('dd MMM yyyy').format(leave.dateRange.end)} (${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''})',
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
                  Center(
                    child: Icon(Icons.expand_more, color: Colors.grey, size: 22),
                  ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isEditable = leave.status == 'Pending';
        if (isEditable) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
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
                                onPressed: () {
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
                                    );
                                    _initializeEvents();
                                  });
                                  Navigator.pop(context);
                                  showGlobalSnackBar('Leave request withdrawn.');
                                },
                                label: const Text('Withdraw Leave', style: TextStyle(fontSize: 16),),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(_getLeaveTypeIcon(leave.leaveType), color: _getStatusColor(leave.leaveType), size: 28),
                          const SizedBox(width: 10),
                          Text(
                            leave.leaveType,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const Spacer(),
                          _buildStatusIndicator(leave.status),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${DateFormat('dd MMM yyyy').format(leave.dateRange.start)} - ${DateFormat('dd MMM yyyy').format(leave.dateRange.end)}'),
                      const SizedBox(height: 10),
                      if (leave.leaveType == 'Half Day' && leave.halfDayType != null) ...[
                        Text('Half Day:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(leave.halfDayType!),
                        const SizedBox(height: 10),
                      ],
                      if (leave.leaveType == 'Short Leave' && leave.shortLeaveTime != null) ...[
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
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
        return Icons.sick;
      case 'Casual Leave':
        return Icons.beach_access;
      case 'Half Day':
        return Icons.wb_sunny;
      case 'Short Leave':
        return Icons.timelapse;
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
      _selectedLeaveType = widget.initialLeave!.leaveType;
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
      if (_selectedLeaveType == 'Half Day Leave' && widget.initialLeave!.reason.contains('First Half')) {
        _selectedHalf = 'First Half';
      } else if (_selectedLeaveType == 'Half Day Leave' && widget.initialLeave!.reason.contains('Second Half')) {
        _selectedHalf = 'Second Half';
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
        setState(() {
          _attachmentPath = result.files.single.path;
        });
      }
    } catch (e) {
      showGlobalSnackBar('Error picking file: $e');
    }
  }

  void _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') &&
        _dateRange!.start != _dateRange!.end) {
      showGlobalSnackBar('Short Leave and Half Day can only be applied for a single day.');
      return;
    }
    if (_selectedLeaveType == 'Short Leave' && _shortLeaveStartTime == null) {
      showGlobalSnackBar('Please select the start time for your short leave.');
      return;
    }
    if (_selectedLeaveType == 'Half Day Leave' && _selectedHalf == null) {
      showGlobalSnackBar('Please select which half for Half Day leave.');
      return;
    }

    if (_selectedManagers.isEmpty) {
      showGlobalSnackBar('Please select at least one manager.');
      return;
    }

    final currentLeaveId = widget.initialLeave?.id;

    for (final existingLeave in widget.existingLeaveRequests) {
      if (currentLeaveId != null && existingLeave.id == currentLeaveId) {
        continue;
      }

      if (_dateRange!.start.isBefore(existingLeave.dateRange.end.add(const Duration(days: 1))) &&
          _dateRange!.end.isAfter(existingLeave.dateRange.start.subtract(const Duration(days: 1)))) {
        showGlobalSnackBar('Leave request already exists for the selected date range. Please choose different dates.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

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
      startTime: _shortLeaveStartTime?.format(context),
      endTime: _shortLeaveEndTime?.format(context),
    );

    final repo = getIt<LeaveRepository>();
    final result = await repo.applyLeave(request);

    setState(() {
      _isSubmitting = false;
    });

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
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Leave Type *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedLeaveType,
            items: uniqueLeaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (value) => setState(() {
              final wasSingleDay = _selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave';
              final isSingleDay = value == 'Short Leave' || value == 'Half Day Leave';
              if (wasSingleDay != isSingleDay) {
                _dateRange = null;
              }
              _selectedLeaveType = value;
              if (value != 'Half Day Leave') _selectedHalf = null;
            }),
            validator: (value) => value == null ? 'Please select leave type' : null,
            isExpanded: true,
          ),
          if (_selectedLeaveType == 'Half Day Leave') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('First Half'),
                    value: 'First Half',
                    groupValue: _selectedHalf,
                    onChanged: (value) {
                      setState(() {
                        _selectedHalf = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Second Half'),
                    value: 'Second Half',
                    groupValue: _selectedHalf,
                    onChanged: (value) {
                      setState(() {
                        _selectedHalf = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_selectedLeaveType == 'Short Leave') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _shortLeaveStartTime ?? TimeOfDay.now(),
                );
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
                  controller: TextEditingController(
                    text: _shortLeaveStartTime == null ? 'Select start time' : _shortLeaveStartTime!.format(context),
                  ),
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
                  setState(() {
                    _dateRange = DateTimeRange(start: picked, end: picked);
                  });
                }
              } else {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _dateRange,
                );
                if (picked != null) {
                  setState(() {
                    _dateRange = picked;
                  });
                }
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: (_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave')
                      ? 'Select date *'
                      : 'Select date range *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.date_range),
                  suffixIcon: const Icon(Icons.calendar_today),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(
                  text: _dateRange == null
                      ? (_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave'
                      ? 'Select date'
                      : 'Select date range')
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
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total Days: $_totalDays',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (_dateRange != null) const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'HR *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedHR,
            items: uniqueHRs.map((hr) => DropdownMenuItem(value: hr, child: Text(hr))).toList(),
            onChanged: (value) => setState(() => _selectedHR = value),
            validator: (value) => value == null ? 'Please select an HR' : null,
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          FormField<List<RoleUser>>(
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      final List<RoleUser>? results = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return MultiSelectManagerDialog(
                            managers: widget.managerList,
                            selectedManagers: _selectedManagers,
                          );
                        },
                      );

                      if (results != null) {
                        setState(() {
                          _selectedManagers = results;
                          field.didChange(_selectedManagers);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Team Lead(s) *',
                        border: const OutlineInputBorder(),
                        errorText: field.errorText,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: _selectedManagers.isEmpty
                          ? const Text('Select one or more managers')
                          : Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: _selectedManagers
                            .map((manager) => Chip(
                          label: Text(manager.fullName),
                          onDeleted: () {
                            setState(() {
                              _selectedManagers.remove(manager);
                              field.didChange(_selectedManagers);
                            });
                          },
                        ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least one manager.';
              }
              return null;
            },
            initialValue: _selectedManagers,
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
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
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
              onPressed: _isSubmitting ? null : _submitLeaveRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
                  : const Text('Submit Leave Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class MultiSelectManagerDialog extends StatefulWidget {
  final List<RoleUser> managers;
  final List<RoleUser> selectedManagers;

  const MultiSelectManagerDialog({
    Key? key,
    required this.managers,
    required this.selectedManagers,
  }) : super(key: key);

  @override
  State<MultiSelectManagerDialog> createState() => _MultiSelectManagerDialogState();
}

class _MultiSelectManagerDialogState extends State<MultiSelectManagerDialog> {
  late final List<RoleUser> _tempSelectedManagers;

  @override
  void initState() {
    super.initState();
    _tempSelectedManagers = List.from(widget.selectedManagers);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Managers'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: widget.managers.length,
          itemBuilder: (context, index) {
            final manager = widget.managers[index];
            final isSelected = _tempSelectedManagers.any((m) => m.id == manager.id);
            return CheckboxListTile(
              title: Text(manager.fullName),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _tempSelectedManagers.add(manager);
                  } else {
                    _tempSelectedManagers.removeWhere((m) => m.id == manager.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(_tempSelectedManagers),
        ),
      ],
    );
  }
}

