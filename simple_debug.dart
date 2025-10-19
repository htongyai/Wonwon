import 'lib/constants/responsive_breakpoints.dart';

void main() {
  print('Breakpoint values:');
  print('Mobile: ${ResponsiveBreakpoints.mobile}');
  print('Tablet: ${ResponsiveBreakpoints.tablet}');
  print('Desktop: ${ResponsiveBreakpoints.desktop}');
  print('Large Desktop: ${ResponsiveBreakpoints.largeDesktop}');

  print('\nFor 700px:');
  print('700 < 600: ${700 < ResponsiveBreakpoints.mobile}');
  print('700 < 768: ${700 < ResponsiveBreakpoints.tablet}');
  print('700 < 1024: ${700 < ResponsiveBreakpoints.desktop}');
  print('700 >= 1400: ${700 >= ResponsiveBreakpoints.largeDesktop}');
}
