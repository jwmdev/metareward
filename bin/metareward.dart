// ignore_for_file: unused_local_variable

import 'package:cron/cron.dart';
import 'package:metareward/config.dart';
import 'package:metareward/metareward.dart' as metareward;

Future<void> main(List<String> arguments) async {
  var config = await Config.create();
  if (config != null) {
    print("Metareward has started!");
    print("node address: ${config.node.address}");
    //print("node key: ${config.node.key}");
    print("node percentage: ${config.node.percentage}");
    print("reward distribution time: at ${config.node.time} everyday");
    print("node donation amount: ${config.node.donation}");
    print("skip addresses: ${config.skip}");
    print("special addresses: ${config.special}");
    metareward.Metareward reward = metareward.Metareward(config: config);
    var cronTime = getCronTime(config.node.time);
    print("cron time is: $cronTime");

    //cron job
    final cron = Cron();
    cron.schedule(Schedule.parse(cronTime), () async {
      await reward.distributeReward();
    });
  }
}

String getCronTime(String time) {
  var timeString = "0000-00-00 " + time;
  var t = DateTime.parse(timeString);
  return "${t.minute} ${t.hour} * * *";
}
