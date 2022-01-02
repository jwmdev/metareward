import 'package:metareward/model/metatransaction.dart';
import 'package:metareward/model/delegation.dart';
import 'package:metareward/model/transaction_history.dart';
import 'package:metareward/api/network_service.dart';
import 'package:metareward/model/wallet.dart';

class ApiService {
  //Singleton class
  static final ApiService _instance = ApiService.internal();
  ApiService.internal();
  factory ApiService() => _instance;

  final Map<String, dynamic> _body = {
    "jsonrpc": "2.0",
    "id": "1",
    "method": "",
    "params": ""
  };

  final String torUrl = "http://tor.net-main.metahashnetwork.com:5795";
  final Uri torUri = Uri.http("tor.net-main.metahashnetwork.com:5795", "");

  final String proxyUrl = "http://proxy.net-main.metahashnetwork.com:9999";
  final Uri proxyUri = Uri.http("proxy.net-main.metahashnetwork.com:9999", "");

  final NetworkService _client = NetworkService();

//get address balance
  Future<Wallet> fetchBalance(String address) async {
    var method = "fetch-balance";
    var params = {"address": address};
    //Uri uri = Uri.http(torUrl, "");
    var response = await _post(torUri, method, params);
    //print(response);
    response = response["result"];
    var data = Map<String, dynamic>.from(response);
    return Wallet.fromJson(data);
  }

  Future<List<Wallet>> fetchBalances(List<String> addresses) async {
    var method = "fetch-balances";
    var params = {"addresses": addresses};
    var response = await _post(torUri, method, params);

    response = response["result"];

    List<Wallet> wallets = List.empty();
    for (Map<String, dynamic> pro in response) {
      wallets.add(Wallet.fromJson(pro));
    }

    return wallets;
  }

  //Fetch address transactions history
  Future<List<TransactionHistory>> fetchHistory(String address) async {
    var method = "fetch-history";
    //var params = {"address": address, "beginTx": start, "countTxs": txNumber};
    var params = {"address": address};
    var response = await _post(torUri, method, params);
    response = response["result"];
    //print("response: ${response.toString()}");
    //response = List.from(response);

    List<TransactionHistory> history = [];
    for (Map<String, dynamic> pro in response) {
      //print("transaction: ${pro.toString()}");
      history.add(TransactionHistory.fromJson(pro));
    }

    return history;
  }

  //Fetch active delegation of a given
  Future<List<Delegation>> fetchDelegation(
      String address, int start, int txNumber) async {
    var method = "get-address-delegations";
    var params = {"address": address, "beginTx": start, "countTxs": txNumber};
    var response = await _post(torUri, method, params);
    response = response["result"];

    List<Delegation> delegations = List.empty();
    for (Map<String, dynamic> pro in response["states"]) {
      delegations.add(Delegation.fromJson(pro));
    }

    return delegations;
  }

//send fund and returns transaction id
  Future<String> send(final MetaTxArg tx) async {
    var method = "mhc_send";
    var params = {
      "to": tx.toAddress,
      "value": tx.value,
      "fee": tx.fee,
      "nonce": tx.nonce,
      "data": tx.data,
      "pubkey": tx.publicKey,
      "sign": tx.signature
    };
    var response = await _post(proxyUri, method, params);
    String result = response["params"];

    return result;
  }

  Future<dynamic> _post(Uri url, String method, Map params) {
    _body["method"] = method;
    _body["params"] = params;
    return _client.post(url, body: _body);
  }
}
