import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Known eco-badges shops can earn (admin-verified). Keeping this as a
/// single source of truth so UI and admin tools stay in sync.
enum EcoBadgeId {
  certifiedRepairer,
  usesReclaimedMaterials,
  zeroWastePractice,
  lifetimeWarranty,
  localArtisan,
}

extension EcoBadgeIdExt on EcoBadgeId {
  String get key {
    switch (this) {
      case EcoBadgeId.certifiedRepairer:
        return 'certified_repairer';
      case EcoBadgeId.usesReclaimedMaterials:
        return 'uses_reclaimed_materials';
      case EcoBadgeId.zeroWastePractice:
        return 'zero_waste_practice';
      case EcoBadgeId.lifetimeWarranty:
        return 'lifetime_warranty';
      case EcoBadgeId.localArtisan:
        return 'local_artisan';
    }
  }

  IconData get icon {
    switch (this) {
      case EcoBadgeId.certifiedRepairer:
        return Icons.workspace_premium_rounded;
      case EcoBadgeId.usesReclaimedMaterials:
        return Icons.recycling_rounded;
      case EcoBadgeId.zeroWastePractice:
        return Icons.eco_rounded;
      case EcoBadgeId.lifetimeWarranty:
        return Icons.verified_rounded;
      case EcoBadgeId.localArtisan:
        return Icons.handshake_rounded;
    }
  }
}

/// Pill-shaped eco-badge with a leaf-tinted look.
class EcoBadge extends StatelessWidget {
  final String id;
  const EcoBadge({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badge = EcoBadgeId.values.firstWhere(
      (e) => e.key == id,
      orElse: () => EcoBadgeId.certifiedRepairer,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EcoPalette.leafWash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoPalette.leaf.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 13, color: EcoPalette.leaf),
          const SizedBox(width: 6),
          Text(
            'eco_badge_${badge.key}'.tr(context),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: EcoPalette.leaf,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a list of badge ids into a rendered Wrap row.
class EcoBadgesRow extends StatelessWidget {
  final List<String> badgeIds;
  const EcoBadgesRow({Key? key, required this.badgeIds}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badgeIds.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badgeIds.map((id) => EcoBadge(id: id)).toList(),
    );
  }
}
