import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:pickup_delivery_app/models/delivery_model.dart';
import 'package:pickup_delivery_app/utils/file_utils.dart';

class PdfService {
  Future<String> generateDeliveryReceipt({
    required String companyName,
    required List<DeliveryPO> poItems,
    required String route,
    required String driverId,
  }) async {
    final pdf = pw.Document();
    final date = DateTime.now();
    final currentDate = DateFormat('yyyy-MM-dd').format(date);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(date);

    // Check if we have any PO items
    final pickupDate = poItems.isNotEmpty
        ? DateFormat('MM/dd/yyyy').format(poItems.first.pickupDate)
        : currentDate;

    // Half-letter size: 5.5 x 8.5 inches (139.7 x 215.9 mm)
    // Convert to points: 1 inch = 72 points
    final halfLetterWidth = 5.5 * 72;
    final halfLetterHeight = 8.5 * 72;

    // Smaller margins for half-letter (0.25 inches = 18 points)
    final margin = 18.0;

    // Create PDF content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(halfLetterWidth, halfLetterHeight),
        margin: pw.EdgeInsets.all(margin),
        build: (pw.Context context) {
          // ===== MAIN TABLE DATA =====
          // Create table data OUTSIDE the Column children
          final tableData = <pw.TableRow>[];

          // Headers
          tableData.add(
            pw.TableRow(
              children: [
                _buildTableHeaderCell('Qty Rec'),
                _buildTableHeaderCell('Qty Ship'),
                _buildTableHeaderCell('Back Order'),
                _buildTableHeaderCell('Description'),
                _buildTableHeaderCell('Hammers'),
                _buildTableHeaderCell('Re-tip'),
                _buildTableHeaderCell('New Tip'),
                _buildTableHeaderCell('No Service'),
              ],
            ),
          );

          // Data rows
          for (var po in poItems) {
            final bladeDetails = po.bladeDetails;

            // Extract and clean values
            String qtyRec = bladeDetails['received_qty']?.toString() ?? '0';
            String qtyShip = bladeDetails['shipped_qty']?.toString() ?? '0';
            String backOrder = bladeDetails['back_order']?.toString() ?? '0';
            String description = po.description;
            String hammer = bladeDetails['hammer']?.toString() ?? '0';
            String reTip = bladeDetails['re_tipped']?.toString() ?? '0';
            String newTip = bladeDetails['new_tip_no']?.toString() ?? '0';
            String noService = bladeDetails['no_service']?.toString() ?? '0';

            // Clean values for display (handle 'None')
            qtyRec = _cleanValue(qtyRec);
            qtyShip = _cleanValue(qtyShip);
            backOrder = _cleanValue(backOrder);
            hammer = _cleanValue(hammer);
            reTip = _cleanValue(reTip);
            newTip = _cleanValue(newTip);
            noService = _cleanValue(noService);

            // Truncate description to fit better
            final descriptionDisplay = description.length > 30
                ? '${description.substring(0, 30)}...'
                : description;

            tableData.add(
              pw.TableRow(
                children: [
                  _buildTableCell(qtyRec, fontSize: 8, align: pw.Alignment.center),
                  _buildTableCell(qtyShip, fontSize: 8, align: pw.Alignment.center),
                  _buildTableCell(backOrder, fontSize: 8, align: pw.Alignment.center),
                  _buildTableCell(descriptionDisplay, fontSize: 6, align: pw.Alignment.centerLeft),
                  _buildTableCell(hammer.length > 3 ? hammer.substring(0, 3) : hammer, fontSize: 8, align: pw.Alignment.center),
                  _buildTableCell(reTip.length > 3 ? reTip.substring(0, 3) : reTip, fontSize: 8, align: pw.Alignment.center),
                  _buildTableCell(newTip.length > 3 ? newTip.substring(0, 3) : newTip, fontSize: 8, align: pw.Alignment.center),
                  _buildTableCell(noService.length > 3 ? noService.substring(0, 3) : noService, fontSize: 8, align: pw.Alignment.center),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              // Title
              pw.Center(
                child: pw.Text(
                  'DOUBLE R SHARPENING',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 8),

              // Contact info
              pw.Center(
                child: pw.Text(
                  'Phone: 814-333-1181 | Email: office@doublersharpening.com',
                  style: pw.TextStyle(
                    fontSize: 7,
                  ),
                ),
              ),

              pw.SizedBox(height: 4),

              // Website
              pw.Center(
                child: pw.Text(
                  'Website: https://doublersharpening.com',
                  style: pw.TextStyle(
                    fontSize: 7,
                  ),
                ),
              ),

              pw.SizedBox(height: 12),

              // ===== COMPANY INFO TABLE =====
              pw.Table(
                columnWidths: {
                  0: pw.FixedColumnWidth(57.6), // 0.8 inch = 57.6 points
                  1: pw.FixedColumnWidth(86.4), // 1.2 inch = 86.4 points
                  2: pw.FixedColumnWidth(57.6), // 0.8 inch = 57.6 points
                  3: pw.FixedColumnWidth(86.4), // 1.2 inch = 86.4 points
                },
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      // First row
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        color: PdfColors.grey300,
                        child: pw.Text(
                          'Company:',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                          companyName,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        color: PdfColors.grey300,
                        child: pw.Text(
                          'Pickup:',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                          pickupDate,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      // Second row
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        color: PdfColors.grey300,
                        child: pw.Text(
                          'Delivery:',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                          currentDate,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        color: PdfColors.grey300,
                        child: pw.Text(
                          'Custom:',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                          '_________________',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ===== MAIN TABLE =====
              pw.Table(
                columnWidths: {
                  0: pw.FixedColumnWidth(28.8), // 0.4 inch = 28.8 points
                  1: pw.FixedColumnWidth(28.8), // 0.4 inch = 28.8 points
                  2: pw.FixedColumnWidth(43.2), // 0.6 inch = 43.2 points
                  3: pw.FixedColumnWidth(103), // 1.5 inch = 108 points
                  4: pw.FixedColumnWidth(33.8), // 0.4 inch = 28.8 points
                  5: pw.FixedColumnWidth(28.8), // 0.4 inch = 28.8 points
                  6: pw.FixedColumnWidth(28.8), // 0.4 inch = 28.8 points
                  7: pw.FixedColumnWidth(36.0), // 0.5 inch = 36 points
                },
                border: pw.TableBorder.all(width: 0.25),
                children: tableData,
              ),

              pw.SizedBox(height: 15),

              // ===== SIGNATURE SECTION =====
              pw.Text(
                'Delivery Signature: _________________________',
                style: pw.TextStyle(fontSize: 9),
              ),

              pw.SizedBox(height: 5),

              // ===== FOOTER =====
              pw.Center(
                child: pw.Text(
                  'Generated: $currentDate | Route: $route | Driver: $driverId',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Generate file path and save
    final pdfPath = await FileUtils.generatePDFPath(route, companyName, date);
    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    print('PDF generated at: $pdfPath');
    return pdfPath;
  }

  pw.Container _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.all(2),
      color: PdfColors.grey,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Container _buildTableCell(
      String text, {
        required double fontSize,
        required pw.Alignment align,
      }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(2),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
          ),
          textAlign: align == pw.Alignment.centerLeft
              ? pw.TextAlign.left
              : pw.TextAlign.center,
        ),
      ),
    );
  }

  String _cleanValue(String value) {
    if (value == 'None' || value.isEmpty) {
      return '0';
    }
    return value;
  }

  // Simple placeholder for now (keep as fallback)
  Future<String> generateSimpleReceipt({
    required String companyName,
    required List<DeliveryPO> poItems,
    required String route,
    required String driverId,
  }) async {
    final date = DateTime.now();
    final pdfPath = await FileUtils.generatePDFPath(route, companyName, date);

    // Create a simple text file for now
    final content = '''
    DELIVERY RECEIPT
    ================
    
    Company: $companyName
    Route: $route
    Date: ${DateFormat('yyyy-MM-dd').format(date)}
    Driver: $driverId
    
    PO Items:
    ${poItems.map((po) => '• ${po.poNumber}: ${po.description} (Qty: ${po.quantity})').join('\n')}
    
    Signature: ___________________
    Date: ___________________
    
    Generated by Pick Up & Delivery App v4.0.1
    ''';

    final file = File('$pdfPath.txt');
    await file.writeAsString(content);

    return pdfPath;
  }
}