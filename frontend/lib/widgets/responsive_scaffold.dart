import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../screens/dashboard_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/request_status_screen.dart';
import '../screens/work_schedule_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/problem_products_screen.dart';
import '../screens/inventory_issue_form.dart';
import '../screens/product_update_form.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget? body;

  const ResponsiveScaffold({Key? key, this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 800;

    // List of screens corresponding to bottom navigation / sidebar tabs
    final List<Widget> screens = [
      const DashboardScreen(),         // 0 — All roles
      const ProductListScreen(),        // 1 — Sales Associate only
      const RequestStatusScreen(),      // 2 — All roles
      const WorkScheduleScreen(),       // 3 — All roles
      const ProfileScreen(),            // 4 — All roles
      const RequestStatusScreen(filterType: RequestType.leave),     // 5 — All roles
      const RequestStatusScreen(filterType: RequestType.shiftSwap), // 6 — All roles
      const ProblemProductsScreen(),    // 7 — Sales Associate only
      const InventoryIssueForm(),       // 8 — Sales Associate only
      const ProductUpdateForm(),        // 9 — Sales Associate only
    ];

    final bool isSalesAssociate = appState.currentUser.role == UserRole.associate;
    // Clamp tab index: non-SA roles should not land on SA-only screens
    if (!isSalesAssociate && appState.currentTabIndex > 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) => appState.setTabIndex(0));
    }

    Widget currentScreen = body ?? screens[appState.currentTabIndex];

    if (isDesktop) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Row(
          children: [
            // Desktop Sidebar Navigation
            _buildSidebar(context, appState),
            // Main Canvas Area
            Expanded(
              child: Column(
                children: [
                  // Top Navbar (Header)
                  _buildTopNavbar(context, appState),
                  // Screen content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: currentScreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Layout
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(appState.currentUser.imageUrl),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Good Morning,',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                appState.currentUser.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_none),
                  if (appState.notifications.any((n) => !n.isRead))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: currentScreen,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: appState.currentTabIndex,
            onTap: (index) => appState.setTabIndex(index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurfaceVariant,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_turned_in_outlined),
                activeIcon: Icon(Icons.assignment_turned_in),
                label: 'Status',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTopNavbar(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumbs
          Row(
            children: [
              Text(
                'Home',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Text(
                _getTabName(appState.currentTabIndex),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // User Details / Notifications
          Row(
            children: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none),
                    if (appState.notifications.any((n) => !n.isRead))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 32,
                color: theme.dividerColor.withOpacity(0.08),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    appState.currentUser.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    appState.currentUser.title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(appState.currentUser.imageUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final bool isSalesAssociate = appState.currentUser.role == UserRole.associate;
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'SMS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // ── Universal Nav Items ──
                _buildSidebarItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                  currentIndex: appState.currentTabIndex,
                  onTap: () => appState.setTabIndex(0),
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.assignment_turned_in_outlined,
                  activeIcon: Icons.assignment_turned_in,
                  label: 'Status / Requests',
                  index: 2,
                  currentIndex: appState.currentTabIndex,
                  onTap: () => appState.setTabIndex(2),
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Work Schedule',
                  index: 3,
                  currentIndex: appState.currentTabIndex,
                  onTap: () => appState.setTabIndex(3),
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.exit_to_app_outlined,
                  activeIcon: Icons.exit_to_app,
                  label: 'Leave Requests',
                  index: 5,
                  currentIndex: appState.currentTabIndex,
                  onTap: () => appState.setTabIndex(5),
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.published_with_changes_outlined,
                  activeIcon: Icons.published_with_changes,
                  label: 'Schedule Change Requests',
                  index: 6,
                  currentIndex: appState.currentTabIndex,
                  onTap: () => appState.setTabIndex(6),
                ),
                _buildSidebarItem(
                  context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'My Profile',
                  index: 4,
                  currentIndex: appState.currentTabIndex,
                  onTap: () => appState.setTabIndex(4),
                ),

                // ── Sales Associate Only ──
                if (isSalesAssociate) ..._buildSalesAssociateNav(context, appState),
              ],
            ),
          ),
          // Footer settings
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings opened')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Support'),
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support center opened')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isActive = index == currentIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      child: ListTile(
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isActive,
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: onTap,
      ),
    );
  }

  List<Widget> _buildSalesAssociateNav(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SALES TOOLS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
      _buildSidebarItem(
        context,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Product List',
        index: 1,
        currentIndex: appState.currentTabIndex,
        onTap: () => appState.setTabIndex(1),
      ),
      _buildSidebarItem(
        context,
        icon: Icons.warning_amber_outlined,
        activeIcon: Icons.warning_amber_rounded,
        label: 'Problem Products',
        index: 7,
        currentIndex: appState.currentTabIndex,
        onTap: () => appState.setTabIndex(7),
      ),
      _buildSidebarItem(
        context,
        icon: Icons.report_problem_outlined,
        activeIcon: Icons.report_problem,
        label: 'Inventory Issue Report',
        index: 8,
        currentIndex: appState.currentTabIndex,
        onTap: () => appState.setTabIndex(8),
      ),
      _buildSidebarItem(
        context,
        icon: Icons.edit_note_outlined,
        activeIcon: Icons.edit_note,
        label: 'Product Update Suggestion',
        index: 9,
        currentIndex: appState.currentTabIndex,
        onTap: () => appState.setTabIndex(9),
      ),
    ];
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Inventory';
      case 2:
        return 'Request Status';
      case 3:
        return 'Work Schedule';
      case 4:
        return 'My Profile';
      case 5:
        return 'Leave Requests';
      case 6:
        return 'Schedule Change Requests';
      case 7:
        return 'Problem Products';
      case 8:
        return 'Inventory Issue Report';
      case 9:
        return 'Product Update Suggestion';
      default:
        return 'GreenMart SMS';
    }
  }
}
