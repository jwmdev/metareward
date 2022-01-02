enum TransactionType {
  transfer,
  rejected,
  forging,
  walletReward,
  nodeReward,
  coinReward,
  randomReward,
  delegation,
}

class TransactionHistory {
  late String from;
  late String to;
  late int value;
  late String transaction;
  late String data;
  late int timestamp;
  late String type;
  late int blockNumber;
  late int blockIndex;
  late String signature;
  late String publickey;
  late int fee;
  late int? realFee;
  late int nonce;
  late int intStatus;
  late String status;
  late bool isDelegate;
  late int delegate;

  TransactionHistory({
    required this.from,
    required this.to,
    required this.value,
    required this.transaction,
    required this.data,
    required this.timestamp,
    required this.type,
    required this.blockNumber,
    required this.blockIndex,
    required this.signature,
    required this.publickey,
    required this.fee,
    required this.realFee,
    required this.nonce,
    required this.intStatus,
    required this.status,
    //required this.isDelegate,
    required this.delegate,
  });

  TransactionHistory.fromJson(Map<String, dynamic> json) {
    from = json['from'];
    to = json['to'];
    value = json['value'];
    transaction = json['transaction'];
    data = json['data'];
    timestamp = json['timestamp'];
    type = json['type'];
    blockNumber = json['blockNumber'];
    blockIndex = json['blockIndex'];
    signature = json['signature'];
    publickey = json['publickey'];
    fee = json['fee'];
    realFee = json['realFee'];
    nonce = json['nonce'];
    intStatus = json['intStatus'];
    status = json['status'];
    if (json['isDelegate'] == null) {
      isDelegate = false;
    } else {
      isDelegate = json['isDelegate'];
    }
    if (json['delegate'] == null) {
      delegate = 0;
    } else {
      delegate = json['delegate'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['from'] = from;
    data['to'] = to;
    data['value'] = value;
    data['transaction'] = transaction;
    data['data'] = data;
    data['timestamp'] = timestamp;
    data['type'] = type;
    data['blockNumber'] = blockNumber;
    data['blockIndex'] = blockIndex;
    data['signature'] = signature;
    data['publickey'] = publickey;
    data['fee'] = fee;
    data['realFee'] = realFee;
    data['nonce'] = nonce;
    data['intStatus'] = intStatus;
    data['status'] = status;
    data['isDelegate'] = isDelegate;
    data['delegate'] = delegate;
    return data;
  }

  TransactionType transactionType() {
    if (intStatus == 20 && value != 0) return TransactionType.transfer;
    if (intStatus == 40) return TransactionType.rejected;
    if (intStatus == 100) return TransactionType.forging;
    if (intStatus == 101) return TransactionType.walletReward;
    if (intStatus == 102) return TransactionType.nodeReward;
    if (intStatus == 103) return TransactionType.coinReward;
    if (intStatus == 104) return TransactionType.randomReward;
    if (intStatus == 20 && value == 0) return TransactionType.delegation;
    return TransactionType.rejected;
  }

  double getAmount() {
    return value.toDouble() / 1e6;
  }
}
