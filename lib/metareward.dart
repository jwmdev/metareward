import 'dart:io';
import 'dart:typed_data';

import 'package:metareward/api/api_service.dart';
import 'package:metareward/config.dart';
import 'package:metareward/model/metatransaction.dart';
import 'package:metareward/model/wallet.dart';
import 'package:metareward/reward/delegators.dart';
import 'package:metareward/util/varuint.dart';
import 'package:metareward/util/util.dart';

import 'crypto/metakey.dart';

class Metareward {
  Config config;
  late Metakey _wallet;
  final ApiService _api = ApiService();

  Metareward({required this.config}) {
    _wallet = Metakey(config.node.key);
  }

  Future<bool> distributeReward() async {
    //get transaction history
    var txs = await _api.fetchHistory(config.node.address);

    if (txs.isEmpty) {
      return false;
    }

    var today = DateTime.now();
    print("Todays reward: $today");
    var rewardDate = DateTime(today.year, today.month, today.day);
    Delegators delegators = Delegators(
        txs: txs,
        nodeAddress: config.node.address,
        rewardPercentage: config.node.percentage / 100.0,
        rewardDate: rewardDate);

    //distribute reward.
    var addresses = delegators.getDelegators();
    if (addresses.isEmpty) {
      return false;
    }

    for (var v in addresses.values) {
      //skip addresses in the skip list
      if (config.isSkip(v.address)) {
        continue;
      }

      //recompute the due amount for special addresses
      if (config.isSpecial(v.address)) {
        var p = config.getSpecialPercentage(v.address)! / 100.0;
        v.dueAmount = v.delegatedAmount /
            delegators.totalDelegation *
            p *
            delegators.reward;
      }

      //transfer the amount
      await _transfer(
          fromAddress: config.node.address,
          toAddress: v.address,
          amount: v.dueAmount as double);
      sleep(Duration(seconds: 5));
    }

    return true;
  }

  //transfer fund
  Future<bool> _transfer(
      {required String fromAddress,
      required String toAddress,
      required double amount,
      String message = "metareward"}) async {
    Wallet w = await _api.fetchBalance(fromAddress);
    if (w == null) return false;
    int nonce = w.countSpent! + 1;
    if (w.getBalance() < amount) {
      return false;
    } //return due to insufficient balance
    int intAmount = (amount * 1e6).toInt();

    MetaTx tx = MetaTx(
      toAddress: toAddress,
      value: intAmount,
      fee: 0,
      nonce: nonce,
      data: message,
    );

    return _sendTransaction(fromAddress: fromAddress, transaction: tx);
  }

  //send transaction fuction is a general function for sending various types of transation
  Future<bool> _sendTransaction({
    required String fromAddress,
    required MetaTx transaction,
  }) async {
    final String trimedAddress = transaction.toAddress.trim().substring(2);
    String data = trimedAddress;
    data += Varuint.encode(transaction.value);
    data += Varuint.encode(transaction.fee);
    data += Varuint.encode(transaction.nonce);

    if (transaction.data.isNotEmpty) {
      //convert message to hex
      final Uint8List msgBytes = Util.stringToBytesUtf8(transaction.data);
      final String msgHex = Util.byteToHex(msgBytes);

      final int le = msgHex.length ~/ 2;
      data += Varuint.encode(le);

      data += msgHex;
    } else {
      data += Varuint.encode(0);
    }

    final Uint8List dataBytes = Util.hexToBytes(data);
    final String signature = _wallet.signTransaction(dataBytes);

    final MetaTxArg metaArg = MetaTxArg(
      toAddress: transaction.toAddress,
      value: transaction.value.toString(),
      fee: transaction.fee.toString(),
      nonce: transaction.nonce.toString(),
      data: Util.byteToHex(Util.stringToBytesUtf8(transaction.data)),
      signature: signature,
      publicKey: _wallet.publicKey,
    );

    var resp = await _api.send(metaArg);

    // TODO(jwmdev): handle invalid response
    //delay for 5 seconds before updating the account
    await Future<dynamic>.delayed(const Duration(seconds: 5));
    print("${transaction.value / 1e6} MHC is sent to ${transaction.toAddress}");

    return true;
  }
}
