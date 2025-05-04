import 'dart:convert';

import 'package:http/http.dart' as http;

class CoinGeckoService {
  final String base_Url = 'https://api.coingecko.com/api/v3';


  Future<Map<String, dynamic>> fetchPrices(List<String> ids,String vsCurrency) async {
    final idsString = ids.join(',');
    final url = Uri.parse('$base_Url/simple/price?ids=$idsString&vs_currencies=$vsCurrency');
    final response = await http.get(
      url,
      headers: {
        'accept': 'application/json',
      }
    );

    if(response.statusCode == 200){
      return json.decode(response.body);
    }
    else{
      throw Exception('Failed to fetch prices');
    }





  }






}