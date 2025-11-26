import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/core/utils/network_result.dart';

enum DateFilter { week, month, custom }

class PunchHistoryController extends GetxController {
  final PunchHistoryUseCase _useCase = GetIt.I<PunchHistoryUseCase>();

  // reactive state
  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rx<DateTime> endDate = DateTime.now().obs;
  final RxList<PunchEntry> punchHistory = <PunchEntry>[].obs;
  final RxBool isLoading = false.obs;
  int currentPage = 1;
  final RxBool hasMore = true.obs;
  final int pageSize = 10;
  final Rx<DateFilter> selectedFilter = DateFilter.week.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate.value = now.subtract(Duration(days: now.weekday - 1));
    endDate.value = startDate.value.add(const Duration(days: 6));
    fetchPunchHistory();
  }

  Future<void> fetchPunchHistory({bool isLoadMore = false}) async {
    if (isLoading.value || (!hasMore.value && isLoadMore)) return;
    isLoading.value = true;

    final sd = startDate.value;
    final ed = endDate.value;
    final startDateStr = "${sd.year}-${sd.month.toString().padLeft(2, '0')}-${sd.day.toString().padLeft(2, '0')}";
    final endDateStr = "${ed.year}-${ed.month.toString().padLeft(2, '0')}-${ed.day.toString().padLeft(2, '0')}";

    final result = await _useCase(
      startDate: startDateStr,
      endDate: endDateStr,
      page: currentPage,
      pageSize: pageSize,
    );

    if (result is NetworkSuccess<PunchHistoryResponse>) {
      if (isLoadMore) {
        punchHistory.addAll(result.data.results);
      } else {
        punchHistory.assignAll(result.data.results);
      }
      hasMore.value = result.data.results.length == pageSize;
      isLoading.value = false;
      if (isLoadMore) currentPage++;
    } else {
      isLoading.value = false;
    }
  }

  Future<void> pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: startDate.value, end: endDate.value),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      startDate.value = picked.start;
      endDate.value = picked.end;
      currentPage = 1;
      hasMore.value = true;
      await fetchPunchHistory();
    }
  }

  void changeFilter(int index) {
    final now = DateTime.now();
    selectedFilter.value = DateFilter.values[index];
    if (selectedFilter.value == DateFilter.week) {
      startDate.value = now.subtract(Duration(days: now.weekday - 1));
      endDate.value = startDate.value.add(const Duration(days: 6));
    } else if (selectedFilter.value == DateFilter.month) {
      startDate.value = DateTime(now.year, now.month, 1);
      endDate.value = DateTime(now.year, now.month + 1, 0);
    } else if (selectedFilter.value == DateFilter.custom) {
      startDate.value = now.subtract(Duration(days: now.weekday - 1));
      endDate.value = startDate.value.add(const Duration(days: 6));
    }
    currentPage = 1;
    hasMore.value = true;
    fetchPunchHistory();
  }

  void prevRange() {
    if (selectedFilter.value == DateFilter.week) {
      startDate.value = startDate.value.subtract(const Duration(days: 7));
      endDate.value = endDate.value.subtract(const Duration(days: 7));
    } else if (selectedFilter.value == DateFilter.month) {
      final prevMonth = DateTime(startDate.value.year, startDate.value.month - 1, 1);
      startDate.value = prevMonth;
      endDate.value = DateTime(prevMonth.year, prevMonth.month + 1, 0);
    } else if (selectedFilter.value == DateFilter.custom) {
      final diff = endDate.value.difference(startDate.value).inDays;
      startDate.value = startDate.value.subtract(Duration(days: diff + 1));
      endDate.value = endDate.value.subtract(Duration(days: diff + 1));
    }
    currentPage = 1;
    hasMore.value = true;
    fetchPunchHistory();
  }

  void nextRange() {
    if (selectedFilter.value == DateFilter.week) {
      startDate.value = startDate.value.add(const Duration(days: 7));
      endDate.value = endDate.value.add(const Duration(days: 7));
    } else if (selectedFilter.value == DateFilter.month) {
      final nextMonth = DateTime(startDate.value.year, startDate.value.month + 1, 1);
      startDate.value = nextMonth;
      endDate.value = DateTime(nextMonth.year, nextMonth.month + 1, 0);
    } else if (selectedFilter.value == DateFilter.custom) {
      final diff = endDate.value.difference(startDate.value).inDays;
      startDate.value = startDate.value.add(Duration(days: diff + 1));
      endDate.value = endDate.value.add(Duration(days: diff + 1));
    }
    currentPage = 1;
    hasMore.value = true;
    fetchPunchHistory();
  }

  void loadMore() {
    if (hasMore.value && !isLoading.value) {
      currentPage++;
      fetchPunchHistory(isLoadMore: true);
    }
  }
}
