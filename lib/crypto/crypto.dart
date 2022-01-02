// ignore_for_file: implementation_imports, unnecessary_import

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart' as ans1;

import 'package:crypto/crypto.dart';
import 'package:metareward/util/util.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';
import "package:pointycastle/src/utils.dart";

class Crypto {
  ////
  ///EC Domain parameters for [secp256k1] curve
  ///The private key starts with 3074
  ///
  static final ECDomainParameters k1Domain = ECDomainParameters('secp256k1');

  ///
  ///EC Domain parameters for [secp256r1] curve
  ///The private key starts with 3077
  ///
  static final ECDomainParameters r1Domain = ECDomainParameters('secp256r1');

  ///
  /// Generates a elliptic curve [AsymmetricKeyPair].
  /// The default curve is **secp256k1**
  ///

  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateEcKeyPair(
      {String curve = 'secp256k1'}) {
    var ecDomainParameters = ECDomainParameters(curve);
    var keyParams = ECKeyGeneratorParameters(ecDomainParameters);

    var secureRandom = _getSecureRandom();

    var rngParams = ParametersWithRandom(keyParams, secureRandom);
    var generator = ECKeyGenerator();
    generator.init(rngParams);

    var keypair = generator.generateKeyPair();
    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
        keypair.publicKey as ECPublicKey, keypair.privateKey as ECPrivateKey);
  }

  ///
  /// Generates a elliptic curve [AsymmetricKeyPair] from [privateKeyDER].
  /// The output will depend on the vervision of the elliptic curve used in
  /// generating privateKeyDER. Currently only supported curves are [secp256k1]
  /// and [secp256r1] as per metahash current version
  ///
  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> keyPairFromPrivateDER(
      String privateKeyDER) {
    ECDomainParameters ecDomain = Crypto.r1Domain;
    if (privateKeyDER.substring(0, 4) == "3077") {
      ecDomain = Crypto.r1Domain;
    } else if (privateKeyDER.substring(0, 4) == "3074") {
      ecDomain = Crypto.k1Domain;
    }

    var keyList = Crypto.hex2bin(privateKeyDER);
    ECPrivateKey privateKey = Crypto._asn1ParsePrivateKey(ecDomain, keyList);
    //if (privateKey == null) return null;

    PublicKey publicKey = _publicKeyFromPrivateKey(privateKey);
    //if (publicKey == null) return null;

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
        publicKey as ECPublicKey, privateKey);
  }

  ///
  /// Decode the given [ECPrivateKey] into DER format.
  ///
  static String ecPrivateKeyToDER(ECPrivateKey ecPrivateKey) {
    ans1.ASN1ObjectIdentifier.registerFrequentNames();

    var algo = ecPrivateKey.parameters!.domainName;

    var pubKey = _publicKeyFromPrivateKey(ecPrivateKey);
    var pubder = ecPublicToDER(pubKey);
    var binPub = ans1.ASN1BitString(hex2bin(pubder));

    String prefix = "";
    String algorithm = "";
    String pub = "";
    if (algo.compareTo('secp256r1') == 0) {
      prefix = "3077";
      algorithm = "a00a06082a8648ce3d030107a144";
      pub = bin2hex(binPub.contentBytes(), separator: '').substring(46);
    } else if (algo.compareTo('secp256k1') == 0) {
      prefix = "3074";
      algorithm = "a00706052b8104000aa144";
      pub = bin2hex(binPub.contentBytes(), separator: '').substring(40);
    }

    var pubBin = hex2bin(pub);
    var pubans = ans1.ASN1BitString(pubBin);

    var version = ans1.ASN1Integer(BigInt.from(1));
    var privateKeyAsBytes = encodeBigInt(ecPrivateKey.d);
    var privateKey = ans1.ASN1OctetString(privateKeyAsBytes);

    var privDER = prefix +
        bin2hex(version.encodedBytes, separator: '') +
        bin2hex(privateKey.encodedBytes, separator: '') +
        algorithm +
        bin2hex(pubans.contentBytes(), separator: '');

    return privDER;
  }

  ///
  /// Decode the given  [ECPublicKey] into DER format.
  ///
  static String ecPublicToDER(ECPublicKey publicKey) {
    var algo = publicKey.parameters!.domainName;

    String algorithm = "";
    if (algo.compareTo('secp256r1') == 0) {
      algorithm =
          "3059301306072a8648ce3d020106082a8648ce3d030107"; //ecPublicKey + secp256r1
    } else if (algo.compareTo('secp256k1') == 0) {
      algorithm =
          "3056301006072a8648ce3d020106052b8104000a"; //ecPublicKey + secp256k1
    }

    var encodedBytes = publicKey.Q!.getEncoded(false);
    var subjectPublicKey = ans1.ASN1BitString(encodedBytes);
    return algorithm +
        Crypto.bin2hex(subjectPublicKey.encodedBytes, separator: '');
  }

  ///
  /// encode [ecSignature] into DER format
  ///
  static Uint8List ecSignatureToDER(ECSignature ecSignature) {
    ans1.ASN1Sequence seq = ans1.ASN1Sequence();
    seq.add(ans1.ASN1Integer(ecSignature.r));
    seq.add(ans1.ASN1Integer(ecSignature.s));
    return seq.encodedBytes;
  }

  /// ECSignature to DER format bytes
  static Uint8List ecSigToDER(ECSignature ecSignature) {
    List<int> r = Util.toSigned(encodeBigInt(ecSignature.r));
    List<int> s = Util.toSigned(encodeBigInt(ecSignature.s));

    var rcheck = r[0] & 0x80;
    var scheck = s[0] & 0x80;
    if (rcheck > 0) r.insert(0, 0x00);
    if (scheck > 0) s.insert(0, 0x00);

    List<int> b = List.empty();
    b.add(0x02);
    b.add(r.length);
    b.addAll(r);

    b.add(0x02);
    b.add(s.length);
    b.addAll(s);

    b.insert(0, b.length);
    b.insert(0, 0x30);

    return Uint8List.fromList(b);
  }

  ///
  /// decode [ecSignature] from DER format
  ///
  static ECSignature ecSignatureFromDER(Uint8List bytes) {
    ans1.ASN1Parser parser = ans1.ASN1Parser(bytes);
    ans1.ASN1Sequence seq = parser.nextObject() as ans1.ASN1Sequence;
    BigInt? r = (seq.elements[0] as ans1.ASN1Integer).valueAsBigInteger;
    BigInt? s = (seq.elements[1] as ans1.ASN1Integer).valueAsBigInteger;
    return ECSignature(r!, s!);
  }

  ///
  /// sign the [data] using private key [privateKey] and returns
  /// the ec signature in DER format
  ///
  static Uint8List signData(ECPrivateKey privateKey, Uint8List data,
      {String algorithmName = 'SHA-256/DET-ECDSA'}) {
    var signer = Signer(algorithmName);
    signer.init(true, PrivateKeyParameter<ECPrivateKey>(privateKey));
    //var digest = singleDigest(data); //sha256
    //print("sign data: $data");
    var sig = signer.generateSignature(data) as ECSignature;
    //var hexSig =
    return ecSignatureToDER(sig);
    //return ecSigToDER(sig);
  }

  ///
  /// verify the signature given the public key
  /// TODO: Handle DER format of signature and public key
  ///
  static bool verifyecSignature(
      Uint8List data, ECSignature signature, ECPublicKey pubKey,
      {String algorithmName = 'SHA-256/DET-ECDSA'}) {
    var signer = Signer(algorithmName);
    signer.init(false, PublicKeyParameter<ECPublicKey>(pubKey));
    //var digest = singleDigest(data);

    return signer.verifySignature(data, signature);
  }

  static bool verifyDERSignature(
      Uint8List data, ECPublicKey pubKey, String signature,
      {String algorithmName = 'SHA-256/DET-ECDSA'}) {
    var signer = Signer(algorithmName);

    signer.init(false, PublicKeyParameter<ECPublicKey>(pubKey));
    //var digest = singleDigest(data);
    var binSignature = hex2bin(signature);
    ECSignature sign = ecSignatureFromDER(binSignature);

    return signer.verifySignature(data, sign);
  }

  static String getAddress(ECPublicKey publicKey) {
    var x = _getPubX(publicKey);
    var y = _getPubY(publicKey);

    // address generation based on steps described here
    //https://metahash.zendesk.com/hc/en-us/articles/360002712193-Getting-started-with-Metahash-network
    //step 1
    var xsub = x.substring(0, 64);
    var ysub = y.substring(0, 64);
    var step1 = "04" + xsub + ysub;
    var step1b = Util.hexToBytes(step1);

    //step 2 - hashing
    var step2 = Crypto.singleDigest(step1b);

    //step 3
    var step3 = Crypto.ripemd160Digest(step2);
    var step3b = "00" + Util.byteToHex(step3);
    var step3c = Util.hexToBytes(step3b);

    //step 4
    var step4 = Crypto.singleDigest(step3c);
    //print(step4);

    //step 5
    var step5 = Crypto.stringSingleDigest(step4);
    //print(step5);

    //step 6
    var address = "0x" + step3b + step5.substring(0, 8);
    return address;
  }

  static Uint8List aesCbcEncrypt(
      Uint8List key, Uint8List iv, Uint8List paddedPlaintext) {
    if (![128, 192, 256].contains(key.length * 8)) {
      throw ArgumentError.value(key, 'key', 'invalid key length for AES');
    }
    if (iv.length * 8 != 128) {
      throw ArgumentError.value(iv, 'iv', 'invalid IV length for AES');
    }
    if (paddedPlaintext.length * 8 % 128 != 0) {
      throw ArgumentError.value(
          paddedPlaintext, 'paddedPlaintext', 'invalid length for AES');
    }

    // Create a CBC block cipher with AES, and initialize with key and IV

    final cbc = CBCBlockCipher(AESFastEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt

    // Encrypt the plaintext block-by-block

    final cipherText = Uint8List(paddedPlaintext.length); // allocate space

    var offset = 0;
    while (offset < paddedPlaintext.length) {
      offset += cbc.processBlock(paddedPlaintext, offset, cipherText, offset);
    }
    assert(offset == paddedPlaintext.length);

    return cipherText;
  }
//----------------------------------------------------------------

  static Uint8List aesCbcDecrypt(
      Uint8List key, Uint8List iv, Uint8List cipherText) {
    if (![128, 192, 256].contains(key.length * 8)) {
      throw ArgumentError.value(key, 'key', 'invalid key length for AES');
    }
    if (iv.length * 8 != 128) {
      throw ArgumentError.value(iv, 'iv', 'invalid IV length for AES');
    }
    if (cipherText.length * 8 % 128 != 0) {
      throw ArgumentError.value(
          cipherText, 'cipherText', 'invalid length for AES');
    }

    // Create a CBC block cipher with AES, and initialize with key and IV

    final cbc = CBCBlockCipher(AESFastEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv)); // false=decrypt

    // Decrypt the cipherText block-by-block

    final paddedPlainText = Uint8List(cipherText.length); // allocate space

    var offset = 0;
    while (offset < cipherText.length) {
      offset += cbc.processBlock(cipherText, offset, paddedPlainText, offset);
    }
    assert(offset == cipherText.length);

    return paddedPlainText;
  }

  /// Added padding
  static Uint8List pad(Uint8List bytes, int blockSize) {
    // The PKCS #7 padding just fills the extra bytes with the same value.
    // That value is the number of bytes of padding there is.
    //
    // For example, something that requires 3 bytes of padding with append
    // [0x03, 0x03, 0x03] to the bytes. If the bytes is already a multiple of the
    // block size, a full block of padding is added.

    final padLength = blockSize - (bytes.length % blockSize);

    final padded = Uint8List(bytes.length + padLength)..setAll(0, bytes);
    PKCS7Padding().addPadding(padded, bytes.length);

    return padded;
  }

//----------------------------------------------------------------
  /// Remove padding
  static Uint8List unpad(Uint8List padded) =>
      padded.sublist(0, padded.length - PKCS7Padding().padCount(padded));

//----------------------------------------------------------------
  /// Derive a key from a passphrase.
  ///
  /// The [passphrase] is an arbitrary length secret string.
  ///
  /// The [bitLength] is the length of key produced. It determines whether
  /// AES-128, AES-192, or AES-256 will be used. It must be one of those values.
  static Uint8List passphraseToKey(String passPhrase,
      {String salt = '', int iterations = 30000, int bitLength = 128}) {
    if (![128, 192, 256].contains(bitLength)) {
      throw ArgumentError.value(bitLength, 'bitLength', 'invalid for AES');
    }
    final numBytes = bitLength ~/ 8;
    final salt2 = Uint8List.fromList(utf8.encode(salt));
    final pass = Uint8List.fromList(utf8.encode(passPhrase));

    final kd = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64)) // 64 for SHA-256
      ..init(Pbkdf2Parameters(salt2, iterations, numBytes));

    return kd.process(pass);
  }

  ///
  ///encrypt function encrypts [hex] string with a [passphrase]
  ///the iv value in hex is appended at the begining of the encrypted string
  static String encrypt(String passphrase, String hex) {
    //metahash uses 128 bitlength, so we use the same bitlength
    var key = Crypto.passphraseToKey(passphrase, bitLength: 128);
    var iv = _getSecureRandomBytes(16);

    var cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESFastEngine()),
    )..init(
        true /*encrypt*/,
        PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
          ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
          null,
        ),
      );

    //var plainBytes = utf8.encode(base64.encode(utf8.encode(plainText)));
    var cipherText = cipher.process(Crypto.hex2bin(hex));
    return Crypto.bin2hex(iv, separator: '') +
        Crypto.bin2hex(cipherText, separator: '');
  }

  static String decrypt(String passphrase, String ciphertext) {
    var key = Crypto.passphraseToKey(passphrase, bitLength: 128);
    var params = ciphertext.substring(0, 32); //extract iv from ciphertext
    var iv = Crypto.hex2bin(params);
    var cipherData = Crypto.hex2bin(ciphertext.substring(32));

    var cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESFastEngine()),
    );

    cipher.init(
      false /*decrypt*/,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
        null,
      ),
    );

    var plainText = cipher.process(cipherData);

    //print(utf8.decode(base64.decode(utf8.decode(plainishText))));
    return Crypto.bin2hex(plainText, separator: '');
  }

//----------------supporting functions ---------------------

  ///
  /// Generates a secure [FortunaRandom]
  ///
  static SecureRandom _getSecureRandom() {
    var _secureRandom = FortunaRandom();
    var random = Random.secure();
    var seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    _secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return _secureRandom;
  }

  ///
  /// Generate random bytes with [len] length
  /// Could be used for Initialization Vector (IV).
  ///
  static Uint8List _getSecureRandomBytes(int len) {
    var _secureRandom = FortunaRandom();

    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    _secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final iv = _secureRandom.nextBytes(len);
    return iv;
  }

  // Parses a DER-encoded ASN.1 ECDSA private key block.
  static ECPrivateKey _asn1ParsePrivateKey(
      ECDomainParameters ecDomain, Uint8List privateKey) {
    ans1.ASN1Parser parser = ans1.ASN1Parser(privateKey);
    ans1.ASN1Sequence seq = parser.nextObject() as ans1.ASN1Sequence;
    assert(seq.elements.length >= 2);
    ans1.ASN1OctetString keyOct = seq.elements[1] as ans1.ASN1OctetString;

    //BigInteger d = new BigInteger.fromBytes(1, keyOct.octets);
    var dd = keyOct.contentBytes();
    BigInt d = decodeBigInt(dd!);
    return ECPrivateKey(d, ecDomain);
  }

  ///
  ///get [ECPublicKey] from [privateKey]
  ///
  static ECPublicKey _publicKeyFromPrivateKey(ECPrivateKey privateKey) {
    ECPoint? Q = privateKey.parameters!.G * privateKey.d;
    return ECPublicKey(Q, privateKey.parameters);
  }

  /// Represent bytes in hexadecimal
  /// If a [separator] is provided, it is placed the hexadecimal characters
  /// representing each byte. Otherwise, all the hexadecimal characters are
  /// simply concatenated together.
  ///
  static String bin2hex(Uint8List bytes,
      {required String separator, int? wrap}) {
    var len = 0;
    final buf = StringBuffer();
    for (final b in bytes) {
      final s = b.toRadixString(16);
      if (buf.isNotEmpty && separator != "") {
        buf.write(separator);
        len += separator.length;
      }

      if (wrap != null && wrap < len + 2) {
        buf.write('\n');
        len = 0;
      }

      buf.write('${(s.length == 1) ? '0' : ''}$s');
      len += 2;
    }
    return buf.toString();
  }

  ///
  /// Decode a hexadecimal string [hexStr] into a sequence of bytes.
  ///

  static Uint8List hex2bin(String hexStr) {
    if (hexStr.length % 2 != 0) {
      throw const FormatException(
          'not an even number of hexadecimal characters');
    }
    final result = Uint8List(hexStr.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hexStr.substring(2 * i, 2 * (i + 1)), radix: 16);
    }
    return result;
  }

  ///
  /// Get a SHA256 hash bytes for the given [bytes].
  ///
  static Uint8List singleDigest(Uint8List bytes) =>
      SHA256Digest().process(bytes);

  ///
  /// Get a SHA256 hash string for the given [bytes].
  ///
  static String stringSingleDigest(Uint8List bytes) {
    var digest = sha256.convert(bytes);
    return digest.toString(); //.toUpperCase();
  }

  ///
  /// Calculates the RIPEMD-160 hash of the given [bytes].
  ///
  static Uint8List ripemd160Digest(Uint8List bytes) =>
      RIPEMD160Digest().process(bytes);

  ///
  /// Get a MD5 Thumbprint for the given [bytes].
  ///
  static String getMd5ThumbprintFromBytes(Uint8List bytes) {
    var digest = md5.convert(bytes);
    return digest.toString().toUpperCase();
  }

  ///
  ///get [x] coordinate of the public key [pubKey]
  ///
  static String _getPubX(ECPublicKey pubKey) {
    return Util.bigIntToHex(pubKey.Q!.x!.toBigInteger());
  }

  ///
  ///get [y] coordinate of the public key [pubKey]
  ///
  static String _getPubY(ECPublicKey pubKey) {
    return Util.bigIntToHex(pubKey.Q!.y!.toBigInteger());
  }
}
