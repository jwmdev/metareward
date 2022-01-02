class Delegation {
  late String to;
  late int value;
  String? tx;

  Delegation({required this.to, required this.value, required this.tx});

  Delegation.fromJson(Map<String, dynamic> json) {
    to = json['to'];
    value = json['value'];
    tx = json['tx'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['to'] = to;
    data['value'] = value;
    data['tx'] = tx;
    return data;
  }

  double getAmount() {
    return value.toDouble() / 1e6;
  }
}

class DelegationCounts {
  String to;
  int value;
  int counts;

  DelegationCounts(
      {required this.to, required this.value, required this.counts});

  double getAmount() {
    return value.toDouble() / 1e6;
  }
}
