import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class AnaSehife extends StatefulWidget {
  @override
  State<AnaSehife> createState() => _AnaSehifeState();
}

class _AnaSehifeState extends State<AnaSehife> {
  final String? _apiKey = dotenv.env['API_KEY'];

  String _baseURL = "http://api.exchangeratesapi.io/v1/latest?access_key=";

  Map<String, double> _nisbetler = {};

  String _secilenDeyer = "USD";

  double _netice = 0;

  TextEditingController _controller=TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _internetdenDataAl();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _nisbetler.isNotEmpty ? _buildBody():Center(child: CircularProgressIndicator()),
      backgroundColor: Colors.black,
    );
  }


/*
  ******************
  * APPBAR
  * ****************
   */
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: Text(
        "Valyuta çevirici",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Colors.white,
        ),
      ),
    );
  }


/*
  ******************
  * BODY
  * ****************
   */
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField()),
              SizedBox(width: 20),
              _buildDropdownButton(),
            ],
          ),
          SizedBox(height: 20),
          _buildNeticeText(),
          SizedBox(height: 20),
          _buildContainer(),
          SizedBox(height: 20),
          _buildListView()
        ],
      ),
    );
  }


/*
  ******************
  * TEXT FIELD
  * ****************
   */
  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: Colors.white),
      cursorColor: Colors.white60,
      onChanged: (String value){
        _hesabla();
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        hintText: "Miqdarı daxil edin",
        hintStyle: TextStyle(color: Colors.white60),
        prefixIcon: Icon(Icons.search, color: Colors.white60,),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white60),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }


/*
  ******************
  * DROPDOWN BUTTON
  * ****************
   */
  Widget _buildDropdownButton() {
    return SizedBox(
      width: 80,
      child: DropdownButton<String>(
        value: _secilenDeyer,
        style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 20),
        dropdownColor: Color(0xFF252424),
        iconSize: 30,
        borderRadius: BorderRadius.circular(10),
        menuWidth: 100,
        menuMaxHeight: 500,
        items:
            _nisbetler.keys.map((String valyuta) {
              return DropdownMenuItem<String>(
                child: Text(valyuta),
                value: valyuta,
              );
            }).toList(),
        onChanged: (String? yeniDeyer) {
          if (yeniDeyer != null) {
            setState(() {
              _secilenDeyer = yeniDeyer;
              _hesabla();
            });
          }
        },
      ),
    );
  }

/*
  ******************
  * NETICE TEXT
  * ****************
   */
  Widget _buildNeticeText() {
    return Text(
      "${_netice.toStringAsFixed(2)} AZN",
      style: TextStyle(fontSize: 30, color: Colors.white),
    );
  }


/*
  ******************
  * AYIRMA CONTAINERI
  * ****************
   */
  Widget _buildContainer() {
    return Container(height: 2, color: Colors.white54);
  }


/*
  ******************
  * LIST VIEW
  * ****************
   */
  Widget _buildListView() {
    return Expanded(
      child: ListView.builder(
        itemBuilder: _buildListItem,
        itemCount: _nisbetler.keys.length,
      ),
    );
  }


/*
  ******************
  * LIST ITEMS
  * ****************
   */
  Widget _buildListItem(BuildContext context, int index) {
    return Card(
      color: Colors.white10,
      child: ListTile(
        title: Text("1 ${_nisbetler.keys.toList()[index]}", style: TextStyle(color: Colors.white, fontSize: 20),),
        trailing: Text(
          "${_nisbetler.values.toList()[index].toStringAsFixed(2)} AZN",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }


/*
  ******************
  * HESABLA FUNKSIYASI
  * ****************
   */
  void _hesabla(){
    double? _deger = double.tryParse(_controller.text);
    double? _nisbet = _nisbetler[_secilenDeyer];

    if (_controller.text.isEmpty) {
      setState(() {
        _netice = 0;
      });
      return;
    }

    if(_deger!=null && _nisbet!=null){
      setState(() {
        _netice=_deger*_nisbet;
      });
    }
  }


/*
  ******************
  * INTERNETDEN DATA AL
  * ****************
   */
  void _internetdenDataAl() async {
    try {
      Uri uri = Uri.parse(_baseURL + _apiKey!);
      http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        print('HTTP error: ${response.statusCode}');
        return;
      }

      Map<String, dynamic> parsedResponse = jsonDecode(response.body);

      // API başarısızsa hata mesajını yazdır
      if (parsedResponse["success"] != true) {
        print('API error: ${parsedResponse["error"]?["info"] ?? "Bilinmeyen hata"}');
        return;
      }

      // "rates" verisi yoksa hata ver
      if (parsedResponse["rates"] == null) {
        print("API yanıtında 'rates' verisi bulunamadı!");
        return;
      }

      Map<String, dynamic> rates = parsedResponse["rates"];

      // AZN kuru yoksa varsayılan olarak hesapla
      double baseAZN = rates["AZN"] ?? (rates["USD"] != null ? rates["USD"] * 1.7 : null);

      if (baseAZN == null) {
        print('AZN kuru bulunamadı ve hesaplanamadı!');
        return;
      }

      Map<String, double> yeniNisbetler = {};

      rates.forEach((String olkeVal, dynamic baseVal) {
        double? baseValDouble = double.tryParse(baseVal.toString());
        if (baseValDouble != null) {
          double azeVal = baseAZN / baseValDouble ;
          yeniNisbetler[olkeVal] = azeVal;
        }
      });

      setState(() {
        _nisbetler = yeniNisbetler;
        _secilenDeyer = _nisbetler.keys.first;
      });

    } catch (e) {
      print("İnternet bağlantı hatası: $e");
    }
  }


}

/*
{
    "success": true,
    "timestamp": 1519296206,
    "base": "EUR",
    "date": "2021-03-17",
    "rates": {
        "AUD": 1.566015,
        "CAD": 1.560132,
        "CHF": 1.154727,
        "CNY": 7.827874,
        "GBP": 0.882047,
        "JPY": 132.360679,
        "USD": 1.23396,
    [...]
    }
}
*/
