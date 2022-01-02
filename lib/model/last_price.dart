///
/// [LastPriceResponse] class stores responses from last price
/// api request
///

class LastPriceResponse {
  String? id;
  String? active;
  String? name;
  String? description;
  double? val;

  double? get price => val;

  LastPriceResponse(
      {required this.id,
      required this.active,
      required this.name,
      required this.description,
      required this.val});

  LastPriceResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    active = json['active'];
    name = json['name'];
    description = json['description'];
    val = double.parse(json['val']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['active'] = active;
    data['name'] = name;
    data['description'] = description;
    data['val'] = val;
    return data;
  }
}

///
///The [LastPrice] class is used to serialise and deserialise
///last price [mhc], [btc] and [eth] and store the same into user preference
///

class LastPrice {
  late num mhc;
  late num btc;
  late num eth;

  static const boxName = 'Prices';

  num get mhcPrice => mhc;
  num get btcPrice => btc;
  num get ethPrice => eth;
  LastPrice({required this.mhc, required this.btc, required this.eth});

  LastPrice.fromJson(Map<String, dynamic> json) {
    mhc = json['mhc'];
    btc = json['btc'];
    eth = json['eth'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mhc'] = mhc;
    data['btc'] = btc;
    data['eth'] = eth;
    return data;
  }
}
