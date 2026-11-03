import '../../../local_db/database.dart';
import '../../home/application/home_overview.dart' show expiresSoon;
import 'device_charge.dart';
import 'stock_today.dart';

/// [chargeDue] is a device whose battery check has come round (#179).
enum InventoryStatusFilter { all, expired, expiring, lowStock, chargeDue }

enum InventorySort { name, expiry, attention }

class InventoryFilter {
  const InventoryFilter({
    this.category,
    this.location,
    this.status = InventoryStatusFilter.all,
    this.sort = InventorySort.name,
  });
  final String? category;
  final String? location;
  final InventoryStatusFilter status;
  final InventorySort sort;
  bool get isActive =>
      category != null ||
      location != null ||
      status != InventoryStatusFilter.all ||
      sort != InventorySort.name;
}

List<InventoryItem> filterInventory(
  List<InventoryItem> items, {
  String query = '',
  InventoryFilter filter = const InventoryFilter(),
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  bool expired(InventoryItem item) =>
      item.expirationDate?.isBefore(today) ?? false;
  // The same "soon" as the overview that leads here (#271).
  bool expiring(InventoryItem item) => switch (item.expirationDate) {
    final expiry? => !expired(item) && expiresSoon(expiry, today),
    null => false,
  };
  bool low(InventoryItem item) => isBelowMinimum(item, now: clock);
  bool chargeDue(InventoryItem item) =>
      deviceChargeCheck(item)?.isDue(now: clock) ?? false;
  int priority(InventoryItem item) => expired(item)
      ? 0
      : low(item)
      ? 1
      : chargeDue(item)
      ? 2
      : expiring(item)
      ? 3
      : 4;
  final terms = query
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty);
  final result = items.where((item) {
    if (filter.category != null && item.category != filter.category) {
      return false;
    }
    if (filter.location != null && item.storageLocation != filter.location) {
      return false;
    }
    final text =
        '${item.name} ${item.barcode ?? ''} ${item.storageLocation} ${item.notes ?? ''}'
            .toLowerCase();
    if (!terms.every(text.contains)) return false;
    return switch (filter.status) {
      InventoryStatusFilter.all => true,
      InventoryStatusFilter.expired => expired(item),
      InventoryStatusFilter.expiring => expiring(item),
      InventoryStatusFilter.lowStock => low(item),
      InventoryStatusFilter.chargeDue => chargeDue(item),
    };
  }).toList();
  result.sort((a, b) {
    final comparison = switch (filter.sort) {
      InventorySort.name => 0,
      InventorySort.attention => priority(a).compareTo(priority(b)),
      InventorySort.expiry =>
        a.expirationDate == null
            ? (b.expirationDate == null ? 0 : 1)
            : b.expirationDate == null
            ? -1
            : a.expirationDate!.compareTo(b.expirationDate!),
    };
    if (comparison != 0) return comparison;
    final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return name != 0 ? name : a.clientId.compareTo(b.clientId);
  });
  return result;
}
