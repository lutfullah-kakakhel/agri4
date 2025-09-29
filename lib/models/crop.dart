class Crop {
  final String id;
  final String name;
  final String imagePath;
  final String description;

  const Crop({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
  });

  static const List<Crop> crops = [
    Crop(
      id: 'wheat',
      name: 'Wheat',
      imagePath: 'assets/images/wheat.svg',
      description: 'Wheat cultivation',
    ),
    Crop(
      id: 'rice',
      name: 'Rice',
      imagePath: 'assets/images/rice.svg',
      description: 'Rice paddy cultivation',
    ),
    Crop(
      id: 'maize',
      name: 'Maize',
      imagePath: 'assets/images/maize.svg',
      description: 'Corn/Maize cultivation',
    ),
    Crop(
      id: 'cotton',
      name: 'Cotton',
      imagePath: 'assets/images/cotton.svg',
      description: 'Cotton cultivation',
    ),
    Crop(
      id: 'sugarcane',
      name: 'Sugarcane',
      imagePath: 'assets/images/sugarcane.svg',
      description: 'Sugarcane cultivation',
    ),
    Crop(
      id: 'vegetables',
      name: 'Vegetables',
      imagePath: 'assets/images/vegetables.svg',
      description: 'Mixed vegetables',
    ),
    Crop(
      id: 'fruits',
      name: 'Fruits',
      imagePath: 'assets/images/fruits.svg',
      description: 'Fruit orchards',
    ),
  ];
}

