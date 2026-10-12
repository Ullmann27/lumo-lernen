import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/rewards/reward_catalog.dart';

void main() {
  test('5000 Sterne entsprechen genau dem Family-Park-Ausflug', () {
    final rewardsAt5000 =
        RewardCatalog.all.where((reward) => reward.cost == 5000).toList();

    expect(rewardsAt5000, hasLength(1));
    expect(rewardsAt5000.single.id, 'family_park');
    expect(rewardsAt5000.single.title, 'Family Park');
    expect(rewardsAt5000.single.parentApprovalRequired, isTrue);
  });

  test('Tiergarten blockiert nicht mehr die Family-Park-Stufe', () {
    final tiergarten =
        RewardCatalog.all.singleWhere((reward) => reward.id == 'tiergarten');
    final familyPark =
        RewardCatalog.all.singleWhere((reward) => reward.id == 'family_park');

    expect(tiergarten.cost, isNot(5000));
    expect(familyPark.cost, 5000);
  });
}
