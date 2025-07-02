import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart' show getInitials;
import 'package:employee_management/features/presentation/state/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = getIt<ProfileController>();
    _profileController.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: theme.colorScheme.onPrimary,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.only(top: 24),
        child: ValueListenableBuilder(
          valueListenable: _profileController.profileApiState,
          builder: (context, profileState, _) {
            if (profileState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (profileState.isError) {
              return Text(
                profileState.error ?? 'An error occurred',
                style: TextStyle(color: theme.colorScheme.error),
              );
            } else if (profileState.isSuccess) {
              final profile = profileState.data;
              if (profile == null) {
                return const Text('No profile data found.');
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: size.width * 0.18,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          getInitials(profile.first_name, profile.last_name),
                          style: TextStyle(
                            fontSize: size.width * 0.10,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _ProfileField(
                        label: 'Name',
                        value: '${profile.first_name} ${profile.last_name}',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _ProfileField(
                        label: 'Email',
                        value: profile.email,
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 16),
                      _ProfileField(
                        label: 'Date of Birth',
                        value: profile.dob,
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 16),
                      _ProfileField(
                        label: 'Phone Number',
                        value: profile.phoneNo.toString(),
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 16),
                      _ProfileField(
                        label: 'Designation',
                        value: profile.designation,
                        icon: Icons.work,
                      ),
                      const SizedBox(height: 16),
                      _ProfileField(
                        label: 'Organization',
                        value: profile.organization,
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon:  Icon(Icons.logout, size: 22.sp,),
                          label: Text('Logout', style: TextStyle(fontSize: 18.sp),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            await _profileController.logout();
                            getIt<GlobalKey<NavigatorState>>().currentState
                                ?.pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// Helper widget for profile fields
class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
