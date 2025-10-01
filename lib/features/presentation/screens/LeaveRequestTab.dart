import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/leave/leave_approval_request.dart';
import 'package:employee_management/features/data/repositories/leave_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LeaveRequestTab extends StatefulWidget {
  const LeaveRequestTab({super.key});

  @override
  State<LeaveRequestTab> createState() => _LeaveRequestTabState();
}

class _LeaveRequestTabState extends State<LeaveRequestTab> {
  final LeaveRepository _leaveRepository = GetIt.I<LeaveRepository>();
  List<LeaveApprovalRequest> leaveRequests = [];
  bool isLoading = true;

  // Filters
  final String _selectedStatusFilter = 'All';
  final String _selectedTimeFilter = 'This Week';
  final List<String> statusFilters = ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'];
  final List<String> timeFilters = ['This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() => isLoading = true);
    final result = await _leaveRepository.fetchLeaveApprovalRequests();
    if (result is NetworkSuccess<List<LeaveApprovalRequest>>) {
      setState(() => leaveRequests = result.data);
    } else if (result is NetworkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch leaves')),
      );
    }
    setState(() => isLoading = false);
  }

  List<LeaveApprovalRequest> get _filteredRequests {
    DateTime now = DateTime.now();
    DateTime startDate;

    // Time filter
    if (_selectedTimeFilter == 'This Week') {
      int weekday = now.weekday;
      startDate = now.subtract(Duration(days: weekday - 1)); // Monday
    } else {
      startDate = DateTime(now.year, now.month, 1); // first day of month
    }

    List<LeaveApprovalRequest> filtered = leaveRequests.where((leave) {
      DateTime leaveStart = DateTime.parse(leave.fromDate);
      bool matchesTime = leaveStart.isAfter(startDate.subtract(const Duration(days: 1)));
      bool matchesStatus = _selectedStatusFilter == 'All' || leave.status == _selectedStatusFilter;
      return matchesTime && matchesStatus;
    }).toList();

    return filtered;
  }

  Color _statusColor(String status) {
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

  Future<void> _showApproveRejectDialog(int index, String action) async {
    final leave = _filteredRequests[index];
    final TextEditingController commentsController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$action Leave',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter comments (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, commentsController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action == 'Approved' ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(action, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      await _updateStatus(leave.id, action, comments: result);
    }
  }

  Future<void> _updateStatus(String leaveId, String newStatus, {String comments = ''}) async {
    final result = await _leaveRepository.updateLeaveStatus(
      leaveId: leaveId,
      action: newStatus,
      comments: comments,
    );

    if (result is NetworkSuccess) {
      _fetchLeaveRequests();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Leave $newStatus!")));
    } else if (result is NetworkError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update leave: ${result.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Filters
/*
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status Filter
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: _selectedStatusFilter,
                        hint: const Text(
                          'Select Status',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        items: statusFilters
                            .map((s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 14)),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedStatusFilter = value);
                        },
                        buttonStyleData: const ButtonStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
                            color: Colors.white,
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          width: null, // <-- null allows it to match button width
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                          ),
                          offset: const Offset(0, 5),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          iconEnabledColor: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Time Filter
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: _selectedTimeFilter,
                        hint: const Text(
                          'Select Time',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        items: timeFilters
                            .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 14)),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedTimeFilter = value);
                        },
                        buttonStyleData: const ButtonStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
                            color: Colors.white,
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          width: null, // <-- match button width
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                          ),
                          offset: const Offset(0, 5),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          iconEnabledColor: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
*/
            // Leave List
            Expanded(
              child: _filteredRequests.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.event_busy, size: 70, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No leave requests found', style: TextStyle(fontSize: 24)),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _filteredRequests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final leave = _filteredRequests[index];
                  final status = leave.status;

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(leave.requestedBy,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                                ),
                                child: Text(status,
                                    style: TextStyle(
                                        color: _statusColor(status), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Type: ${leave.leaveTypeName}'),
                          Text('Date: ${leave.fromDate} - ${leave.toDate}'),
                          Text('Reason: ${leave.reason}'),
                          if (status == 'Pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showApproveRejectDialog(index, 'Approved'),
                                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () => _showApproveRejectDialog(index, 'Rejected'),
                                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                  label: const Text('Reject', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // Loader overlay
        if (isLoading)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
