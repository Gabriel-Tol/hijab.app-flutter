import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/order.dart';
import '../../state/order_controller.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/status_pill.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderController>();

    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(title: const Text('Pesanan Saya')),
        body: Column(
          children: [
            _filters(orders),
            Expanded(child: _body(orders)),
          ],
        ),
      ),
    );
  }

  Widget _filters(OrderController orders) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Row(
        children: [
          _chip(
            key: const Key('order-filter-all'),
            label: 'Semua',
            selected: orders.statusFilter == null,
            onSelected: () => orders.setStatusFilter(null),
          ),
          for (final status in OrderStatus.values)
            _chip(
              key: Key('order-filter-${status.name}'),
              label: status.label,
              selected: orders.statusFilter == status,
              onSelected: () => orders.setStatusFilter(status),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        key: key,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _body(OrderController orders) {
    if (orders.loading && orders.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: orders.load,
      child: orders.orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 340,
                  child: EmptyState(
                    title: orders.error == null
                        ? 'Belum ada pesanan'
                        : 'Gagal memuat pesanan',
                    message:
                        orders.error ??
                        (orders.statusFilter == null
                            ? 'Pesanan Anda akan tampil di sini.'
                            : 'Tidak ada pesanan dengan status '
                                  '${orders.statusFilter!.label}.'),
                    actionLabel: orders.error == null ? null : 'Coba Lagi',
                    onAction: orders.error == null ? null : orders.load,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              itemCount: orders.orders.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _orderCard(orders.orders[index]),
            ),
    );
  }

  Widget _orderCard(Order order) {
    final itemCount = order.items.fold(0, (sum, item) => sum + item.qty);
    return Container(
      key: Key('order-card-${order.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNo,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatDateWib(order.createdAt),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: SizedBox(
                  width: 56,
                  height: 68,
                  child: order.items.isEmpty
                      ? const ColoredBox(color: AppColors.line)
                      : Image.asset(
                          order.items.first.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: AppColors.line),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$itemCount produk',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatRupiah(order.total),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: Key('order-view-${order.id}'),
                onPressed: () => context.push('/orders/${order.id}'),
                child: const Text('Lihat Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
