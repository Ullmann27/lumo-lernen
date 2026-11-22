import 'package:flutter/foundation.dart';

import '../app/app_state.dart';
import '../domain/rewards/reward_shop.dart';
import 'reward_shop_repository.dart';
import 'reward_wallet_repository.dart';

/// One visible shop/editor, bound to the captured child identity through every
/// await. The historical name/grade shop remains intact; all new definitions
/// and receipts use the stable learning-profile identity.
class RewardShopSession extends ChangeNotifier {
  RewardShopSession(this.appState,
      {this.repository = const RewardShopRepository()}) {
    _generation = appState.profileGeneration;
    _legacyId = _currentLegacyId;
    appState.addListener(_onAppChanged);
    load();
  }

  final LumoAppState appState;
  final RewardShopRepository repository;
  LearningProfileLease? owner;
  RewardShopProfile? profile;
  RewardWallet? wallet;
  String ownerName = '';
  RewardShopState legacy = const RewardShopState();
  bool loading = true;
  bool busy = false;
  String? error;
  int _loadId = 0;
  late int _generation;
  late String _legacyId;
  bool _disposed = false;
  final Map<String, RewardShopRedemption> _memoryPending = {};

  String get _currentLegacyId => RewardShopRepository.legacyChildId(
      appState.state.childName, appState.state.grade);

  bool get ready =>
      !loading && owner != null && profile != null && wallet != null;

  bool isCurrent(LearningProfileLease lease) =>
      !_disposed &&
      !appState.backupBusy &&
      appState.canUseLearningLease(lease) &&
      lease.generation == appState.profileGeneration &&
      appState.school.cachedActiveStudentId ==
          (lease.logStudentId == 'self' ? null : lease.studentId) &&
      owner?.studentId == lease.studentId;

  void validateOwner(LearningProfileLease lease) {
    if (!isCurrent(lease)) {
      throw StateError('Das Kinderprofil hat gewechselt oder wird gesichert. '
          'Bitte öffne den Gutschein erneut.');
    }
  }

  RewardShopState get state => legacy.copyWith(
        availableStars: wallet?.stars ?? 0,
        redeemed: history,
      );

  List<RedeemedReward> get history {
    final entries = <RedeemedReward>[...legacy.redeemed];
    final ids = entries.map((v) => v.transactionId).whereType<String>().toSet();
    for (final receipt
        in wallet?.shopRedemptions ?? const <RewardShopRedemption>[]) {
      if (receipt.ownerId == owner?.studentId &&
          ids.add(receipt.transactionId)) {
        entries.add(receipt.historyEntry);
      }
    }
    entries.sort((a, b) => a.redeemedAt.compareTo(b.redeemedAt));
    return entries;
  }

  List<RewardShopRedemption> get pending {
    final completed =
        wallet?.shopRedemptions.map((v) => v.transactionId).toSet() ?? {};
    final items = <String, RewardShopRedemption>{
      for (final value
          in profile?.pendingRedemptions ?? const <RewardShopRedemption>[])
        value.transactionId: value,
      ..._memoryPending,
    };
    return items.values
        .where((v) =>
            v.ownerId == owner?.studentId &&
            !completed.contains(v.transactionId))
        .toList();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onAppChanged() {
    if (_disposed) return;
    if (_generation != appState.profileGeneration ||
        _legacyId != _currentLegacyId) {
      _generation = appState.profileGeneration;
      _legacyId = _currentLegacyId;
      _memoryPending.clear();
      load();
      return;
    }
    if (wallet != null && !loading) {
      wallet = wallet!.copyWith(
          stars: appState.state.stars,
          xp: appState.state.xp,
          level: appState.state.level);
      _notify();
    }
  }

  Future<void> load() async {
    final ticket = ++_loadId;
    final source = appState.captureLearningProfile();
    final legacyId = _currentLegacyId;
    loading = true;
    error = null;
    owner = null;
    profile = null;
    wallet = null;
    _notify();
    try {
      final lease = await source;
      if (_disposed || ticket != _loadId) return;
      owner = lease;
      validateOwner(lease);
      final name = lease.logStudentId == 'self'
          ? appState.state.childName
          : await appState.school.studentName(lease.studentId) ?? 'Schulprofil';
      validateOwner(lease);
      var saved = await repository.loadProfile(lease.studentId);
      validateOwner(lease);
      final old = await repository.load(legacyId);
      validateOwner(lease);
      var balance = await appState.loadRewardShopWallet(lease: lease);
      // A pending receipt may already be visible in native preference memory
      // after an ambiguous write reply. Only an identical, positively confirmed
      // wallet retry establishes durability; merely finding its ID is not an
      // acknowledgement. Missing receipts stay pending for explicit resumption.
      for (final receipt in saved.pendingRedemptions) {
        if (!balance.shopRedemptions
            .any((v) => v.transactionId == receipt.transactionId)) {
          continue;
        }
        validateOwner(lease);
        balance =
            await appState.redeemShopReward(lease: lease, redemption: receipt);
        validateOwner(lease);
        try {
          saved = await repository.finishRedemption(
              ownerId: lease.studentId,
              transactionId: receipt.transactionId,
              validateOwner: () => validateOwner(lease));
        } catch (_) {
          validateOwner(lease);
          // The wallet receipt is durable even if queue cleanup must wait.
        }
      }
      await appState.hydrateFromWallet();
      validateOwner(lease);
      balance = await appState.loadRewardShopWallet(lease: lease);
      validateOwner(lease);
      if (ticket != _loadId) return;
      profile = saved;
      ownerName = name;
      legacy = old;
      wallet = balance;
      loading = false;
      _notify();
    } catch (failure) {
      if (_disposed || ticket != _loadId) return;
      loading = false;
      error = messageFor(failure);
      _notify();
    }
  }

  Future<void> saveDefinition(CustomRewardDefinition definition,
      {required LearningProfileLease lease}) async {
    validateOwner(lease);
    if (busy) {
      throw StateError(
          'Bitte warte, bis der aktuelle Gutschein gespeichert ist.');
    }
    busy = true;
    error = null;
    _notify();
    try {
      final saved = await repository.saveDefinition(
          ownerId: lease.studentId,
          definition: definition,
          validateOwner: () => validateOwner(lease));
      validateOwner(lease);
      profile = saved;
    } catch (failure) {
      if (isCurrent(lease)) error = messageFor(failure);
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> redeem(RewardShopRedemption receipt,
      {required LearningProfileLease lease}) async {
    if (busy) return false;
    validateOwner(lease);
    if (receipt.ownerId != lease.studentId) {
      throw StateError(
          'Dieser Gutschein gehört zu einem anderen Kinderprofil.');
    }
    busy = true;
    error = null;
    _memoryPending[receipt.transactionId] = receipt;
    _notify();
    try {
      final staged = await repository.stageRedemption(
          redemption: receipt, validateOwner: () => validateOwner(lease));
      validateOwner(lease);
      profile = staged;
      final committed =
          await appState.redeemShopReward(lease: lease, redemption: receipt);
      validateOwner(lease);
      wallet = committed;
      _memoryPending.remove(receipt.transactionId);
      // The wallet is already durably committed. A cleanup error must not turn
      // a successful debit into a fresh purchase with a different identity.
      try {
        final finished = await repository.finishRedemption(
            ownerId: lease.studentId,
            transactionId: receipt.transactionId,
            validateOwner: () => validateOwner(lease));
        validateOwner(lease);
        profile = finished;
      } catch (_) {
        if (isCurrent(lease)) {
          error =
              'Der Gutschein ist eingelöst. Der gespeicherte Beleg bleibt erhalten.';
        }
      }
      return true;
    } catch (failure) {
      if (isCurrent(lease)) error = messageFor(failure);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  static String messageFor(Object failure) {
    if (failure is StateError) return failure.message.toString();
    if (failure is FormatException) {
      return 'Die gespeicherten Gutscheine konnten nicht sicher gelesen werden. '
          'Der vorhandene Stand wurde nicht überschrieben.';
    }
    return 'Speichern noch nicht bestätigt. Bitte versuche es erneut.';
  }

  @override
  void dispose() {
    _disposed = true;
    _loadId++;
    appState.removeListener(_onAppChanged);
    super.dispose();
  }
}
