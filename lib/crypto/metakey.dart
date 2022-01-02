import 'dart:convert';
import 'dart:typed_data';

import 'package:metareward/crypto/crypto.dart';
import 'package:metareward/util/util.dart';
import 'package:pointycastle/ecc/api.dart';

class Metakey {
  String _publicKeyDER = "";
  String _privateKeyDER = "";
  String _address = "";

  late ECPrivateKey _ecPrivateKey;
  late ECPublicKey _ecPublicKey;

  Metakey(String privateKeyDER) {
    if (privateKeyDER != "") {
      _privateKeyDER = privateKeyDER;
      var keypair = Crypto.keyPairFromPrivateDER(privateKeyDER);
      _ecPublicKey = keypair.publicKey;
      _ecPrivateKey = keypair.privateKey;
      _publicKeyDER = Crypto.ecPublicToDER(_ecPublicKey);
      _address = Crypto.getAddress(_ecPublicKey);
    }
  }

  String get privateKey => _privateKeyDER;
  String get publicKey => _publicKeyDER;
  String get address => _address;

  ///
  ///sign the [data] and return the signature string in
  ///DER format
  ///
  String signData(String data) {
    final List<int> d = utf8.encode(data);
    final Uint8List dd = Uint8List.fromList(d);
    final Uint8List sign = Crypto.signData(_ecPrivateKey, dd);
    return Util.byteToHex(sign);
  }

  ///
  ///sign the [data] and return the signature string in
  ///DER format
  ///
  String signTransaction(Uint8List data) {
    final Uint8List sign = Crypto.signData(_ecPrivateKey, data);
    return Util.byteToHex(sign);
  }

  ///
  ///verify signature the [data] and return the signature string in
  ///DER format
  ///
  bool verifySignature(String signature, String data) {
    final Uint8List binData = Util.hexToBytes(data);
    return Crypto.verifyDERSignature(binData, _ecPublicKey, signature);
  }
}
