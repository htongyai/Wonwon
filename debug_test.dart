import 'lib/constants/design_tokens.dart';

void main() {
  // ignore: avoid_print
  print('Debugging DesignTokens values:');

  // Test padding values
  // ignore: avoid_print
  print('Mobile (300px): ${DesignTokens.getResponsivePadding(300)}');
  // ignore: avoid_print
  print('Tablet (700px): ${DesignTokens.getResponsivePadding(700)}');
  // ignore: avoid_print
  print('Desktop (1200px): ${DesignTokens.getResponsivePadding(1200)}');
  // ignore: avoid_print
  print('Large Desktop (1920px): ${DesignTokens.getResponsivePadding(1920)}');

  // Test font size values
  const baseSize = 16.0;
  // ignore: avoid_print
  print(
    'Mobile font (300px): ${DesignTokens.getResponsiveFontSize(baseSize, 300)}',
  );
  // ignore: avoid_print
  print(
    'Tablet font (700px): ${DesignTokens.getResponsiveFontSize(baseSize, 700)}',
  );
  // ignore: avoid_print
  print(
    'Desktop font (1200px): ${DesignTokens.getResponsiveFontSize(baseSize, 1200)}',
  );
  // ignore: avoid_print
  print(
    'Large Desktop font (1920px): ${DesignTokens.getResponsiveFontSize(baseSize, 1920)}',
  );

  // Test breakpoint values
  // ignore: avoid_print
  print('Breakpoints:');
  // ignore: avoid_print
  print('Mobile: < 600');
  // ignore: avoid_print
  print('Tablet: 600-1024');
  // ignore: avoid_print
  print('Desktop: 1024-1400');
  // ignore: avoid_print
  print('Large Desktop: > 1400');
}
