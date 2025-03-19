import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temp_gas_station/models/fuel_fill_model.dart';
import 'package:temp_gas_station/models/sky_band_payment.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SkyBandPayment {
  final MethodChannel _madaChannel = const MethodChannel('sky_band_payment');
  List<FuelFillModel> recentTransactions = [];
  bool showTableView = false;
  Future<void> handleMadaPayment(FuelFillModel transaction) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final result = await _madaChannel.invokeMethod('makePayment', {
        'amount': transaction.amount.toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mada Payment Result: $result')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Mada Payment Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  FuelFillModel? currentTransaction;
  bool isLoading = false;
  String? errorMessage;
  bool showTransactionDetails = false;
  //final MethodChannel _printerChannel = const MethodChannel('pos_printer');

  Future<void> fetchPaymentData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://qservsprinter3-001-site1.itempurl.com/api/Transaction/GetSellFuel'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            currentTransaction = FuelFillModel.fromJson(data.first);
            showTransactionDetails = true;
          });
        } else {
          setState(() {
            errorMessage = "No transactions available";
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to fetch data: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // Add this method after fetchPaymentData()
  Future<void> fetchRecentTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      showTransactionDetails = false;
      showTableView = false; // Reset table view
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://qservsprinter3-001-site1.itempurl.com/api/Transaction/GetSellFuel'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            recentTransactions = data
                .take(10)
                .map((json) => FuelFillModel.fromJson(json))
                .toList();
            showTableView = true;
          });
        } else {
          setState(() {
            errorMessage = "No transactions available";
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to fetch data: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void goBack() {
    setState(() {
      showTransactionDetails = false;
      currentTransaction = null;
      errorMessage = null;
    });
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Add AppBar with back button when showing transaction details
      appBar: (showTransactionDetails || showTableView)
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.blue[900]),
                onPressed: () {
                  setState(() {
                    if (showTransactionDetails) {
                      showTransactionDetails = false;
                      currentTransaction = null;
                    }
                    if (showTableView) {
                      showTableView = false;
                    }
                    errorMessage = null;
                  });
                },
              ),
            )
          : null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo.jpeg',
              width: 200,
              height: 150,
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (!showTransactionDetails && !showTableView)
              Column(
                // Changed from Row to Column
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : fetchPaymentData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Pay Now",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Changed from width to height
                  Padding(
                    padding: const EdgeInsets.only(top: 20), // Adjusted padding
                    child: ElevatedButton(
                      onPressed: isLoading ? null : fetchRecentTransactions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Last Transactions",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            if (showTransactionDetails && currentTransaction != null) ...[
              Expanded(
                // Wrap with Expanded
                child: SingleChildScrollView(
                  // Add ScrollView
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Receipt',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentTransaction!.transactionDate}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          const Divider(thickness: 1.5),
                          const SizedBox(height: 15),
                          _buildReceiptRow(
                              'Invoice No:', currentTransaction!.invoiceNumber),
                          _buildReceiptRow(
                              'Transaction ID:', '${currentTransaction!.id}'),
                          const SizedBox(height: 15),
                          const Divider(),
                          _buildReceiptRow(
                              'Fuel Type:', currentTransaction!.fuelType),
                          _buildReceiptRow(
                              'Volume:', '${currentTransaction!.volume} L'),
                          _buildReceiptRow('Unit Price:',
                              '${currentTransaction!.price} SAR'),
                          const Divider(thickness: 1.5),
                          const SizedBox(height: 10),
                          _buildReceiptRow('Total Amount:',
                              '${currentTransaction!.amount} SAR',
                              isBold: true),
                          const SizedBox(height: 15),
                          const Divider(),
                          _buildReceiptRow(
                              'Employee:', '${currentTransaction!.employee}'),
                          _buildReceiptRow('Employee ID:',
                              '${currentTransaction!.employeeId}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => makePayment(currentTransaction!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      child: const Text(
                        "Send to Mada",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ElevatedButton(
                    //   onPressed: isLoading
                    //       ? null
                    //       : () async {
                    //           try {
                    //             await _printerChannel.invokeMethod('print',
                    //                 {'data': currentTransaction?.toJson()});
                    //           } catch (e) {
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               SnackBar(
                    //                   content: Text('Printing failed: $e')),
                    //             );
                    //           }
                    //         },
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.orange,
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 20, vertical: 15),
                    //   ),
                    //   // child: const Text(
                    //   //   "Print Receipt",
                    //   //   style: TextStyle(color: Colors.white),
                    //   // ),
                    // ),
                  ],
                ),
              ),
            ],
            if (showTableView)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width,
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              horizontalMargin: 10,
                              columns: const [
                                DataColumn(
                                  label: Expanded(
                                    child: Text('ID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Fuel',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Amount',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Price',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Volume',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    child: Text('Employee Id',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                              rows: recentTransactions.map((transaction) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${transaction.id ?? "-"}')),
                                    DataCell(Text(transaction.fuelType)),
                                    DataCell(Text('${transaction.amount}')),
                                    DataCell(Text('${transaction.price}')),
                                    DataCell(Text('${transaction.volume}')),
                                    DataCell(Text(
                                        '${transaction.employeeId ?? "-"}')),
                                  ],
                                  onSelectChanged: (bool? selected) {
                                    if (selected != null && selected) {
                                      setState(() {
                                        currentTransaction = transaction;
                                        showTransactionDetails = false;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
