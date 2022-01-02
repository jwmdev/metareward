import 'dart:math';
import 'dart:typed_data';

import 'package:metareward/util/util.dart';

/*
 0-249 	         the same number
 250 (0xfa) 	 as uint16
 251 (0xfb) 	 as uint32
 252 (0xfc) 	 as uint64
 253 (0xfd) 	 as uint128
 254 (0xfe) 	 as uint256
 255 (0xff) 	 as uint512
 */

class Varuint {
  ///
  ///encode encode integer [value] into a string
  ///
  static String encode(int value) {
    if (value <= 249) {
      return intToHex(value, 1);
    } else if (value <= pow(2, 16)) {
      return intToHex(250, 1) + intToHex(value, 2);
    } else if (value <= pow(2, 32)) {
      return intToHex(251, 1) + intToHex(value, 4);
    } else {
      return intToHex(252, 1) + intToHex(value, 8);
    }
  }

  ///
  ///intHex converts an interger [value] into string
  ///
  static String intToHex(int value, int len) {
    if (value < 0 || value == 0) return "00";

    //int len = (value.bitLength / 8).ceil();
    //print("Len " + len.toString() + " value = " + value.toString());
    Uint8List list = Uint8List(len);
    for (var i = 0; i < len; i++) {
      list[i] = (value % 256);
      value = value ~/ 256;
    }
    return Util.byteToHex(list);
  }
}
