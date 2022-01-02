import 'package:metareward/model/transaction_history.dart';

class Delegator {
  String address;
  num delegatedAmount;
  num dueAmount;

  Delegator({
    required this.address,
    required this.delegatedAmount,
    required this.dueAmount,
  });
}

class Delegators {
  num reward = 0;
  num totalDelegation = 0;
  num totalDueAmount = 0;
  DateTime rewardDate;
  List<TransactionHistory> txs;
  String nodeAddress;
  num rewardPercentage;
  Delegators({
    required this.txs,
    required this.nodeAddress,
    required this.rewardPercentage,
    required this.rewardDate,
  }) {
    reward = getTodayReward();
  }

  //get list of delegators
  Map<String, Delegator> getDelegators() {
    Map<String, Delegator> delegators = <String, Delegator>{};

    //var now = DateTime.now();
    var dayBefore =
        DateTime(rewardDate.year, rewardDate.month, rewardDate.day - 1);
    num ts = (dayBefore.millisecondsSinceEpoch / 1000);

    for (var tx in txs) {
      if (isTxValid(tx, ts) && tx.to == nodeAddress) {
        var del = Delegator(address: tx.from, delegatedAmount: 0, dueAmount: 0);
        delegators.putIfAbsent(tx.from, () => del); //put if does not exist
        if (tx.isDelegate &&
            tx.transactionType() == TransactionType.delegation) {
          //if (tx.transactionType() == TransactionType.delegation) {
          delegators[tx.from]!.delegatedAmount += tx.delegate;
          totalDelegation += tx.delegate;
        } else {
          delegators[tx.from]!.delegatedAmount -= tx.delegate;
          totalDelegation -= tx.delegate;
        }
      }
    }

    print("Node reward: ${reward / 1e6}");
    print("Total delegation: ${totalDelegation / 1e6}");
    //remove delegators with zero delegation values
    delegators.removeWhere((key, value) => value.delegatedAmount == 0);

    //compute reward percentage for each delegator
    delegators.forEach((key, value) {
      var dueAmount = (value.delegatedAmount / totalDelegation) *
          reward *
          rewardPercentage /
          1e6;

      value.dueAmount = dueAmount;
      totalDueAmount += dueAmount;
    });

    print("Amount to be distributed: $totalDueAmount");
    print("Node balance: ${reward / 1e6 - totalDueAmount}");
    return delegators;
  }

//get today's node reward
  num getTodayReward() {
    //DateTime today = DateTime.now();
    //DateTime dayBefore = rewardDate.subtract(Duration(days: 1));
    num rewardDateTm =
        (rewardDate.millisecondsSinceEpoch / 1000); //seconds since epoch
    num limitTm = rewardDateTm + 23 * 60 * 60; //seconds since epoch
    for (var tx in txs) {
      if (tx.timestamp >= rewardDateTm &&
          tx.timestamp < limitTm &&
          tx.intStatus == 102 &&
          tx.from == "InitialWalletTransaction") {
        return tx.value;
      }
    }
    return 0;
  }

//check if the delegation transaction is valid
  bool isTxValid(TransactionHistory tx, num ts) {
    if (tx.timestamp < ts && tx.status == "ok") {
      return true;
    }
    return false;
  }
}
