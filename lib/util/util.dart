import 'dart:typed_data';
import 'dart:convert';
import 'package:hex/hex.dart';

class Util {
  static List<String> hexArray = '0123456789ABCDEF'.split('');

  /// Decode a BigInt from bytes in big-endian encoding.
  static BigInt _decodeBigInt(List<int> bytes) {
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    return result;
  }

  /// Converts a Uint8List to a hex string
  static String byteToHex(Uint8List bytes) {
    return HEX.encode(bytes); //.toUpperCase();
  }

  static BigInt byteToBigInt(Uint8List bigIntBytes) {
    return _decodeBigInt(bigIntBytes);
  }

  /// Converts a hex string to a Uint8List
  static Uint8List hexToBytes(String hex) {
    return Uint8List.fromList(HEX.decode(hex));
  }

  /// Convert a bigint to a byte array
  static Uint8List bigIntToBytes(BigInt bigInt) {
    return hexToBytes(bigInt.toRadixString(16).padLeft(32, "0"));
  }

  /// Convert a bigint to a byte array
  static String bigIntToHex(BigInt? bigInt) {
    return byteToHex(hexToBytes(bigInt!.toRadixString(16).padLeft(32, "0")));
  }

  /// Converts a hex string to a binary string
  static String hexToBinary(String hex) {
    return BigInt.parse(hex, radix: 16).toRadixString(2);
  }

  /// Converts a binary string into a hex string
  static String binaryToHex(String binary) {
    return BigInt.parse(binary, radix: 2).toRadixString(16).toUpperCase();
  }

  static Uint8List reverse(Uint8List bytes) {
    Uint8List reversed = Uint8List(bytes.length);
    for (int i = bytes.length; i > 0; i--) {
      reversed[bytes.length - i] = bytes[i - 1];
    }
    return reversed;
  }

  static bool isHexString(String input) {
    List<String> hexChars = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F'
    ];
    for (int i = 0; i < input.length; i++) {
      if (!hexChars.contains(input[i])) {
        return false;
      }
    }
    return true;
  }

  // Convert an integer to a byte array
  static Uint8List intToBytes(int integer, int length) {
    Uint8List ret = Uint8List(length);
    for (int i = 0; i < length; i++) {
      ret[i] = integer & 0xff;
      integer = (integer - ret[i]) ~/ 256;
    }
    return Util.reverse(ret);
  }

  /// Convert string to byte array
  static Uint8List stringToBytesUtf8(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  /// Convert byte array to string utf-8
  static String bytesToUtf8String(Uint8List bytes) {
    return utf8.decode(bytes);
  }

  /// Concatenates one or more byte arrays
  ///
  /// @param {List<Uint8List>} bytes
  /// @returns {Uint8List}
  static Uint8List concat(List<Uint8List> bytes) {
    String hex = '';
    bytes.forEach((v) {
      hex += Util.byteToHex(v);
    });
    return Util.hexToBytes(hex);
  }

//This function coverts base64 string into data (Uint8List)
  static Uint8List string2Data(String base64String) {
    return base64Decode(base64String);
  }

//This function converts data (Uint8List) into string
  static String data2String(Uint8List data) {
    return base64Encode(data);
  }

  static Uint8List joinUint8Lists(Uint8List p1, Uint8List p2) {
    List<int> keyList = p1.toList();
    keyList.addAll(p2);
    return Uint8List.fromList(keyList);
  }

//Converts Uint8List to List<int>
  static List<int> toSigned(Uint8List bytes) {
    return List.from(bytes);
  }
}
