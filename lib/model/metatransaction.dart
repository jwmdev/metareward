enum TransactionType { TRANSFER, DELEGATE, UNDELEGATE }

class MetaTx {
  final String toAddress;
  final int value;
  final int fee;
  final int nonce;
  final String data;

  const MetaTx({
    required this.toAddress,
    required this.value,
    required this.fee,
    required this.nonce,
    required this.data,
  });
}

class MetaTxArg {
  final String toAddress;
  final String value;
  final String fee;
  final String nonce;
  final String data;
  final String signature;
  final String publicKey;
  const MetaTxArg(
      {required this.toAddress,
      required this.value,
      required this.fee,
      required this.nonce,
      required this.data,
      required this.signature,
      required this.publicKey});
}
