import '../../../core/name_order.dart';
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

/// What the filter asks of one row, on one day.
class _Status {
  _Status(this.clock) : today = DateTime(clock.year, clock.month, clock.day);

  final DateTime clock;
  final DateTime today;

  // Nothing left, nothing to expire (#281).
  DateTime? _expiry(InventoryItem item) =>
      isUsedUp(item, now: clock) ? null : item.expirationDate;

  // Past its date from the day after, as everywhere else (#234).
  bool expired(InventoryItem item) => _expiry(item)?.isBefore(today) ?? false;

  // The same "soon" as the overview that leads here (#271).
  bool expiring(InventoryItem item) => switch (_expiry(item)) {
    final date? => !date.isBefore(today) && expiresSoon(date, today),
    null => false,
  };

  bool low(InventoryItem item) => isBelowMinimum(item, now: clock);

  bool chargeDue(InventoryItem item) =>
      deviceChargeCheck(item, now: clock)?.isDue(now: clock) ?? false;

  /// Past its date, under its minimum, or a device whose battery check
  /// has come round (#179): what the badge on the inventory counts.
  bool wantsAttention(InventoryItem item) =>
      expired(item) || low(item) || chargeDue(item);
}

/// How many of [items] want looking at today, for the badge on the
/// inventory: the same rows the filter finds, so the number and the list
/// behind it agree (#281).
int countNeedingAttention(List<InventoryItem> items, {DateTime? now}) {
  final status = _Status(now ?? DateTime.now());
  return items.where(status.wantsAttention).length;
}

List<InventoryItem> filterInventory(
  List<InventoryItem> items, {
  String query = '',
  InventoryFilter filter = const InventoryFilter(),
  DateTime? now,
}) {
  final status = _Status(now ?? DateTime.now());
  final expired = status.expired;
  final expiring = status.expiring;
  final low = status.low;
  final chargeDue = status.chargeDue;
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
  // Worked out once a row rather than at every comparison: this runs on
  // every letter typed into the search.
  final names = {
    for (final item in result) item.clientId: nameSortKey(item.name),
  };
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
    // "Äpfel" beside "apfelmus", not after "Zucker" (#283).
    final name = names[a.clientId]!.compareTo(names[b.clientId]!);
    if (name != 0) return name;
    final spelt = a.name.compareTo(b.name);
    return spelt != 0 ? spelt : a.clientId.compareTo(b.clientId);
  });
  return result;
}
