import 'package:flutter/material.dart';
import 'package:agri4_app/models/agricultural_advisory.dart';

class AdvisoryScreen extends StatelessWidget {
  final AgriculturalAdvisory advisory;

  const AdvisoryScreen({
    super.key,
    required this.advisory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${advisory.cropType} Field Advisory'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(advisory.stressLevel),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Field Status: ${advisory.stressLevel}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCard('NDVI', advisory.ndviValue.toStringAsFixed(2), '🌱'),
                        _buildMetricCard('Moisture', advisory.moistureIndex.toStringAsFixed(2), '💧'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recommendations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌾 Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...advisory.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(child: Text(rec, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Irrigation Advice
            _buildAdviceCard(
              '💧 Irrigation Advice',
              advisory.irrigationAdvice,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Fertilizer Advice
            _buildAdviceCard(
              '🌱 Fertilizer Advice',
              advisory.fertilizerAdvice,
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Pest Advice
            _buildAdviceCard(
              '🐛 Pest & Disease Advice',
              advisory.pestAdvice,
              Colors.red,
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement save advisory
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Advisory saved to field records')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Advisory'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement share advisory
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Advisory shared')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceCard(String title, String advice, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              advice,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String stressLevel) {
    switch (stressLevel) {
      case 'High Stress':
        return Colors.red.shade600;
      case 'Moderate Stress':
        return Colors.orange.shade600;
      case 'Low Stress':
        return Colors.yellow.shade600;
      case 'Healthy':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

