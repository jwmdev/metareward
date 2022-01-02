import 'dart:io';

import 'package:yaml/yaml.dart';

class Config {
  Node node;
  List<String> skip = [];
  Map<String, num> special = <String, num>{};
  Config({
    required this.node,
    required this.skip,
    required this.special,
  });

  static Future<Config?> create() async {
    //load configuration
    var path = "./config.yaml";
    var cfg;
    File file = File(path);
    if ((await file.exists()) == true) {
      String content = await file.readAsString();
      cfg = loadYaml(content);
    }
    if (cfg == null) {
      return null;
    }

    var node = Node(
      address: cfg["node"]["address"],
      key: cfg["node"]["key"],
      percentage: cfg["node"]["percentage"],
      time: cfg["node"]["time"],
      donation: cfg["node"]["donation"],
    );

    var skip = List<String>.from(cfg["skip"]);

    if (cfg["special"]["addresses"].length !=
        cfg["special"]["percentage"].length) {
      return null;
    }

    Map<String, num> special = <String, num>{};
    for (var i = 0; i < cfg["special"]["addresses"].length; i++) {
      special[cfg["special"]["addresses"][i]] = cfg["special"]["percentage"][i];
    }

    Config config = Config(node: node, skip: skip, special: special);
    return config;
  }

//check if given address has to be skipped
  bool isSkip(String address) {
    if (skip.isEmpty) {
      return false;
    }
    return skip.contains(address);
  }

  //check if given address has to be skipped
  bool isSpecial(String address) {
    if (special.isEmpty) {
      return false;
    }
    return special.containsKey(address);
  }

//get special percentage
  num? getSpecialPercentage(String address) {
    if (!isSpecial(address)) {
      return node.percentage;
    } else {
      return special[address];
    }
  }
}

class Node {
  String address;
  String key;
  num percentage;
  String time;
  num donation;
  Node({
    required this.address,
    required this.key,
    required this.percentage,
    required this.time,
    required this.donation,
  });
}
