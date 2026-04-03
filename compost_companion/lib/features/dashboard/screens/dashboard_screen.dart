import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/data/models/dashboard_pile.dart';
import 'package:compost_companion/data/services/auth_service.dart';
import 'package:compost_companion/data/services/compost_service.dart';
import 'package:compost_companion/data/services/pile_ingredient_store.dart';
import 'package:compost_companion/features/auth/screens/login_screen.dart';
import 'package:compost_companion/features/dashboard/widgets/compost_pile_card.dart';
import 'notification_screen.dart';
import 'pile_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<DashboardPile>> _futurePiles;
  final _authService = AuthService();
  final _service = CompostService();
  final _pileIngredientStore = PileIngredientStore();
  final Set<int> _deletingPileIds = <int>{};

  @override
  void initState() {
    super.initState();
    _futurePiles = _service.fetchDashboardData();
  }
  void _refreshPiles() {
    setState(() {
      _futurePiles = _service.fetchDashboardData();
    });
  }

  Future<void> _handleRefresh() async {
    final next = _service.fetchDashboardData();
    setState(() {
      _futurePiles = next;
    });

    try {
      await next;
    } catch (_) {
      // Keep behavior consistent with FutureBuilder error rendering.
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will need to sign in again to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    _authService.logout();
    await _pileIngredientStore.clearAllPileIngredients();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmAndDeletePile(DashboardPile pile) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete pile?'),
          content: Text('Are you sure you want to delete "${pile.name}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDB181B)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true || !mounted) {
      return;
    }

    setState(() {
      _deletingPileIds.add(pile.id);
    });

    try {
      await _service.deleteCompostPile(pile.id);
      await _pileIngredientStore.deletePileIngredients(pile.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${pile.name}"'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshPiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete pile: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _deletingPileIds.remove(pile.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: FutureBuilder<List<DashboardPile>>(
            future: _futurePiles,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              if (snapshot.hasError) {
                // global failure fetching piles
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 80),
                    Center(child: Text('Error: ${snapshot.error}')),
                  ],
                );
              }
              final piles = snapshot.data ?? [];
              if (piles.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 80),
                    const Center(child: Text('No compost piles found.')),
                  ],
                );
              }
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header with notification, logo, and title
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Next Action Card
                    _buildNextActionCard(),
                    const SizedBox(height: 40),

                    // Pile Cards List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (int i = 0; i < piles.length; i++) ...[
                            CompostPileCard(
                              pile: piles[i],
                              deleteInProgress: _deletingPileIds.contains(piles[i].id),
                              onDelete: () => _confirmAndDeletePile(piles[i]),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PileDetailsScreen(
                                      pileId: piles[i].id,
                                      pileName: piles[i].name,
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                _refreshPiles();
                              },
                            ),
                            if (i < piles.length - 1) const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            child: SvgPicture.asset('assets/I64-321;7758-11128.svg', width: 24, height: 24),
          ),
          const Spacer(),
          Image.asset('assets/102-213.webp', width: 50, height: 50),
          const SizedBox(width: 12),
          const Text(
            'My Piles',
            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            onPressed: _refreshPiles,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionCard() {
    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next Action',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SvgPicture.asset('assets/88-213.svg', width: 32, height: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Turn Pile',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Tomorrow 9:00 AM',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}