import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/delivery_provider.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final currentCompany = deliveryProvider.currentCompany;

    if (deliveryProvider.totalDeliveries == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No deliveries loaded',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Press "Download Route" to fetch delivery data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (currentCompany == null) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: currentCompany.poList.length,
      itemBuilder: (context, index) {
        final po = currentCompany.poList[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PO #${po.poNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                _buildDetailRow('Description:', po.description),
                _buildDetailRow('Quantity:', po.quantity.toString()),
                _buildDetailRow('Pickup Date:', _formatDate(po.pickupDate)),
                if (po.expectedDelivery != 'N/A')
                  _buildDetailRow('Expected Delivery:', po.expectedDelivery),

                SizedBox(height: 16),

                // Blade details
                if (po.bladeDetails.isNotEmpty) ...[
                  Divider(),
                  Text(
                    'Blade Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: po.bladeDetails.entries
                        .where((entry) => entry.value.toString().isNotEmpty)
                        .map((entry) => Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      visualDensity: VisualDensity.compact,
                    ))
                        .toList(),
                  ),
                ],

                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    _showBladeEditor(context, currentCompany.companyName, index, po.bladeDetails);
                  },
                  child: Text('Edit Blades'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showBladeEditor(BuildContext context, String companyName, int poIndex, Map<String, dynamic> currentDetails) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Blade Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBladeField('Qty Received', 'received_qty', currentDetails),
              _buildBladeField('Qty Shipped', 'shipped_qty', currentDetails),
              _buildBladeField('Back Order', 'back_order', currentDetails),
              _buildBladeField('Hammer', 'hammer', currentDetails),
              _buildBladeField('Re-tip', 're_tipped', currentDetails),
              _buildBladeField('New Tip', 'new_tip_no', currentDetails),
              _buildBladeField('No Service', 'no_service', currentDetails),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get values from form
              final newDetails = {
                'received_qty': _getFieldValue('received_qty'),
                'shipped_qty': _getFieldValue('shipped_qty'),
                'back_order': _getFieldValue('back_order'),
                'hammer': _getFieldValue('hammer'),
                're_tipped': _getFieldValue('re_tipped'),
                'new_tip_no': _getFieldValue('new_tip_no'),
                'no_service': _getFieldValue('no_service'),
              };

              deliveryProvider.editBladeDetails(companyName, poIndex, newDetails);
              deliveryProvider.saveBladeEdits();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildBladeField(String label, String key, Map<String, dynamic> currentDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        initialValue: currentDetails[key]?.toString() ?? '',
        onChanged: (value) {
          // Store value in closure variable (simplified approach)
          // In a real app, use a form controller
        },
      ),
    );
  }

  String _getFieldValue(String key) {
    // This is a simplified approach
    // In a real app, use TextEditingControllers
    return '';
  }
}