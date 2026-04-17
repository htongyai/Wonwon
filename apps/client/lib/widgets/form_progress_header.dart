import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Shows live progress for a long form.
///
/// Renders a linear progress bar, a "N of M complete" summary, and a list
/// of section checks (filled vs. remaining). Computes progress from a list
/// of [FormSectionProgress] passed by the parent each build.
class FormProgressHeader extends StatelessWidget {
  final List<FormSectionProgress> sections;

  const FormProgressHeader({Key? key, required this.sections}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = sections.fold<int>(0, (n, s) => n + s.required);
    final done = sections.fold<int>(0, (n, s) => n + s.completed);
    final percent = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final remaining = (total - done).clamp(0, total);
    final isComplete = remaining == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? Colors.green.shade300
              : AppConstants.primaryColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete
                    ? Icons.check_circle_rounded
                    : Icons.pending_actions_rounded,
                size: 20,
                color: isComplete
                    ? Colors.green.shade600
                    : AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComplete
                      ? 'form_ready_to_submit'.tr(context)
                      : 'form_progress_title'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkColor,
                  ),
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isComplete
                      ? Colors.green.shade600
                      : AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: percent,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete
                    ? Colors.green.shade500
                    : AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? 'form_all_required_done'.tr(context)
                : 'form_fields_remaining'
                    .tr(context)
                    .replaceFirst('{n}', '$remaining'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          // Section chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sections
                .map((s) => _SectionChip(section: s))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final FormSectionProgress section;
  const _SectionChip({required this.section});

  @override
  Widget build(BuildContext context) {
    final done = section.completed >= section.required;
    final color = done ? Colors.green.shade500 : Colors.grey.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            section.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: done
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Describes the completion state of a single form section.
class FormSectionProgress {
  final String label;
  final int required;
  final int completed;

  const FormSectionProgress({
    required this.label,
    required this.required,
    required this.completed,
  });
}
