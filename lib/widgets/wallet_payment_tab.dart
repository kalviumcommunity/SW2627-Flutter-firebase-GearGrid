import 'package:flutter/material.dart';
import '../theme/client_theme.dart';

class WalletPaymentTab extends StatelessWidget {
  const WalletPaymentTab({super.key});

  @override
  Widget build(BuildContext context) {
    const wallets = [
      ('Paytm Wallet', Color(0xFF00BAF2), Icons.account_balance_wallet_rounded),
      ('Amazon Pay', Color(0xFFFF9900), Icons.shopping_bag_outlined),
      ('Airtel Money', Color(0xFFE40000), Icons.sim_card_outlined),
      ('Jio Money', Color(0xFF0066CC), Icons.monetization_on_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: ClientTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ClientTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select wallet',
              style: ClientTheme.body(
                  color: ClientTheme.ink, size: 13, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...wallets.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ClientTheme.border)),
                  child: Row(children: [
                    Icon(w.$3, color: w.$2, size: 24),
                    const SizedBox(width: 12),
                    Text(w.$1,
                        style: ClientTheme.body(
                            color: ClientTheme.ink, weight: FontWeight.w700)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: ClientTheme.muted, size: 18),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}
