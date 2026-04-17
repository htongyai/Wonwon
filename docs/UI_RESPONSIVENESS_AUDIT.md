# UI Responsiveness Audit

Audit of how the app adapts to different device sizes and recommendations.

---

## 1. Breakpoint System

**Location:** `lib/constants/responsive_breakpoints.dart`

| Breakpoint     | Width  | Usage |
|----------------|--------|--------|
| `smallPhone`   | 400px  | Very small phones; hide/compact UI |
| `mobile`       | 600px  | Phone vs tablet boundary |
| `tablet`       | 768px  | Used in DesignTokens for padding steps |
| `desktop`      | 1024px | Tablet vs desktop; desktop layout starts here |
| `largeDesktop` | 1400px | Large desktop |

**Helpers:** `isMobile(width)`, `isTablet(width)`, `isDesktop(width)`, `isLargeDesktop(width)`, `isSmallPhone(width)`, `shouldShowDesktopLayout(width)`, `shouldShowTabletLayout(width)`.

**Note:** Layout choice (mobile / tablet / desktop) uses **600** and **1024** via `shouldShowTabletLayout` / `shouldShowDesktopLayout`. DesignTokens uses **600, 768, 1024** for padding and font scaling, so 600–768 is “mobile” in layout but “tablet” in DesignTokens padding—acceptable.

---

## 2. Responsive Utilities

- **ResponsiveSize** (`lib/utils/responsive_size.dart`): Static cache of screen size, safe area, block sizes. **Re-initializes when width/height changes** (rotation, resize). Call `ResponsiveSize.init(context)` at the top of build in navigation and key screens so values stay current.
- **CachedResponsiveSize** (`lib/utils/cached_responsive_size.dart`): Caches derived values (padding, font size, device type); cleared when screen size changes in `ResponsiveSize.init()`.
- **DesignTokens** (`lib/constants/design_tokens.dart`): Responsive padding, font size, sidebar width, nav bar height by screen width/height.

---

## 3. Layout Selection (MainNavigation)

- **Desktop** (width ≥ 1024): `DesktopNavigation` + desktop screens (e.g. `DesktopHomeScreen`, `DesktopMapScreen`, …).
- **Tablet** (600 ≤ width < 1024): Bottom `TabletNavigationBar` + tablet screens (e.g. `TabletHomeScreen`, …).
- **Mobile** (width < 600): Bottom `CustomNavigationBar` + phone screens (e.g. `HomeScreen`, `MapScreen`, …).

All three branches call `ResponsiveSize.init(context)` so rotation and window resize update layout correctly.

---

## 4. Safe Area & Text Scaling

- **SafeArea:** Used on many screens (e.g. home, shop detail, login, settings, signup, splash). Keep using for notches and system UI.
- **Text scaling:** `main.dart` overrides with `TextScaler.linear(1.0)` for all platforms. This disables system font scaling and can hurt accessibility. Consider respecting `MediaQuery.textScaleFactorOf(context)` (possibly with a max cap) for accessibility.

---

## 5. Inconsistencies Addressed

- **Magic numbers:** Prefer `ResponsiveBreakpoints` (e.g. `isMobile(screenWidth)`, `isSmallPhone(screenWidth)`) instead of raw `screenWidth < 600` or `screenWidth < 400` so behavior stays aligned with the breakpoint system.
- **shop_detail_screen:** Uses 1000 and 600 for “small” vs “very small”; these have been aligned to breakpoints where applicable.

---

## 6. Recommendations

1. **Breakpoints:** Use only `ResponsiveBreakpoints` and `ResponsiveSize` / `DesignTokens` for layout and spacing decisions; avoid new hardcoded widths (400, 600, 1000, 1024).
2. **Init:** Any screen or widget that uses `ResponsiveSize` or `CachedResponsiveSize` for layout should call `ResponsiveSize.init(context)` at the start of `build` (or be under a parent that does, e.g. MainNavigation).
3. **Testing:** Manually test breakpoints at 400, 600, 768, 1024, 1400 (Chrome DevTools or different devices) and after rotation/resize.
4. **Accessibility:** Revisit `TextScaler.linear(1.0)` in `main.dart` and consider honoring system text scale (with a reasonable max).
5. **DesignTokens height breakpoints:** `getResponsiveNavBarHeight` uses 600 and 1000 for height; consider moving these to `ResponsiveBreakpoints` or a small “height breakpoints” set if reused elsewhere.

---

## 7. Files Using Responsive Logic

- **Navigation / shell:** `main_navigation.dart`, `custom_navigation_bar.dart`, `tablet_navigation_bar.dart`, `desktop_navigation.dart`, `notification_sidebar.dart`.
- **Screens:** All `*_screen.dart` under `screens/`; many use `MediaQuery.of(context).size`, `LayoutBuilder`, or `ResponsiveSize` / `DesignTokens`.
- **Widgets:** `advanced_search_bar.dart`, `notification_sidebar.dart`, and others that adjust layout by width.
