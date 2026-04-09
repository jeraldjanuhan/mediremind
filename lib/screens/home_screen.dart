// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../services/storage_service.dart';
import '../widgets/add_medicine_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/medicine_card.dart';
import '../widgets/notification_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  Expanded(child: _buildBody(provider)),
                ],
              ),
              // In-app notification banner
              if (provider.currentAlert != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: NotificationBanner(
                      medicine: provider.currentAlert!,
                      onTaken: provider.dismissAlert,
                      onSnooze: provider.snoozeAlert,
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _currentTab == 0
              ? _buildFab(provider)
              : null,
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () {},
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'MediRemind',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(MedicineProvider provider) {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab(provider);
      case 1:
        return _buildScheduleTab(provider);
      case 2:
        return _buildHistoryTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildHomeTab(provider);
    }
  }

  Widget _buildHomeTab(MedicineProvider provider) {
    final today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    if (provider.medicines.isEmpty) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6200EA).withOpacity(0.08),
                  const Color(0xFF9C27B0).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF6200EA).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Color(0xFF6200EA), size: 20),
                const SizedBox(width: 10),
                Text(
                  today,
                  style: const TextStyle(
                    color: Color(0xFF6200EA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: EmptyState()),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6200EA).withOpacity(0.08),
                  const Color(0xFF9C27B0).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF6200EA).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Color(0xFF6200EA), size: 20),
                const SizedBox(width: 10),
                Text(
                  today,
                  style: const TextStyle(
                    color: Color(0xFF6200EA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6200EA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${provider.medicines.where((m) => m.enabled).length} Active',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final medicine = provider.medicines[i];
              return MedicineCard(
                medicine: medicine,
                onToggle: () => provider.toggleMedicine(medicine.id),
                onDelete: () => provider.deleteMedicine(medicine.id),
                onTestVoice: () => provider.testVoice(medicine),
              );
            },
            childCount: provider.medicines.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildScheduleTab(MedicineProvider provider) {
    final enabled = provider.medicines.where((m) => m.enabled).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Today's Schedule",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121)),
        ),
        const SizedBox(height: 12),
        if (enabled.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text(
                'No active reminders scheduled.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...enabled.map((m) => _ScheduleItem(medicine: m)),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Color(0xFFBDBDBD)),
            SizedBox(height: 16),
            Text(
              'History',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242)),
            ),
            SizedBox(height: 8),
            Text(
              'Medicine taken history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121)),
        ),
        const SizedBox(height: 16),
        _SettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.volume_up_rounded,
          title: 'Voice Alerts',
          subtitle: 'Text-to-speech reminder settings',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.battery_saver_rounded,
          title: 'Battery Optimization',
          subtitle:
              'Disable battery optimization for reliable background alarms',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'About MediRemind',
          subtitle: 'Version 1.0.0',
          onTap: () {},
        ),
      ],
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentTab,
      onTap: (i) => setState(() => _currentTab = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF6200EA),
      unselectedItemColor: Colors.grey.shade500,
      backgroundColor: Colors.white,
      elevation: 8,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule_rounded),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab(MedicineProvider provider) {
    return FloatingActionButton(
      onPressed: () => _showAddDialog(provider),
      elevation: 4,
      shape: const CircleBorder(),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6200EA).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Future<void> _showAddDialog(MedicineProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddMedicineDialog(),
    );

    if (result == null) return;

    final alarmId = await StorageService.instance.nextAlarmId();
    final medicine = Medicine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: result['name'] as String,
      dosage: result['dosage'] as String,
      frequency: result['frequency'] as String,
      time: result['time'] as String,
      alarmId: alarmId,
    );

    await provider.addMedicine(medicine);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medicine.name} reminder added!'),
          backgroundColor: const Color(0xFF6200EA),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _ScheduleItem extends StatelessWidget {
  final Medicine medicine;
  const _ScheduleItem({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6200EA).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(medicine.time,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6200EA))),
        ),
        title: Text(medicine.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${medicine.dosage} · ${medicine.frequencyLabel}'),
        trailing: const Icon(Icons.alarm_on_rounded,
            color: Color(0xFF6200EA)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6200EA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6200EA), size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
