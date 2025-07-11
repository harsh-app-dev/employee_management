import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'app_side_drawer.dart';

class LeaveRequest {
  final String id;
  final DateTimeRange dateRange;
  final String leaveType;
  final String reason;
  final String? attachmentPath;
  final String hr;
  final String teamLead;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Cancelled'
  final DateTime appliedDate;
  final String? managerComment;
  final DateTime? processedDate;
  final int totalDays;

  LeaveRequest({
    required this.id,
    required this.dateRange,
    required this.leaveType,
    required this.reason,
    this.attachmentPath,
    required this.hr,
    required this.teamLead,
    this.status = 'Pending',
    required this.appliedDate,
    this.managerComment,
    this.processedDate,
    required this.totalDays,
  });
}

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
  // Leave types
  final List<String> _leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Half Day', // Not a separate quota, but an option
    'Short Leave',
  ];

  // HR and Team Lead options
  final List<String> _hrList = ['Alice HR', 'Bob HR', 'Charlie HR', 'Diana HR'];
  final List<String> _teamLeadList = ['David TL', 'Eva TL', 'Frank TL', 'Grace TL'];

  // Leave balances (Half Day is not a separate quota)
  double _casualUsed = 3; // can be incremented by 0.5 for half day
  int _shortUsed = 0;
  final double _casualTotal = 12;
  final int _shortTotal = 1;

  // Sample leave requests
  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      id: 'LR001',
      dateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 10)), end: DateTime.now().subtract(const Duration(days: 7))),
      leaveType: 'Casual Leave',
      reason: 'Family function',
      hr: 'Alice HR',
      teamLead: 'David TL',
      status: 'Approved',
      appliedDate: DateTime.now().subtract(const Duration(days: 15)),
      processedDate: DateTime.now().subtract(const Duration(days: 12)),
      managerComment: 'Approved. Enjoy your time with family.',
      totalDays: 3,
    ),
    LeaveRequest(
      id: 'LR002',
      dateRange: DateTimeRange(start: DateTime.now().add(const Duration(days: 2)), end: DateTime.now().add(const Duration(days: 5))),
      leaveType: 'Sick Leave',
      reason: 'Medical appointment',
      hr: 'Bob HR',
      teamLead: 'Eva TL',
      status: 'Pending',
      appliedDate: DateTime.now().subtract(const Duration(days: 2)),
      totalDays: 3,
    ),
    LeaveRequest(
      id: 'LR003',
      dateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 20)), end: DateTime.now().subtract(const Duration(days: 17))),
      leaveType: 'Half Day',
      reason: 'Personal work',
      hr: 'Charlie HR',
      teamLead: 'Frank TL',
      status: 'Rejected',
      appliedDate: DateTime.now().subtract(const Duration(days: 25)),
      processedDate: DateTime.now().subtract(const Duration(days: 22)),
      managerComment: 'Rejected due to project deadline.',
      totalDays: 3,
    ),
    LeaveRequest(
      id: 'LR004',
      dateRange: DateTimeRange(start: DateTime.now().add(const Duration(days: 15)), end: DateTime.now().add(const Duration(days: 21))),
      leaveType: 'Short Leave',
      reason: 'Attending cousin\'s wedding',
      hr: 'Diana HR',
      teamLead: 'Grace TL',
      status: 'Approved',
      appliedDate: DateTime.now().subtract(const Duration(days: 5)),
      processedDate: DateTime.now().subtract(const Duration(days: 3)),
      managerComment: 'Approved. Congratulations!',
      totalDays: 6,
    ),
  ];

  // Calendar view
  Map<DateTime, List<LeaveRequest>> _events = {};

  // Filter options
  String _selectedStatusFilter = 'All';
  String _selectedTypeFilter = 'All';
  DateTimeRange? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    _initializeEvents();
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

  void _addLeaveRequest(LeaveRequest request, {double casualDeduct = 0, int sickDeduct = 0, int shortDeduct = 0}) {
    setState(() {
      _leaveRequests.insert(0, request);
      _casualUsed += casualDeduct;
      _shortUsed += shortDeduct;
      _initializeEvents();
    });
  }


  List<LeaveRequest> get _filteredLeaveRequests {
    return _leaveRequests.where((leave) {
      bool statusMatch = _selectedStatusFilter == 'All' || leave.status == _selectedStatusFilter;
      bool typeMatch = _selectedTypeFilter == 'All' || leave.leaveType == _selectedTypeFilter;
      bool dateMatch = _selectedDateFilter == null || 
          (leave.dateRange.start.isAfter(_selectedDateFilter!.start.subtract(const Duration(days: 1))) &&
           leave.dateRange.end.isBefore(_selectedDateFilter!.end.add(const Duration(days: 1))));
      
      return statusMatch && typeMatch && dateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            SizedBox(
              height: 500, // or MediaQuery.of(context).size.height * 0.6 for dynamic height
              child: _buildLeaveHistoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLeaveApplicationBottomSheet(),
        child: const Icon(Icons.add, size: 28),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
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
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Apply for Leave',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _LeaveApplicationForm(
                      leaveTypes: _leaveTypes,
                      hrList: _hrList,
                      teamLeadList: _teamLeadList,
                      onLeaveSubmitted: (request, {casualDeduct = 0, sickDeduct = 0, shortDeduct = 0}) {
                        _addLeaveRequest(request, casualDeduct: casualDeduct, sickDeduct: sickDeduct, shortDeduct: shortDeduct);
                        Navigator.pop(context);
                      },
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
                    items: ['All', ..._leaveTypes]
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
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(leave.leaveType).withOpacity(0.13),
                  child: Icon(_getLeaveTypeIcon(leave.leaveType), color: _getStatusColor(leave.leaveType), size: 22),
                  radius: 22,
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
                _buildStatusChip(leave.status),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: _getStatusColor(status),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
  final List<String> hrList;
  final List<String> teamLeadList;
  final Function(LeaveRequest, {double casualDeduct, int sickDeduct, int shortDeduct}) onLeaveSubmitted;
  const _LeaveApplicationForm({
    required this.leaveTypes,
    required this.hrList,
    required this.teamLeadList,
    required this.onLeaveSubmitted,
  });

  @override
  State<_LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<_LeaveApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedLeaveType;
  String? _selectedHR;
  String? _selectedTeamLead;
  DateTimeRange? _dateRange;
  String? _attachmentPath;
  bool _isSubmitting = false;

  int get _totalDays {
    if (_dateRange == null) return 0;
    return _dateRange!.duration.inDays + 1;
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
          _attachmentPath = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Determine leave deduction
    double casualDeduct = 0;
    int sickDeduct = 0;
    int shortDeduct = 0;
    int totalDays = _totalDays;
    String leaveType = _selectedLeaveType!;
    if (leaveType == 'Half Day') {
      casualDeduct = 0.5;
      totalDays = 1; // For display
    } else if (leaveType == 'Casual Leave') {
      casualDeduct = _totalDays.toDouble();
    } else if (leaveType == 'Sick Leave') {
      sickDeduct = _totalDays;
    } else if (leaveType == 'Short Leave') {
      shortDeduct = _totalDays;
    }

    // Call parent to update balances
    widget.onLeaveSubmitted(
      LeaveRequest(
        id: 'LR${DateTime.now().millisecondsSinceEpoch}',
        dateRange: _dateRange!,
        leaveType: leaveType,
        reason: _reasonController.text.trim(),
        attachmentPath: _attachmentPath,
        hr: _selectedHR!,
        teamLead: _selectedTeamLead!,
        status: 'Pending',
        appliedDate: DateTime.now(),
        totalDays: totalDays,
      ),
      casualDeduct: casualDeduct,
      sickDeduct: sickDeduct,
      shortDeduct: shortDeduct,
    );

    setState(() {
      _isSubmitting = false;
    });

    // Reset form
    _formKey.currentState!.reset();
    _selectedLeaveType = null;
    _selectedHR = null;
    _selectedTeamLead = null;
    _dateRange = null;
    _attachmentPath = null;
    _reasonController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave application submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Leave Type Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Leave Type *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedLeaveType,
            items: widget.leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (value) => setState(() => _selectedLeaveType = value),
            validator: (value) => value == null ? 'Please select leave type' : null,
            isExpanded: true,
          ),
          const SizedBox(height: 12),

          // Date Range Picker
          GestureDetector(
            onTap: () async {
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
            },
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date Range *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                  suffixIcon: Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(
                  text: _dateRange == null
                      ? 'Select date range'
                      : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                ),
                validator: (_) => _dateRange == null ? 'Please select date range' : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Total Days Display
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

          // HR Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select HR *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedHR,
            items: widget.hrList.map((hr) => DropdownMenuItem(value: hr, child: Text(hr))).toList(),
            onChanged: (value) => setState(() => _selectedHR = value),
            validator: (value) => value == null ? 'Please select HR' : null,
            isExpanded: true,
          ),
          const SizedBox(height: 12),

          // Team Lead Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Team Lead *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group_outlined),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedTeamLead,
            items: widget.teamLeadList.map((tl) => DropdownMenuItem(value: tl, child: Text(tl))).toList(),
            onChanged: (value) => setState(() => _selectedTeamLead = value),
            validator: (value) => value == null ? 'Please select Team Lead' : null,
            isExpanded: true,
          ),
          const SizedBox(height: 12),

          // Reason Text Field
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2, // Reduced from 3 to 2
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter reason' : null,
          ),
          const SizedBox(height: 12),

          // Attachment Section
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
                    const SizedBox(width: 8),
                    if (_attachmentPath != null)
                      Expanded(
                        child: Text(
                          _attachmentPath!,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 45, // Reduced height
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