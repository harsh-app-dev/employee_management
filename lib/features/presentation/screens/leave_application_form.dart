import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:employee_management/features/presentation/screens/leave_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injectable_module.dart';
import '../../../core/utils/network_result.dart';
import '../../../core/utils/util.dart';
import '../../../core/widgets/debouncing_state.dart';
import '../../../core/widgets/document_web_viewer.dart';
import '../../data/models/leave/leave_apply_request.dart';
import '../../data/models/leave/leave_response.dart';
import '../../data/models/leave/leave_type.dart';
import '../../data/models/leave/role_user.dart';
import '../../data/repositories/leave_repository.dart';

class LeaveApplicationForm extends StatefulWidget {
  final List<String> leaveTypes;
  final List<LeaveType> leaveTypeObjects;
  final List<RoleUser> hrList;
  final List<RoleUser> managerList;
  final List<LeaveResponse> existingLeaveRequests;
  final Function(LeaveResponse, {double casualDeduct, int sickDeduct, int shortDeduct}) onLeaveSubmitted;
  final VoidCallback onSubmissionSuccess;
  final LeaveResponse? initialLeave;
  const LeaveApplicationForm({
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
  State<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
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
      // Pre-select all managers from the leave request
      _selectedManagers = widget.managerList.where((m) => widget.initialLeave!.managers.contains(m.id)).toList();
      _dateRange = DateTimeRange(
        start: DateTime.parse(widget.initialLeave!.fromDate),
        end: DateTime.parse(widget.initialLeave!.toDate),
      );
      _attachmentPath = widget.initialLeave!.attachment;
      _reasonController.text = widget.initialLeave!.reason;
      // Convert from_time and to_time (timestamp) to TimeOfDay
      if (widget.initialLeave!.fromTime != null) {
        final fromTimestamp = int.tryParse(widget.initialLeave!.fromTime.toString());
        if (fromTimestamp != null) {
          final fromDateTime = DateTime.fromMillisecondsSinceEpoch(fromTimestamp * 1000);
          _shortLeaveStartTime = TimeOfDay(hour: fromDateTime.hour, minute: fromDateTime.minute);
        }
      }
      if (widget.initialLeave!.toTime != null) {
        final toTimestamp = int.tryParse(widget.initialLeave!.toTime.toString());
        if (toTimestamp != null) {
          final toDateTime = DateTime.fromMillisecondsSinceEpoch(toTimestamp * 1000);
          _shortLeaveEndTime = TimeOfDay(hour: toDateTime.hour, minute: toDateTime.minute);
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
      if (_dateRange!.start.isBefore(existingLeave.toDateTime.add(const Duration(days: 1))) &&
          _dateRange!.end.isAfter(existingLeave.fromDateTime.subtract(const Duration(days: 1)))) {
        showGlobalSnackBarOverlay('Leave request already exists for the selected date range. Please choose different dates.');
        return;
      }
    }

    setState(() {_isSubmitting = true;});

    final selectedLeaveType = widget.leaveTypeObjects.firstWhere((t) => t.name == _selectedLeaveType);
    final selectedHr = widget.hrList.firstWhere((hr) => hr.fullName == _selectedHR);
    final selectedManagerIds = _selectedManagers.map((m) => m.id).toList();

    final request = LeaveApplyRequest(
      leaveType: selectedLeaveType.id,
      fromDate: _dateRange!.start,
      toDate: _dateRange!.end,
      managers: selectedManagerIds.map((id) => id.toString()).toList(),
      hr: selectedHr.id.toString(),
      reason: _reasonController.text.trim(),
      attachment: _attachmentPath != null ? File(_attachmentPath!) : null,
      fromTime: _shortLeaveStartTime != null ? '${_shortLeaveStartTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveStartTime!.minute.toString().padLeft(2, '0')}' : null,
      toTime: _shortLeaveEndTime != null ? '${_shortLeaveEndTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveEndTime!.minute.toString().padLeft(2, '0')}' : null,
    );

    final repo = getIt<LeaveRepository>();
    final result = await repo.applyLeave(request);

    setState(() {_isSubmitting = false;});

    if (result is NetworkSuccess) {
      widget.onSubmissionSuccess();
      showGlobalSnackBar('Leave application submitted successfully!');
      Navigator.pop(context);
    } else if (result is NetworkError) {
      showGlobalSnackBarOverlay(result.message);
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
    if (_selectedHR == null && uniqueHRs.length == 1) {
      _selectedHR = uniqueHRs.first;
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
          if (_selectedLeaveType == 'Half Day Leave' || _selectedLeaveType == 'Short Leave') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _shortLeaveStartTime ?? TimeOfDay.now(),);
                if (picked != null) {
                  setState(() {_shortLeaveStartTime = picked;});
                }
              },
              child: FormField<TimeOfDay>(
                validator: (value) {
                  if ((_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') && _shortLeaveStartTime == null) {
                    return 'Please select start time';
                  }
                  return null;
                },
                builder: (field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Time *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.access_time),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      errorText: field.errorText,
                    ),
                    child: Text(
                      _shortLeaveStartTime != null ? _shortLeaveStartTime!.format(context) : 'Select Start Time',
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _shortLeaveEndTime ?? TimeOfDay.now(),);
                if (picked != null) {
                  setState(() {_shortLeaveEndTime = picked;});
                }
              },
              child: FormField<TimeOfDay>(
                validator: (value) {
                  if ((_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') && _shortLeaveEndTime == null) {
                    return 'Please select end time';
                  }

                  // Check if end time is earlier than start time
                  if (_shortLeaveStartTime != null && _shortLeaveEndTime != null && (_shortLeaveEndTime!.hour < _shortLeaveStartTime!.hour ||
                          (_shortLeaveEndTime!.hour == _shortLeaveStartTime!.hour && _shortLeaveEndTime!.minute <= _shortLeaveStartTime!.minute))) {
                    return 'End time cannot be before start time';
                  }

                  return null;
                },
                builder: (field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Time *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.access_time),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      errorText: field.errorText,
                    ),
                    child: Text(_shortLeaveEndTime != null ? _shortLeaveEndTime!.format(context) : 'Select End Time',),
                  );
                },
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
              return DropdownButtonHideUnderline(
                child: DropdownButton2(
                  isExpanded: true,
                  customButton: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Team Lead(s) *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16,),
                      errorText: field.errorText,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectedManagers.isEmpty
                              ? const Text('Select one or more managers', style: TextStyle(fontSize: 14, color: Colors.black54,), overflow: TextOverflow.ellipsis,)
                              : Text(_selectedManagers.map((e) => e.fullName).join(', '),
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54,),
                      ],
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 250,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white, border: Border.all(color: Colors.grey.shade300),),
                  ),
                  onChanged: (_) {},
                  items: widget.managerList.map((manager) {
                    return DropdownMenuItem(
                      value: manager,
                      child: StatefulBuilder(
                        builder: (context, setStateSB) {
                          final isSelected =
                          _selectedManagers.any((m) => m.id == manager.id);
                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            title: Text(manager.fullName, style: const TextStyle(fontSize: 14),),
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
                ),
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
                const Text('Attachment (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _attachmentPath != null ? null : _pickFile,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: Text(
                          _attachmentPath == null ? 'Choose File' : 'File Attached',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: _attachmentPath != null ? Colors.grey[400] : null,
                        ),
                      ),
                    ),
                  ],
                ),

                // Attached File Preview
                if (_attachmentPath != null) ...[
                  const SizedBox(height: 10),
                  DocumentWebViewer(
                    filePath: _attachmentPath!,
                    onRemove: () {
                      setState(() {
                        _attachmentPath = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: (widget.initialLeave != null && widget.initialLeave!.status.toLowerCase() != 'pending')
                  ? null // 🔒 Disable if not pending
                  : (_isSubmitting ? null : () {
                submitDebouncer.run(() async {
                  if (widget.initialLeave != null) {
                    if (!_formKey.currentState!.validate()) return;
                    if ((_selectedLeaveType == 'Short Leave' || _selectedLeaveType == 'Half Day Leave') &&
                        _dateRange!.start != _dateRange!.end) {
                      showGlobalSnackBarOverlay('Short Leave and Half Day can only be applied for a single day.');
                      return;
                    }

                    setState(() {_isSubmitting = true;});

                    final selectedLeaveType = widget.leaveTypeObjects.firstWhere((t) => t.name == _selectedLeaveType);
                    final selectedHr = widget.hrList.firstWhere((hr) => hr.fullName == _selectedHR);
                    final selectedManagerIds = _selectedManagers.map((m) => m.id).toList();

                    final request = LeaveApplyRequest(
                      leaveType: selectedLeaveType.id,
                      fromDate: _dateRange!.start,
                      toDate: _dateRange!.end,
                      managers: selectedManagerIds.map((id) => id.toString()).toList(),
                      hr: selectedHr.id.toString(),
                      reason: _reasonController.text.trim(),
                      attachment: _attachmentPath != null ? File(_attachmentPath!) : null,
                      fromTime: _shortLeaveStartTime != null
                          ? "${_shortLeaveStartTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveStartTime!.minute.toString().padLeft(2, '0')}"
                          : null,
                      toTime: _shortLeaveEndTime != null
                          ? "${_shortLeaveEndTime!.hour.toString().padLeft(2, '0')}:${_shortLeaveEndTime!.minute.toString().padLeft(2, '0')}"
                          : null,
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
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ) : Text(
                widget.initialLeave != null
                    ? 'Update Leave Request'
                    : 'Submit Leave Request',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              )

            ),
          )
        ],
      ),
    );
  }
}