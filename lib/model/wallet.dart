class Wallet {
  late String address;
  int? received;
  int? spent;
  int? countReceived;
  int? countSpent;
  int? countTxs;
  int? blockNumber;
  int? currentBlock;
  String? hash;
  int? countDelegatedOps;
  int? delegate;
  int? undelegate;
  int? delegated;
  int? undelegated;
  int? reserved;
  int? countForgedOps;
  int? forged;
  String name = "Wallet";

  static const boxName = 'Wallets';

  Wallet(
      {required this.address,
      required this.received,
      required this.spent,
      required this.countReceived,
      required this.countSpent,
      required this.countTxs,
      required this.blockNumber,
      required this.currentBlock,
      required this.hash,
      required this.countDelegatedOps,
      required this.delegate,
      required this.undelegate,
      required this.delegated,
      required this.undelegated,
      required this.reserved,
      required this.countForgedOps,
      required this.forged,
      required this.name});

  Wallet.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    received = json['received'];
    spent = json['spent'];
    countReceived = json['count_received'];
    countSpent = json['count_spent'];
    countTxs = json['count_txs'];
    blockNumber = json['block_number'];
    currentBlock = json['currentBlock'];
    hash = json['hash'];
    countDelegatedOps = json['countDelegatedOps'];
    delegate = json['delegate'];
    undelegate = json['undelegate'];
    delegated = json['delegated'];
    undelegated = json['undelegated'];
    reserved = json['reserved'];
    countForgedOps = json['countForgedOps'];
    forged = json['forged'];
    name = "Wallet";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['received'] = received;
    data['spent'] = spent;
    data['count_received'] = countReceived;
    data['count_spent'] = countSpent;
    data['count_txs'] = countTxs;
    data['block_number'] = blockNumber;
    data['currentBlock'] = currentBlock;
    data['hash'] = hash;
    data['countDelegatedOps'] = countDelegatedOps;
    data['delegate'] = delegate;
    data['undelegate'] = undelegate;
    data['delegated'] = delegated;
    data['undelegated'] = undelegated;
    data['reserved'] = reserved;
    data['countForgedOps'] = countForgedOps;
    data['forged'] = forged;
    return data;
  }

  double getBalance() {
    return (received!.toDouble() - spent!.toDouble()) / 1e6;
  }

  double getDelegate() {
    if (delegated == null) return 0.0;
    return (delegate!.toDouble() - undelegate!) / 1e6;
  }

  double getTotal() {
    return getBalance() + getDelegate();
  }
}
