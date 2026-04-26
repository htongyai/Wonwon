import 'package:flutter/material.dart';

/// Earth-tone, editorial-leaning palette for the sustainability brand pass.
///
/// Coexists with [AppColors] / [AppConstants.primaryColor] — we don't rip out
/// the existing olive anchor. Use these where warmth and calm are the goal:
/// editorial heroes, impact cards, eco-badges, empty states.
class EcoPalette {
  EcoPalette._();

  // ── Surfaces ──────────────────────────────────────────────────────────────

  /// Warm cream — main background for editorial sections.
  /// Feels like aged paper vs. pure clinical white.
  static const Color surfaceLight = Color(0xFFFBF8F3);

  /// Bone / oatmeal — nested surface (cards on cream).
  static const Color surfaceDeep = Color(0xFFF1ECDF);

  /// Pale sage — secondary eco-oriented surface (callouts).
  static const Color surfaceLeafWash = Color(0xFFEFF3E9);

  // ── Ink ────────────────────────────────────────────────────────────────────

  /// Warm near-black — headlines, display type.
  static const Color inkPrimary = Color(0xFF1F1A13);

  /// Warm taupe — body copy, secondary text.
  static const Color inkSecondary = Color(0xFF6B5D4A);

  /// Muted clay — tertiary text, captions, metadata.
  static const Color inkMuted = Color(0xFF9B8C77);

  // ── Accents ───────────────────────────────────────────────────────────────

  /// Forest green — the sustainability accent. Used for eco-badges,
  /// impact metrics, "saved" moments.
  static const Color leaf = Color(0xFF4A6B3A);

  /// Lighter leaf — backgrounds for leaf-accented elements.
  static const Color leafWash = Color(0xFFD4DEC3);

  /// Olive — matches existing AppConstants.primaryColor for continuity.
  static const Color olive = Color(0xFFC3C130);

  /// Terracotta — error/destructive. Warmer than pure red.
  static const Color terracotta = Color(0xFFB8553A);

  /// Dune — warning / pending. Warmer than pure orange.
  static const Color dune = Color(0xFFC89264);

  // ── Divider + border ──────────────────────────────────────────────────────

  /// Whisper line for card borders, dividers.
  static const Color hairline = Color(0xFFE6DFD0);
}
