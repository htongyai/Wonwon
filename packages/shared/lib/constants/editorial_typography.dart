import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/eco_palette.dart';

/// Editorial-leaning typography scale for the sustainability brand pass.
///
/// Two voices:
///  * **Display** (`DM Serif Display`) — hero titles, story headlines,
///    "moment" copy. Carries weight and warmth.
///  * **Body** (`Inter`) — everything else. Kept from existing system.
///
/// Small-caps eyebrows are used for category intros and section labels.
class EditorialTypography {
  EditorialTypography._();

  // ── Display (serif) ───────────────────────────────────────────────────────

  static TextStyle get displayHero => GoogleFonts.dmSerifDisplay(
        fontSize: 34,
        height: 1.15,
        letterSpacing: -0.8,
        color: EcoPalette.inkPrimary,
      );

  static TextStyle get displayLarge => GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.5,
        color: EcoPalette.inkPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.dmSerifDisplay(
        fontSize: 22,
        height: 1.25,
        letterSpacing: -0.3,
        color: EcoPalette.inkPrimary,
      );

  /// For short pull-quotes (shop stories, manifesto lines).
  static TextStyle get displayQuote => GoogleFonts.dmSerifDisplay(
        fontSize: 18,
        height: 1.45,
        letterSpacing: -0.2,
        fontStyle: FontStyle.italic,
        color: EcoPalette.inkPrimary,
      );

  // ── Eyebrow labels ────────────────────────────────────────────────────────

  /// Tiny all-caps section label — "REPAIR STORY", "THIS MONTH".
  static TextStyle get eyebrow => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: EcoPalette.inkSecondary,
      );

  /// Eyebrow with leaf tint — reserved for sustainability callouts.
  static TextStyle get eyebrowLeaf => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: EcoPalette.leaf,
      );

  // ── Body scale ────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        height: 1.55,
        color: EcoPalette.inkPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        height: 1.55,
        color: EcoPalette.inkSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 1.4,
        color: EcoPalette.inkMuted,
      );

  // ── Numeric (impact metrics) ──────────────────────────────────────────────

  /// Large numeric for impact cards — "4.2 kg". Tabular figures for alignment.
  static TextStyle get metricLarge => GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        height: 1.0,
        letterSpacing: -0.8,
        color: EcoPalette.leaf,
      );

  /// Medium numeric — shop savings chip, etc.
  static TextStyle get metricSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: EcoPalette.leaf,
      );
}
