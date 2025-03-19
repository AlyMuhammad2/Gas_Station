import 'dart:async';
//import 'dart:convert';
import 'package:flutter/services.dart';
////import 'package:http/http.dart' as http;

import 'fuel_fill_model.dart';

mixin SkyBandPayment {
  final MethodChannel _channel = const MethodChannel('sky_band_payment');

  /// Fetch the latest transaction and process payment
  Future<String> makePayment(FuelFillModel fuelFillModel) async {
    try {
      // Directly use the provided transaction amount
      final String result = await _channel.invokeMethod(
          'makePayment', {'amount': fuelFillModel.amount.toStringAsFixed(2)});
      return result;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}
