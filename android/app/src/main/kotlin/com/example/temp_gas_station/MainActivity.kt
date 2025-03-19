package com.example.gas_satation
import androidx.annotation.NonNull
import java.security.MessageDigest
import com.skyband.ecr.sdk.CLibraryLoad
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import com.sunmi.peripheral.printer.InnerPrinterCallback
import com.sunmi.peripheral.printer.InnerPrinterException
import com.sunmi.peripheral.printer.InnerPrinterManager
import com.sunmi.peripheral.printer.SunmiPrinterService

val TAG = "MainActivity"

class MainActivity: FlutterActivity() {
    private val PAYMENT_CHANNEL = "sky_band_payment"
    private val PRINTER_CHANNEL = "pos_printer"
    private var printerService: SunmiPrinterService? = null
    private var paymentResult: MethodChannel.Result? = null

    // Keep only this single declaration of paymentReceiver
    private val paymentReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.skyband.pos.app.PAYMENT_RESULT") {
                // Get port and connection type information
                val portNo = intent.getStringExtra("PortNo")
                val connectionType = intent.getStringExtra("ConnectionType")
                
                // Log connection details4
                
                portNo?.let { port ->
                    Log.i("MadaPayment", "Port Number: $port")
                    // Store port number for future use if needed
                }
                
                connectionType?.let { type ->
                    Log.i("MadaPayment", "Connection Type: $type")
                    // Store connection type for future use if needed
                }

                val receivedDataByte = intent.getByteArrayExtra("app-to-app-response")
                
                paymentResult?.let { result ->
                    if (receivedDataByte != null && receivedDataByte.isNotEmpty()) {
                        try {
                            val receivedIntentData = String(receivedDataByte, Charsets.UTF_8)
                                .replace("�", ";")
                            Log.i("MadaPayment", "Received ECR Response >> $receivedIntentData")
                            result.success(receivedIntentData)
                        } catch (e: Exception) {
                            Log.e("MadaPayment", "Failed to process response", e)
                            result.error("RESPONSE_ERROR", "Failed to process response", e.message)
                        }
                    } else {
                        result.error("EMPTY_RESPONSE", "No response data received", null)
                    }
                    paymentResult = null
                }
            }
        }
    }

    private val printerCallback = object : InnerPrinterCallback() {
        override fun onConnected(service: SunmiPrinterService) {
            printerService = service
        }

        override fun onDisconnected() {
            printerService = null
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        registerReceiver(
            paymentReceiver,
            IntentFilter("com.skyband.pos.app.PAYMENT_RESULT")
        )
    
        // Initialize printer...
    
        // Payment channel
           // Payment channel
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PAYMENT_CHANNEL).setMethodCallHandler { call, result ->
        if (call.method == "makePayment") {
            val amount = call.argument<String>("amount")
            if (amount != null) {
                try {
                    // First launch to ensure POS app is running
                    val launchIntent = packageManager.getLaunchIntentForPackage("com.skyband.pos.app")
                    launchIntent?.let { intent ->
                        intent.putExtra("message", "ecr-local-event")
                        startActivity(intent)
                        
                        // Now prepare and send the transaction
                        val timeStamp = System.currentTimeMillis().toString()
                        val terminalId = "8184000200000077" // Your terminal ID
                        val lastSixDigits = timeStamp.takeLast(6)
                        val signature = computeSha256Hash(lastSixDigits + terminalId)
                        val transactionType = 0 // Purchase transaction
                        val printFlag = "1"
                        
                        // Format: date;purchaseAmount;printFlag;ecrReferenceNo!
                        val requestData = "$timeStamp;$amount;$printFlag;$timeStamp!"
                        
                        val packedData = CLibraryLoad.getInstance()
                            .getPackData(requestData, transactionType, signature)

                        // Send transaction data
                        val txnIntent = Intent()
                        txnIntent.setPackage("com.skyband.pos.app")
                        txnIntent.putExtra("message", "ecr-txn-event")
                        txnIntent.putExtra("request", packedData)
                        txnIntent.putExtra("packageName", "com.skyband.ecr")
                        txnIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        paymentResult = result
                        startActivity(txnIntent)
                    } ?: run {
                        result.error("APP_NOT_FOUND", "Skyband POS app not found", null)
                    }
                } catch (e: Exception) {
                    Log.e("MadaPayment", "Payment error", e)
                    result.error("PAYMENT_ERROR", e.message, null)
                }
            }
        }
    }
        // Printer channel...
    }

    private fun printReceipt(data: Map<String, Any>) {
        printerService?.let { printer ->
            try {
                printer.setAlignment(1, null)  // Center alignment
                printer.printText("*** FUEL RECEIPT ***\n", null)
                printer.setAlignment(0, null)  // Left alignment
                printer.printText("Fuel Type: ${data["fuelType"]}\n", null)
                printer.printText("Amount: ${data["amount"]}\n", null)
                printer.printText("Price: ${data["price"]}\n", null)
                printer.printText("Invoice: ${data["invoiceNumber"]}\n", null)
                printer.printText("-------------------------\n", null)
                printer.lineWrap(3, null)  // Feed paper
                printer.cutPaper(null)     // Cut paper if supported
            } catch (e: Exception) {
                Log.e("PrintError", "Failed to print", e)
                throw e
            }
        } ?: throw Exception("Printer service not connected")
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(paymentReceiver)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error unregistering receiver", e)
        }
        InnerPrinterManager.getInstance().unBindService(this, printerCallback)
    }

    // Compute SHA-256 Hash
    private fun computeSha256Hash(combinedValue: String): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hashBytes = digest.digest(combinedValue.toByteArray())
            hashBytes.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            Log.e("SHA-256", "Error computing hash", e)
            ""
        }
    }
}