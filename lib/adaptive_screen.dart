import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdaptiveScreen extends StatelessWidget {
  const AdaptiveScreen({super.key});

  bool get isCupertino {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  @override
  Widget build(BuildContext context) {
    final useCupertino = isCupertino;

    final dashboardBody = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 220,
                    child: _Sidebar(cupertino: useCupertino),
                  ),
                  Expanded(child: _DashboardContent(isWide: isWide)),
                ],
              )
            : _DashboardContent(isWide: isWide);

        // Web gets mouse-friendly behavior.
        return MouseRegion(
          //cursor: kIsWeb ? SystemMouseCursors.basic : SystemMouseCursors.defer,
          child: content,
        );
      },
    );

    if (useCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Dashboard')),
        child: SafeArea(child: dashboardBody),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: dashboardBody,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool cupertino;

  const _Sidebar({required this.cupertino});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      (Icons.dashboard_outlined, 'Overview'),
      (Icons.analytics_outlined, 'Analytics'),
      (Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      color: cupertino
          ? CupertinoColors.systemGroupedBackground
          : Colors.grey.shade200,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MENU', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            ...menuItems.map(
              (item) => cupertino
                  ? CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.centerLeft,
                      onPressed: () {},
                      child: Row(
                        children: [
                          Icon(item.$1),
                          const SizedBox(width: 16),
                          Text(item.$2),
                        ],
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(item.$1),
                        title: Text(item.$2),
                        onTap: () {},
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final bool isWide;

  const _DashboardContent({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Wireframe statistic cards.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: isWide ? 110 : 90,
            ),
            itemBuilder: (context, index) {
              const cards = [
                _WireframeCard(title: 'TOTAL USERS', value: '1,248'),
                _WireframeCard(title: 'ACTIVE PROJECTS', value: '36'),
                _WireframeCard(title: 'PENDING TASKS', value: '12'),
              ];

              return cards[index];
            },
          ),

          const SizedBox(height: 24),

          // Main wireframe panel.
          Container(
            width: double.infinity,
            height: 260,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVITY OVERVIEW',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Icon(Icons.bar_chart, size: 100, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lower panels stack on narrow screens.
          Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isWide ? 1 : 0,
                child: const _Panel(
                  title: 'RECENT ACTIVITY',
                  content: 'No recent activity',
                ),
              ),
              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
              Expanded(
                flex: isWide ? 1 : 0,
                child: const _Panel(
                  title: 'UPCOMING TASKS',
                  content: 'No upcoming tasks',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WireframeCard extends StatelessWidget {
  final String title;
  final String value;

  const _WireframeCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String content;

  const _Panel({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Center(child: Text(content)),
        ],
      ),
    );
  }
}
