// lib/widgets/medicine_card.dart
import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTestVoice;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onToggle,
    required this.onDelete,
    required this.onTestVoice,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: medicine.enabled ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: medicine.enabled ? 3 : 1,
        shadowColor: const Color(0xFF6200EA).withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: medicine.enabled
              ? const BorderSide(color: Color(0xFF6200EA), width: 0.8)
              : BorderSide.none,
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left icon ─────────────────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),

              // ── Centre content ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      medicine.dosage,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF757575)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.access_time_rounded,
                          label: medicine.time,
                          bg: const Color(0xFFE8F5E9),
                          fg: const Color(0xFF2E7D32),
                        ),
                        _Chip(
                          icon: Icons.repeat_rounded,
                          label: medicine.frequencyLabel,
                          bg: const Color(0xFFE3F2FD),
                          fg: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Right actions ──────────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: medicine.enabled,
                    onChanged: (_) => onToggle(),
                    activeColor: const Color(0xFF6200EA),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded,
                            size: 20, color: Color(0xFF6200EA)),
                        tooltip: 'Test voice',
                        onPressed: onTestVoice,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: Color(0xFFD32F2F)),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medicine'),
        content: Text(
            'Remove ${medicine.name} from your reminder list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  const _Chip(
      {required this.icon,
      required this.label,
      required this.bg,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
