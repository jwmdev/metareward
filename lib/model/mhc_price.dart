// ignore_for_file: prefer_collection_literals

enum CurrencyType { MHC, USD, BTC, ETH }
enum DurationType { DAY, WEEK, MONTH }

class Price {
  List<PriceEntry> _day = <PriceEntry>[]; //24 hours price
  List<PriceEntry> _week = <PriceEntry>[]; //price in one week
  List<PriceEntry> _month = <PriceEntry>[];

  List<PriceEntry> get dayPrice => _day;
  List<PriceEntry> get weekPrice => _week;
  List<PriceEntry> get monthPrice => _month;
  set dayPrice(List<PriceEntry> price) => _day = price;
  set weekPrice(List<PriceEntry> price) => _week = price;
  set monthPrice(List<PriceEntry> price) => _month = price;

  List<PricePoint> getDayPrice(CurrencyType currency) {
    final List<PricePoint> price = <PricePoint>[];

    switch (currency) {
      case CurrencyType.USD:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.val));
        }
        break;
      case CurrencyType.BTC:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.toBtc));
        }
        break;
      case CurrencyType.ETH:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.toEth));
        }
        break;
      default:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.val));
        }
    }

    return price;
  }

  List<PricePoint> getWeekPrice(CurrencyType currency) {
    List<PricePoint> price = List.empty();

    switch (currency) {
      case CurrencyType.USD:
        for (PriceEntry pe in _week) {
          price.add(PricePoint(pe.ts, pe.val));
        }
        break;
      case CurrencyType.BTC:
        for (PriceEntry pe in _week) {
          price.add(PricePoint(pe.ts, pe.toBtc));
        }
        break;
      case CurrencyType.ETH:
        for (PriceEntry pe in _week) {
          price.add(PricePoint(pe.ts, pe.toEth));
        }
        break;
      default:
        for (PriceEntry pe in _week) {
          price.add(PricePoint(pe.ts, pe.val));
        }
    }

    return price;
  }

  List<PricePoint> getMonthPrice(CurrencyType currency) {
    List<PricePoint> price = List.empty();

    switch (currency) {
      case CurrencyType.USD:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.val));
        }
        break;
      case CurrencyType.BTC:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.toBtc));
        }
        break;
      case CurrencyType.ETH:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.toEth));
        }
        break;
      default:
        for (PriceEntry pe in _day) {
          price.add(PricePoint(pe.ts, pe.val));
        }
    }

    return price;
  }
}

///
///[PricePoint] class is stores price and its corresponding timestamp
///This is useful if you want to plot a price graph
///
class PricePoint {
  final double timestamp;
  final double instantPrice;
  PricePoint(this.timestamp, this.instantPrice);
}

class PriceEntry {
  double ts = 0; //timestamp
  double val = 0; //value in usd
  double toBtc = 0; //value in btc
  double toEth = 0; //value in eth

  PriceEntry(
      {required this.ts,
      required this.val,
      required this.toBtc,
      required this.toEth});

  PriceEntry.fromJson(Map<String, dynamic> json) {
    ts = double.parse(json['ts'] as String);
    val = double.parse(json['val'] as String);
    toBtc = double.parse(json['to_btc'] as String);
    toEth = double.parse(json['to_eth'] as String);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['ts'] = ts;
    data['val'] = val;
    data['to_btc'] = toBtc;
    data['to_eth'] = toEth;
    return data;
  }
}
