import 'package:agri4_app/models/crop.dart';

class AgriculturalAdvisory {
  final String cropType;
  final double ndviValue;
  final double moistureIndex;
  final String stressLevel;
  final List<String> recommendations;
  final String irrigationAdvice;
  final String fertilizerAdvice;
  final String pestAdvice;

  AgriculturalAdvisory({
    required this.cropType,
    required this.ndviValue,
    required this.moistureIndex,
    required this.stressLevel,
    required this.recommendations,
    required this.irrigationAdvice,
    required this.fertilizerAdvice,
    required this.pestAdvice,
  });

  static AgriculturalAdvisory generateAdvisory({
    required String cropType,
    required List<double> bbox,
  }) {
    // Simulate satellite data analysis based on location and crop
    final double centerLat = (bbox[1] + bbox[3]) / 2;
    final double centerLon = (bbox[0] + bbox[2]) / 2;
    
    // Generate realistic NDVI based on location and crop
    final double ndviValue = _calculateNDVI(cropType, centerLat, centerLon);
    final double moistureIndex = _calculateMoistureIndex(cropType, centerLat, centerLon);
    final String stressLevel = _determineStressLevel(ndviValue, moistureIndex);
    
    return AgriculturalAdvisory(
      cropType: cropType,
      ndviValue: ndviValue,
      moistureIndex: moistureIndex,
      stressLevel: stressLevel,
      recommendations: _generateRecommendations(cropType, ndviValue, moistureIndex, stressLevel),
      irrigationAdvice: _getIrrigationAdvice(cropType, moistureIndex, stressLevel),
      fertilizerAdvice: _getFertilizerAdvice(cropType, ndviValue, stressLevel),
      pestAdvice: _getPestAdvice(cropType, ndviValue, stressLevel),
    );
  }

  static double _calculateNDVI(String cropType, double lat, double lon) {
    // Simulate NDVI calculation based on crop type and location
    double baseNDVI = 0.5;
    
    // Crop-specific NDVI ranges
    switch (cropType.toLowerCase()) {
      case 'wheat':
        baseNDVI = 0.6 + (lat * 0.001); // Wheat typically has higher NDVI
        break;
      case 'rice':
        baseNDVI = 0.7 + (lat * 0.001); // Rice paddies have very high NDVI
        break;
      case 'maize':
        baseNDVI = 0.5 + (lat * 0.001); // Maize moderate NDVI
        break;
      case 'cotton':
        baseNDVI = 0.4 + (lat * 0.001); // Cotton lower NDVI
        break;
      case 'sugarcane':
        baseNDVI = 0.8 + (lat * 0.001); // Sugarcane very high NDVI
        break;
      case 'vegetables':
        baseNDVI = 0.6 + (lat * 0.001); // Mixed vegetables
        break;
      case 'fruits':
        baseNDVI = 0.5 + (lat * 0.001); // Fruit trees
        break;
    }
    
    // Add some variation based on longitude
    baseNDVI += (lon * 0.0001);
    
    return (baseNDVI * 0.8 + 0.2).clamp(0.1, 0.9);
  }

  static double _calculateMoistureIndex(String cropType, double lat, double lon) {
    // Simulate moisture index based on crop and location
    double baseMoisture = 0.6;
    
    // Pakistan-specific moisture patterns
    if (lat > 30 && lat < 35) { // Punjab region - more moisture
      baseMoisture = 0.7;
    } else if (lat > 24 && lat < 30) { // Sindh region - less moisture
      baseMoisture = 0.4;
    }
    
    // Crop-specific moisture needs
    switch (cropType.toLowerCase()) {
      case 'rice':
        baseMoisture += 0.2; // Rice needs more water
        break;
      case 'cotton':
        baseMoisture -= 0.1; // Cotton needs less water
        break;
      case 'sugarcane':
        baseMoisture += 0.1; // Sugarcane needs more water
        break;
    }
    
    return baseMoisture.clamp(0.1, 0.9);
  }

  static String _determineStressLevel(double ndvi, double moisture) {
    if (ndvi < 0.3 || moisture < 0.3) {
      return 'High Stress';
    } else if (ndvi < 0.5 || moisture < 0.5) {
      return 'Moderate Stress';
    } else if (ndvi < 0.7 || moisture < 0.7) {
      return 'Low Stress';
    } else {
      return 'Healthy';
    }
  }

  static List<String> _generateRecommendations(String cropType, double ndvi, double moisture, String stressLevel) {
    List<String> recommendations = [];
    
    // NDVI-based recommendations
    if (ndvi < 0.3) {
      recommendations.add('🌱 Low vegetation health detected - consider fertilizer application');
    } else if (ndvi > 0.7) {
      recommendations.add('🌿 Excellent vegetation health - maintain current practices');
    }
    
    // Moisture-based recommendations
    if (moisture < 0.3) {
      recommendations.add('💧 Low soil moisture - irrigation recommended');
    } else if (moisture > 0.8) {
      recommendations.add('🌧️ High soil moisture - reduce irrigation');
    }
    
    // Stress level recommendations
    switch (stressLevel) {
      case 'High Stress':
        recommendations.add('⚠️ High stress detected - immediate attention needed');
        recommendations.add('🔍 Check for pests, diseases, or nutrient deficiencies');
        break;
      case 'Moderate Stress':
        recommendations.add('📊 Moderate stress - monitor closely');
        recommendations.add('💡 Consider soil testing and nutrient analysis');
        break;
      case 'Low Stress':
        recommendations.add('✅ Low stress - good crop condition');
        break;
      case 'Healthy':
        recommendations.add('🎉 Excellent crop health - continue current practices');
        break;
    }
    
    // Crop-specific recommendations
    switch (cropType.toLowerCase()) {
      case 'wheat':
        if (ndvi < 0.5) {
          recommendations.add('🌾 Wheat: Consider nitrogen application for better growth');
        }
        break;
      case 'rice':
        if (moisture < 0.6) {
          recommendations.add('🌾 Rice: Maintain water level in paddy fields');
        }
        break;
      case 'cotton':
        if (ndvi < 0.4) {
          recommendations.add('🌿 Cotton: Check for bollworm infestation');
        }
        break;
    }
    
    return recommendations;
  }

  static String _getIrrigationAdvice(String cropType, double moisture, String stressLevel) {
    if (moisture < 0.3) {
      return '💧 Immediate irrigation needed - soil is very dry';
    } else if (moisture < 0.5) {
      return '💧 Irrigation recommended within 2-3 days';
    } else if (moisture > 0.8) {
      return '🌧️ Reduce irrigation - soil is oversaturated';
    } else {
      return '✅ Soil moisture levels are adequate';
    }
  }

  static String _getFertilizerAdvice(String cropType, double ndvi, String stressLevel) {
    if (ndvi < 0.3) {
      return '🌱 Apply nitrogen fertilizer - vegetation health is poor';
    } else if (ndvi < 0.5) {
      return '🌱 Consider balanced fertilizer application';
    } else {
      return '✅ Current nutrient levels appear adequate';
    }
  }

  static String _getPestAdvice(String cropType, double ndvi, String stressLevel) {
    if (stressLevel == 'High Stress' && ndvi < 0.4) {
      return '🐛 Check for pest infestation - stress indicators present';
    } else if (ndvi < 0.5) {
      return '🔍 Monitor for early signs of pest damage';
    } else {
      return '✅ No immediate pest concerns detected';
    }
  }
}

