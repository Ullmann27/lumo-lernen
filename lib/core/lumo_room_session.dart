import 'package:flutter/foundation.dart';

import '../app/app_state.dart';
import '../domain/room/lumo_room.dart';
import 'lumo_room_repository.dart';
import 'reward_wallet_repository.dart';

class LumoRoomSession extends ChangeNotifier {
  LumoRoomSession(this.appState,
      {this.repository = const LumoRoomRepository()}) {
    _generation = appState.profileGeneration;
    appState.addListener(_appChanged);
    load();
  }

  final LumoAppState appState;
  final LumoRoomRepository repository;
  LearningProfileLease? owner;
  LumoRoomProfile? profile;
  RewardWallet? wallet;
  String ownerName = '';
  bool loading = true;
  bool busy = false;
  String? error;
  late int _generation;
  int _loadId = 0;
  bool _disposed = false;
  final Map<String, LumoRoomActionRequest> _memoryActions = {};
  final Set<String> _memoryPurchases = {};

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

  void guard(LearningProfileLease lease) {
    if (!isCurrent(lease))
      throw StateError(
          'Das Kinderprofil hat gewechselt oder wird gesichert. Bitte öffne Lumos Zimmer erneut.');
  }

  bool owns(LumoRoomItem item) =>
      ready &&
      LumoRoomCatalog.owns(owner!.studentId, item, wallet!.shopRedemptions);

  Set<String> get equipped => {
        'scarf_blue',
        ...?profile?.equipped.where((id) => owns(LumoRoomCatalog.byId(id))),
      }..removeWhere((id) =>
          id == 'scarf_blue' &&
          (profile?.equipped.any((v) =>
                  v != 'scarf_blue' &&
                  v.startsWith('scarf_') &&
                  owns(LumoRoomCatalog.byId(v))) ??
              false));

  String get theme =>
      profile?.theme == 'room_space' && owns(LumoRoomCatalog.byId('room_space'))
          ? 'room_space'
          : 'starter';

  DateTime? get nextPraise => owner == null || wallet == null
      ? null
      : lumoRoomNextPraise(owner!.studentId, wallet!.roomActions);

  List<LumoRoomItem> get pendingPurchases {
    final ids = {
      ..._memoryPurchases,
      for (final value in profile?.purchases ?? const <LumoRoomPurchase>[])
        if (!value.confirmed) value.itemId,
    };
    return ids.map(LumoRoomCatalog.byId).where((item) => !owns(item)).toList();
  }

  List<LumoRoomActionRequest> get pendingActions {
    final completed =
        wallet?.roomActions.map((v) => v.request.actionId).toSet() ?? {};
    final all = <String, LumoRoomActionRequest>{
      for (final value
          in profile?.pendingActions ?? const <LumoRoomActionRequest>[])
        value.actionId: value,
      ..._memoryActions,
    };
    return all.values
        .where((v) =>
            v.ownerId == owner?.studentId && !completed.contains(v.actionId))
        .toList();
  }

  bool get hasPending =>
      pendingPurchases.isNotEmpty || pendingActions.isNotEmpty;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _appChanged() {
    if (_disposed) return;
    if (_generation != appState.profileGeneration) {
      _generation = appState.profileGeneration;
      _memoryActions.clear();
      _memoryPurchases.clear();
      load();
    } else if (wallet != null && !loading) {
      wallet = wallet!.copyWith(
          stars: appState.state.stars,
          xp: appState.state.xp,
          level: appState.state.level);
      _notify();
    }
  }

  Future<void> load() async {
    final ticket = ++_loadId;
    final identity = appState.captureLearningProfile();
    loading = true;
    error = null;
    owner = null;
    profile = null;
    wallet = null;
    _notify();
    try {
      final lease = await identity;
      if (_disposed || ticket != _loadId) return;
      owner = lease;
      guard(lease);
      var saved = await repository.load(lease.studentId);
      guard(lease);
      var balance = await appState.loadRewardShopWallet(lease: lease);
      for (final purchase in saved.purchases.where((v) => !v.confirmed)) {
        if (!balance.shopRedemptions
            .any((v) => v.transactionId == purchase.receipt.transactionId))
          continue;
        guard(lease);
        balance = await appState.redeemShopReward(
            lease: lease, redemption: purchase.receipt);
        guard(lease);
        saved = await repository.confirmPurchase(
            ownerId: lease.studentId,
            itemId: purchase.itemId,
            validateOwner: () => guard(lease));
      }
      for (final action in saved.pendingActions) {
        if (!balance.roomActions
            .any((v) => v.request.actionId == action.actionId)) continue;
        guard(lease);
        balance =
            await appState.performLumoRoomAction(lease: lease, request: action);
        guard(lease);
        saved = await repository.finishAction(
            ownerId: lease.studentId,
            actionId: action.actionId,
            validateOwner: () => guard(lease));
      }
      final name = lease.logStudentId == 'self'
          ? appState.state.childName
          : await appState.school.studentName(lease.studentId) ?? 'Schulprofil';
      await appState.hydrateFromWallet();
      balance = await appState.loadRewardShopWallet(lease: lease);
      guard(lease);
      if (ticket != _loadId) return;
      profile = saved;
      wallet = balance;
      ownerName = name;
      loading = false;
      _notify();
    } catch (failure) {
      if (_disposed || ticket != _loadId) return;
      loading = false;
      error = message(failure);
      _notify();
    }
  }

  Future<bool> buy(LumoRoomItem item, LearningProfileLease lease) async {
    if (busy) return false;
    guard(lease);
    busy = true;
    error = null;
    _memoryPurchases.add(item.id);
    _notify();
    try {
      final staged = await repository.stagePurchase(
          ownerId: lease.studentId,
          item: item,
          validateOwner: () => guard(lease));
      guard(lease);
      profile = staged;
      final purchase = staged.purchases.singleWhere((v) => v.itemId == item.id);
      final committed = await appState.redeemShopReward(
          lease: lease, redemption: purchase.receipt);
      guard(lease);
      wallet = committed;
      _memoryPurchases.remove(item.id);
      try {
        final confirmed = await repository.confirmPurchase(
            ownerId: lease.studentId,
            itemId: item.id,
            validateOwner: () => guard(lease));
        guard(lease);
        profile = confirmed;
      } catch (_) {
        if (isCurrent(lease))
          error =
              'Der Kauf ist gespeichert. Du kannst den Gegenstand ausrüsten.';
      }
      return true;
    } catch (failure) {
      if (isCurrent(lease)) error = message(failure);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> equip(LumoRoomItem item, LearningProfileLease lease) async {
    if (busy) return false;
    guard(lease);
    busy = true;
    error = null;
    _notify();
    try {
      final balance = await appState.loadRewardShopWallet(lease: lease);
      guard(lease);
      final saved = await repository.equip(
          ownerId: lease.studentId,
          item: item,
          receipts: balance.shopRedemptions,
          validateOwner: () => guard(lease));
      guard(lease);
      profile = saved;
      wallet = balance;
      return true;
    } catch (failure) {
      if (isCurrent(lease)) error = message(failure);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> act(
      LumoRoomActionRequest request, LearningProfileLease lease) async {
    if (busy) return false;
    guard(lease);
    if (request.ownerId != lease.studentId)
      throw StateError('Falsches Kinderprofil');
    busy = true;
    error = null;
    _memoryActions[request.actionId] = request;
    _notify();
    try {
      final staged = await repository.stageAction(
          request: request, validateOwner: () => guard(lease));
      guard(lease);
      profile = staged;
      final committed =
          await appState.performLumoRoomAction(lease: lease, request: request);
      guard(lease);
      wallet = committed;
      _memoryActions.remove(request.actionId);
      try {
        final saved = await repository.finishAction(
            ownerId: lease.studentId,
            actionId: request.actionId,
            validateOwner: () => guard(lease));
        guard(lease);
        profile = saved;
      } catch (_) {
        if (isCurrent(lease)) error = 'Deine Zimmeraktion ist gespeichert.';
      }
      return true;
    } on LumoRoomActionUnavailable catch (failure) {
      if (isCurrent(lease)) {
        error = failure.message;
        try {
          final saved = await repository.finishAction(
              ownerId: lease.studentId,
              actionId: request.actionId,
              validateOwner: () => guard(lease));
          guard(lease);
          profile = saved;
          _memoryActions.remove(request.actionId);
        } catch (_) {
          /* The unchanged request stays available for a later retry. */
        }
      }
      return false;
    } catch (failure) {
      if (isCurrent(lease)) error = message(failure);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  static String message(Object failure) {
    if (failure is StateError) return failure.message.toString();
    if (failure is LumoRoomActionUnavailable) return failure.message;
    if (failure is FormatException)
      return 'Dein gespeichertes Zimmer konnte nicht sicher gelesen werden. Der vorhandene Stand bleibt erhalten.';
    return 'Speichern noch nicht bestätigt. Bitte versuche es erneut.';
  }

  @override
  void dispose() {
    _disposed = true;
    _loadId++;
    appState.removeListener(_appChanged);
    super.dispose();
  }
}
