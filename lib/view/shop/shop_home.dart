import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/shop_workingdays.dart';
import 'package:projectqdel/services/api_service.dart';

class ShopHome extends StatefulWidget {
  const ShopHome({super.key});

  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  ApiService apiService = ApiService();
  bool isLoading = true;
  bool isUpdating = false;

  // Shop data
  int? shopId;
  bool isManuallyClosed = false;
  List<WorkingDay> workingDays = [];
  List<SpecialDay> specialDays = [];

  // Registration flow
  bool isRegistering = false;
  int registrationStep = 0;

  // Edit mode
  bool isEditMode = false;
  bool hasUnsavedChanges = false;
  int? editingDayIndex;
  int? editingSpecialDayIndex;

  // Special day form - only used in edit mode
  DateTime? selectedSpecialDate;
  bool specialDayIsOpen = true;
  TimeOfDay? specialOpenTime;
  TimeOfDay? specialCloseTime;
  List<BreakTime> specialBreaks = [];

  // Temporary copies for edit mode
  List<WorkingDay> tempWorkingDays = [];
  List<SpecialDay> tempSpecialDays = [];

  @override
  void initState() {
    super.initState();
    fetchShopData();
  }

  Future<void> fetchShopData() async {
    setState(() => isLoading = true);
    try {
      final data = await apiService.getShopTimings();
      if (data != null &&
          data['working_days'] != null &&
          (data['working_days'] as List).isNotEmpty) {
        setState(() {
          shopId = data['id'];
          isManuallyClosed = data['is_manually_closed'] ?? false;
          workingDays = (data['working_days'] as List)
              .map((day) => WorkingDay.fromJson(day))
              .toList();
          specialDays = (data['special_days'] as List)
              .map((day) => SpecialDay.fromJson(day))
              .toList();
          isLoading = false;
          isRegistering = false;
        });
      } else {
        startRegistration();
      }
    } catch (e) {
      print('Error fetching data: $e');
      startRegistration();
    }
  }

  void startRegistration() {
    setState(() {
      workingDays = List.generate(
        7,
        (index) => WorkingDay(
          weekday: index,
          isOpen: false,
          openTime: null,
          closeTime: null,
          breaks: [],
        ),
      );
      specialDays = [];
      isLoading = false;
      isRegistering = true;
      registrationStep = 0;
    });
  }

  Future<void> saveShopData() async {
    setState(() => isUpdating = true);
    try {
      bool success;

      if (isRegistering) {
        success = await apiService.createShopTimings(
          workingDays: workingDays,
          specialDays: specialDays,
          isManuallyClosed: isManuallyClosed,
        );
      } else {
        success = await apiService.updateShopTimings(
          shopId: shopId,
          workingDays: workingDays,
          specialDays: specialDays,
          isManuallyClosed: isManuallyClosed,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "Saved successfully ✅" : "Failed to save ❌",
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

      if (success && isRegistering) {
        await fetchShopData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  void updateWorkingDayInTemp(WorkingDay updatedDay) {
    final index = tempWorkingDays.indexWhere(
      (d) => d.weekday == updatedDay.weekday,
    );
    if (index != -1) {
      setState(() {
        tempWorkingDays[index] = updatedDay;
        hasUnsavedChanges = true;
      });
    }
  }

  void addSpecialDayToTemp() {
    if (selectedSpecialDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    final newSpecialDay = SpecialDay(
      date: selectedSpecialDate!,
      isOpen: specialDayIsOpen,
      openTime: specialDayIsOpen ? specialOpenTime : null,
      closeTime: specialDayIsOpen ? specialCloseTime : null,
      breaks: specialDayIsOpen ? specialBreaks : [],
    );

    setState(() {
      tempSpecialDays.add(newSpecialDay);
      hasUnsavedChanges = true;
      selectedSpecialDate = null;
      specialDayIsOpen = true;
      specialOpenTime = null;
      specialCloseTime = null;
      specialBreaks = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Special day added to pending changes'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void updateSpecialDayInTemp(int index, SpecialDay updatedDay) {
    setState(() {
      tempSpecialDays[index] = updatedDay;
      hasUnsavedChanges = true;
    });
  }

  void deleteSpecialDayFromTemp(int index) {
    setState(() {
      tempSpecialDays.removeAt(index);
      hasUnsavedChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Special day removed from pending changes'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void enterEditMode() {
    // Create copies of current data
    setState(() {
      tempWorkingDays = workingDays.map((day) => day.copyWith()).toList();
      tempSpecialDays = specialDays.map((day) => day.copyWith()).toList();
      isEditMode = true;
      hasUnsavedChanges = false;
      editingDayIndex = null;
      editingSpecialDayIndex = null;
    });
  }

  void exitEditMode() {
    if (hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Unsaved Changes",
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            "You have unsaved changes. Are you sure you want to exit? All changes will be lost.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Stay", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isEditMode = false;
                  editingDayIndex = null;
                  editingSpecialDayIndex = null;
                  tempWorkingDays = [];
                  tempSpecialDays = [];
                  hasUnsavedChanges = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Changes discarded'),
                    backgroundColor: Colors.grey,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Discard"),
            ),
          ],
        ),
      );
    } else {
      // No unsaved changes, exit normally without dialog
      setState(() {
        isEditMode = false;
        editingDayIndex = null;
        editingSpecialDayIndex = null;
        tempWorkingDays = [];
        tempSpecialDays = [];
      });
    }
  }

  Future<void> saveAllChanges() async {
    setState(() => isUpdating = true);
    try {
      final success = await apiService.updateShopTimings(
        shopId: shopId,
        workingDays: tempWorkingDays,
        specialDays: tempSpecialDays,
        isManuallyClosed: isManuallyClosed,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All changes saved successfully ✅'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh data to get updated IDs from backend
          await fetchShopData();
          // Reset hasUnsavedChanges before exiting
          setState(() {
            hasUnsavedChanges = false;
            isEditMode = false;
            editingDayIndex = null;
            editingSpecialDayIndex = null;
            tempWorkingDays = [];
            tempSpecialDays = [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save changes ❌'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
              SizedBox(height: 16),
              Text('Loading shop data...', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (isRegistering) {
      return _buildRegistrationFlow();
    }

    return _buildDashboard();
  }

  Widget _buildRegistrationFlow() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "Set Your Shop Schedule",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: registrationStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  setState(() => registrationStep--);
                },
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Day ${registrationStep + 1} of 7",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${((registrationStep + 1) / 7 * 100).toInt()}%",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (registrationStep + 1) / 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildDayRegistrationPage(registrationStep)),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () {
                      if (registrationStep < 6) {
                        setState(() => registrationStep++);
                      } else {
                        saveShopData();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isUpdating
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      registrationStep == 6
                          ? "Complete Registration"
                          : "Continue",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRegistrationPage(int weekdayIndex) {
    final day = workingDays[weekdayIndex];
    final dayName = _getDayName(weekdayIndex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Configure schedule for $dayName",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              title: const Text(
                "Shop Open",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                day.isOpen
                    ? "Set opening and closing hours"
                    : "Shop will remain closed on $dayName",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              value: day.isOpen,
              activeColor: Colors.red,
              onChanged: (val) {
                setState(() {
                  workingDays[weekdayIndex] = day.copyWith(isOpen: val);
                });
              },
            ),
          ),

          if (day.isOpen) ...[
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Business Hours",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildRedTimePickerTile(
                      title: "Opening Time",
                      time: day.openTime,
                      icon: Icons.sunny,
                      onTap: () async {
                        final time = await _pickTime();
                        if (time != null) {
                          setState(() {
                            workingDays[weekdayIndex] = day.copyWith(
                              openTime: time,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildRedTimePickerTile(
                      title: "Closing Time",
                      time: day.closeTime,
                      icon: Icons.nightlight_round,
                      onTap: () async {
                        final time = await _pickTime();
                        if (time != null) {
                          setState(() {
                            workingDays[weekdayIndex] = day.copyWith(
                              closeTime: time,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildRedBreaksSection(
                  breaks: day.breaks,
                  onAddBreak: () async {
                    final newBreak = await _showBreakDialog();
                    if (newBreak != null) {
                      setState(() {
                        workingDays[weekdayIndex] = day.copyWith(
                          breaks: [...day.breaks, newBreak],
                        );
                      });
                    }
                  },
                  onRemoveBreak: (index) {
                    final newBreaks = List<BreakTime>.from(day.breaks);
                    newBreaks.removeAt(index);
                    setState(() {
                      workingDays[weekdayIndex] = day.copyWith(
                        breaks: newBreaks,
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    // Use temp data when in edit mode
    final displayWorkingDays = isEditMode ? tempWorkingDays : workingDays;
    final displaySpecialDays = isEditMode ? tempSpecialDays : specialDays;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "Shop Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: enterEditMode,
            ),
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: exitEditMode,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildManualCloseCard(),
                const SizedBox(height: 24),

                _buildRedSectionHeader("Weekly Schedule", Icons.calendar_today),
                const SizedBox(height: 12),
                ...displayWorkingDays.map(
                  (day) => _buildRedWorkingDayCard(day),
                ),
                const SizedBox(height: 24),

                _buildRedSectionHeader("Special Days", Icons.star),
                const SizedBox(height: 12),
                _buildRedSpecialDaysSection(displaySpecialDays),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Grey overlay when shop is closed (but not fully disabling)
          if (isManuallyClosed && !isEditMode)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text(
                        "Shop is Closed",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Toggle the switch above to open the shop",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isEditMode
          ? FloatingActionButton.extended(
              onPressed: saveAllChanges,
              backgroundColor: Colors.red,
              icon: isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildManualCloseCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isManuallyClosed
              ? [Colors.red.shade700, Colors.red.shade900]
              : [Colors.red.shade500, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: const Text(
          "Manual Override",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          isManuallyClosed
              ? "Shop is temporarily closed"
              : "Shop is open for business",
          style: const TextStyle(color: Colors.white70),
        ),
        value: isManuallyClosed,
        activeColor: Colors.white,
        onChanged: (val) async {
          setState(() => isManuallyClosed = val);
          setState(() => isUpdating = true);
          try {
            final success = await apiService.updateShopTimings(
              shopId: shopId,
              workingDays: workingDays,
              specialDays: specialDays,
              isManuallyClosed: val,
            );
            if (success && mounted) {
              await fetchShopData();
            }
          } catch (e) {
            print('Error updating manual close: $e');
          } finally {
            if (mounted) {
              setState(() => isUpdating = false);
            }
          }
        },
      ),
    );
  }

  Widget _buildRedWorkingDayCard(WorkingDay day) {
    final isEditing = isEditMode && editingDayIndex == day.weekday;
    final dayName = _getDayName(day.weekday);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isEditing
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() => editingDayIndex = null);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Open"),
                    value: day.isOpen,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      updateWorkingDayInTemp(day.copyWith(isOpen: val));
                    },
                  ),
                  if (day.isOpen) ...[
                    _buildRedTimePickerTile(
                      title: "Opening Time",
                      time: day.openTime,
                      icon: Icons.access_time,
                      onTap: () async {
                        final time = await _pickTime();
                        if (time != null) {
                          updateWorkingDayInTemp(day.copyWith(openTime: time));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildRedTimePickerTile(
                      title: "Closing Time",
                      time: day.closeTime,
                      icon: Icons.access_time,
                      onTap: () async {
                        final time = await _pickTime();
                        if (time != null) {
                          updateWorkingDayInTemp(day.copyWith(closeTime: time));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildRedBreaksSection(
                      breaks: day.breaks,
                      onAddBreak: () async {
                        final newBreak = await _showBreakDialog();
                        if (newBreak != null) {
                          updateWorkingDayInTemp(
                            day.copyWith(breaks: [...day.breaks, newBreak]),
                          );
                        }
                      },
                      onRemoveBreak: (index) {
                        final newBreaks = List<BreakTime>.from(day.breaks);
                        newBreaks.removeAt(index);
                        updateWorkingDayInTemp(day.copyWith(breaks: newBreaks));
                      },
                    ),
                  ],
                ],
              ),
            )
          : ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: day.isOpen ? Colors.red.shade50 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  day.isOpen ? Icons.check : Icons.close,
                  color: day.isOpen ? Colors.red : Colors.grey,
                  size: 24,
                ),
              ),
              title: Text(
                dayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: day.isOpen
                  ? Text(
                      "${_formatTimeOfDay(day.openTime)} - ${_formatTimeOfDay(day.closeTime)}${day.breaks.isNotEmpty ? " • ${day.breaks.length} break(s)" : ""}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    )
                  : const Text(
                      "Closed",
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
              trailing: isEditMode
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: Colors.red),
                      onPressed: () {
                        setState(() => editingDayIndex = day.weekday);
                      },
                    )
                  : null,
            ),
    );
  }

  Widget _buildRedSpecialDaysSection(List<SpecialDay> displaySpecialDays) {
    if (displaySpecialDays.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                "No special days configured",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              if (isEditMode) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showRedSpecialDayDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Special Day"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displaySpecialDays.length,
          itemBuilder: (context, index) {
            final day = displaySpecialDays[index];
            final isEditing = isEditMode && editingSpecialDayIndex == index;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: isEditing
                  ? _buildRedSpecialDayEditForm(index, day)
                  : ListTile(
                      leading: CircleAvatar(
                        backgroundColor: day.isOpen
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                        child: Icon(
                          day.isOpen ? Icons.celebration : Icons.block,
                          color: day.isOpen ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        DateFormat('EEEE, MMM d, yyyy').format(day.date),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: day.isOpen
                          ? Text(
                              "${_formatTimeOfDay(day.openTime)} - ${_formatTimeOfDay(day.closeTime)}",
                            )
                          : const Text(
                              "Closed",
                              style: TextStyle(color: Colors.red),
                            ),
                      trailing: isEditMode
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => editingSpecialDayIndex = index,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      deleteSpecialDayFromTemp(index),
                                ),
                              ],
                            )
                          : null,
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRedSpecialDayEditForm(int index, SpecialDay day) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(day.date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  setState(() => editingSpecialDayIndex = null);
                },
              ),
            ],
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Open on this day"),
            value: day.isOpen,
            activeColor: Colors.red,
            onChanged: (val) {
              updateSpecialDayInTemp(index, day.copyWith(isOpen: val));
            },
          ),
          if (day.isOpen) ...[
            _buildRedTimePickerTile(
              title: "Opening Time",
              time: day.openTime,
              icon: Icons.access_time,
              onTap: () async {
                final time = await _pickTime();
                if (time != null) {
                  updateSpecialDayInTemp(index, day.copyWith(openTime: time));
                }
              },
            ),
            const SizedBox(height: 8),
            _buildRedTimePickerTile(
              title: "Closing Time",
              time: day.closeTime,
              icon: Icons.access_time,
              onTap: () async {
                final time = await _pickTime();
                if (time != null) {
                  updateSpecialDayInTemp(index, day.copyWith(closeTime: time));
                }
              },
            ),
            const SizedBox(height: 12),
            _buildRedBreaksSection(
              breaks: day.breaks,
              onAddBreak: () async {
                final newBreak = await _showBreakDialog();
                if (newBreak != null) {
                  updateSpecialDayInTemp(
                    index,
                    day.copyWith(breaks: [...day.breaks, newBreak]),
                  );
                }
              },
              onRemoveBreak: (breakIndex) {
                final newBreaks = List<BreakTime>.from(day.breaks);
                newBreaks.removeAt(breakIndex);
                updateSpecialDayInTemp(index, day.copyWith(breaks: newBreaks));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRedTimePickerTile({
    required String title,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: Colors.grey.shade700)),
            ),
            Text(
              time == null ? "Select" : _formatTimeOfDay(time),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: time == null ? Colors.grey.shade500 : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildRedBreaksSection({
    required List<BreakTime> breaks,
    required VoidCallback onAddBreak,
    required Function(int) onRemoveBreak,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Break Periods",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: onAddBreak,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Break"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
        if (breaks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "No breaks scheduled",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          )
        else
          ...breaks.asMap().entries.map((entry) {
            final index = entry.key;
            final breakTime = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.free_breakfast,
                    size: 16,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${_formatTimeOfDay(breakTime.start)} - ${_formatTimeOfDay(breakTime.end)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemoveBreak(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRedSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (isEditMode && title == "Special Days")
          TextButton.icon(
            onPressed: () => _showRedSpecialDayDialog(),
            icon: const Icon(Icons.add, size: 18, color: Colors.red),
            label: const Text(
              "Add",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
      ],
    );
  }

  void _showRedSpecialDayDialog() {
    setState(() {
      selectedSpecialDate = null;
      specialDayIsOpen = true;
      specialOpenTime = null;
      specialCloseTime = null;
      specialBreaks = [];
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Add Special Day",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setStateModal(() => selectedSpecialDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedSpecialDate == null
                                ? "Select Date"
                                : DateFormat(
                                    'EEEE, MMM d, yyyy',
                                  ).format(selectedSpecialDate!),
                            style: TextStyle(
                              color: selectedSpecialDate == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Open on this day"),
                  value: specialDayIsOpen,
                  activeColor: Colors.red,
                  onChanged: (val) {
                    setStateModal(() => specialDayIsOpen = val);
                  },
                ),
                if (specialDayIsOpen) ...[
                  const SizedBox(height: 8),
                  _buildRedTimePickerTile(
                    title: "Opening Time",
                    time: specialOpenTime,
                    icon: Icons.sunny,
                    onTap: () async {
                      final time = await _pickTime();
                      if (time != null) {
                        setStateModal(() => specialOpenTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildRedTimePickerTile(
                    title: "Closing Time",
                    time: specialCloseTime,
                    icon: Icons.nightlight_round,
                    onTap: () async {
                      final time = await _pickTime();
                      if (time != null) {
                        setStateModal(() => specialCloseTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildRedBreaksSection(
                    breaks: specialBreaks,
                    onAddBreak: () async {
                      final newBreak = await _showBreakDialog();
                      if (newBreak != null) {
                        setStateModal(() {
                          specialBreaks = [...specialBreaks, newBreak];
                        });
                      }
                    },
                    onRemoveBreak: (index) {
                      setStateModal(() {
                        specialBreaks.removeAt(index);
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      addSpecialDayToTemp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Add Special Day",
                      style: TextStyle(color: Colors.white),
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

  Future<TimeOfDay?> _pickTime() async {
    return await showTimePicker(context: context, initialTime: TimeOfDay.now());
  }

  Future<BreakTime?> _showBreakDialog() async {
    TimeOfDay? start;
    TimeOfDay? end;

    return showDialog<BreakTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text(
              "Add Break Period",
              style: TextStyle(color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final time = await _pickTime();
                    if (time != null) {
                      setStateDialog(() => start = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            start == null
                                ? "Break Start Time"
                                : _formatTimeOfDay(start!),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final time = await _pickTime();
                    if (time != null) {
                      setStateDialog(() => end = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stop, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            end == null
                                ? "Break End Time"
                                : _formatTimeOfDay(end!),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (start != null && end != null) {
                    Navigator.pop(context, BreakTime(start: start!, end: end!));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday];
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
