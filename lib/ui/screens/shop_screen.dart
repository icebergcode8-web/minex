import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/board_skin.dart';
import '../../domain/models/piece_skin.dart';
import '../../domain/models/shop_item.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/economy_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coins_pill.dart';

/// Tienda offline (plan §3.2): recargas de ítems, skins de tablero y de piezas.
/// Solo monedas del juego (sin compras reales en v1).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.shopTitle),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: CoinsPill()),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l.shopTabItems),
              Tab(text: l.shopTabBoards),
              Tab(text: l.shopTabPieces),
            ],
          ),
        ),
        body: AppBackground(
          child: TabBarView(
            children: [
              _ItemsTab(),
              _BoardSkinsTab(),
              _PieceSkinsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra un aviso breve y, si se compró, reevalúa logros de colección.
Future<void> _handlePurchase(BuildContext context, bool bought) async {
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (!bought) {
    messenger.showSnackBar(SnackBar(content: Text(l.shopNotEnough)));
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(l.shopPurchased)));
  // Logros de colección ("Coleccionista", "Esteta") pueden cumplirse al comprar.
  final result = await context.read<AchievementsProvider>().reevaluate();
  if (result.coins > 0 && context.mounted) {
    await context.read<EconomyProvider>().addCoins(result.coins);
  }
}

class _ItemsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final l = AppLocalizations.of(context)!;
    final locale = l.localeName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final c in ShopConsumable.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title(context, c.displayName(locale)),
                        const SizedBox(height: 2),
                        _sub(context, c.description(locale)),
                        const SizedBox(height: 4),
                        _sub(context, l.shopInStock(economy.consumableCount(c))),
                      ],
                    ),
                  ),
                  _BuyButton(
                    cost: c.cost,
                    onBuy: () async {
                      final bought =
                          await context.read<EconomyProvider>().buyConsumable(c);
                      if (context.mounted) await _handlePurchase(context, bought);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BoardSkinsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final l = AppLocalizations.of(context)!;
    final locale = l.localeName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final s in BoardSkin.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkinTile(
              emoji: s.emoji,
              name: s.displayName(locale),
              cost: s.cost,
              owned: economy.ownsBoardSkin(s),
              equipped: economy.equippedBoardSkin == s,
              onBuy: () async {
                final ok = await context.read<EconomyProvider>().buyBoardSkin(s);
                if (ok && context.mounted) {
                  await context.read<EconomyProvider>().equipBoardSkin(s);
                }
                if (context.mounted) await _handlePurchase(context, ok);
              },
              onEquip: () =>
                  context.read<EconomyProvider>().equipBoardSkin(s),
            ),
          ),
      ],
    );
  }
}

class _PieceSkinsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final l = AppLocalizations.of(context)!;
    final locale = l.localeName;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final s in PieceSkin.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkinTile(
              emoji: s.emoji,
              name: s.displayName(locale),
              cost: s.cost,
              owned: economy.ownsPieceSkin(s),
              equipped: economy.equippedPieceSkin == s,
              onBuy: () async {
                final ok = await context.read<EconomyProvider>().buyPieceSkin(s);
                if (ok && context.mounted) {
                  await context.read<EconomyProvider>().equipPieceSkin(s);
                }
                if (context.mounted) await _handlePurchase(context, ok);
              },
              onEquip: () =>
                  context.read<EconomyProvider>().equipPieceSkin(s),
            ),
          ),
      ],
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.emoji,
    required this.name,
    required this.cost,
    required this.owned,
    required this.equipped,
    required this.onBuy,
    required this.onEquip,
  });

  final String emoji;
  final String name;
  final int cost;
  final bool owned;
  final bool equipped;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;
    return AppCard(
      accent: palette.primary,
      selected: equipped,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(child: _title(context, name)),
          if (equipped)
            _Tag(text: l.shopEquipped, color: palette.primary)
          else if (owned)
            _ActionButton(label: l.shopEquip, onTap: onEquip)
          else
            _BuyButton(cost: cost, onBuy: onBuy),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.cost, required this.onBuy});
  final int cost;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _ActionButton(
      onTap: onBuy,
      color: palette.secondary,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$cost',
            style: AppTheme.mono(
              fontSize: 14,
              color: palette.onAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    this.label,
    this.child,
    this.color,
  });

  final VoidCallback onTap;
  final String? label;
  final Widget? child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = color ?? palette.primary;
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: child ??
              Text(
                label!,
                style: TextStyle(
                  color: palette.onAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

Widget _title(BuildContext context, String text) => Text(
      text,
      style: TextStyle(
        color: context.palette.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );

Widget _sub(BuildContext context, String text) => Text(
      text,
      style: TextStyle(color: context.palette.textMuted, fontSize: 12),
    );