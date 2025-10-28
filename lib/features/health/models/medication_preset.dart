class MedicationPreset {
  final String name;
  final String category;
  final List<String> commonDosages;
  final List<String> commonFrequencies;
  final String instructions;
  final String? icon;

  MedicationPreset({
    required this.name,
    required this.category,
    required this.commonDosages,
    required this.commonFrequencies,
    required this.instructions,
    this.icon,
  });
}

// Common medication presets for elderly users
final List<MedicationPreset> medicationPresets = [
  // Blood Pressure
  MedicationPreset(
    name: 'Lisinopril',
    category: 'Blood Pressure',
    commonDosages: ['5mg', '10mg', '20mg', '40mg'],
    commonFrequencies: ['Once daily', 'Twice daily'],
    instructions: 'Take at the same time each day, with or without food',
  ),
  MedicationPreset(
    name: 'Amlodipine',
    category: 'Blood Pressure',
    commonDosages: ['2.5mg', '5mg', '10mg'],
    commonFrequencies: ['Once daily'],
    instructions: 'Take at the same time each day',
  ),
  MedicationPreset(
    name: 'Metoprolol',
    category: 'Blood Pressure',
    commonDosages: ['25mg', '50mg', '100mg'],
    commonFrequencies: ['Once daily', 'Twice daily'],
    instructions: 'Take with or immediately following food',
  ),

  // Cholesterol
  MedicationPreset(
    name: 'Atorvastatin',
    category: 'Cholesterol',
    commonDosages: ['10mg', '20mg', '40mg', '80mg'],
    commonFrequencies: ['Once daily in the evening'],
    instructions: 'Can be taken with or without food',
  ),
  MedicationPreset(
    name: 'Simvastatin',
    category: 'Cholesterol',
    commonDosages: ['10mg', '20mg', '40mg'],
    commonFrequencies: ['Once daily in the evening'],
    instructions: 'Take in the evening',
  ),

  // Diabetes
  MedicationPreset(
    name: 'Metformin',
    category: 'Diabetes',
    commonDosages: ['500mg', '850mg', '1000mg'],
    commonFrequencies: ['Once daily', 'Twice daily', 'Three times daily'],
    instructions: 'Take with meals to reduce stomach upset',
  ),
  MedicationPreset(
    name: 'Glipizide',
    category: 'Diabetes',
    commonDosages: ['5mg', '10mg'],
    commonFrequencies: ['Once daily', 'Twice daily'],
    instructions: 'Take 30 minutes before meals',
  ),

  // Pain Relief
  MedicationPreset(
    name: 'Acetaminophen',
    category: 'Pain Relief',
    commonDosages: ['325mg', '500mg', '650mg'],
    commonFrequencies: ['Every 4-6 hours as needed', 'Every 8 hours as needed'],
    instructions: 'Do not exceed 3000mg per day',
  ),
  MedicationPreset(
    name: 'Ibuprofen',
    category: 'Pain Relief',
    commonDosages: ['200mg', '400mg', '600mg', '800mg'],
    commonFrequencies: ['Every 6-8 hours as needed'],
    instructions: 'Take with food or milk',
  ),

  // Thyroid
  MedicationPreset(
    name: 'Levothyroxine',
    category: 'Thyroid',
    commonDosages: ['25mcg', '50mcg', '75mcg', '100mcg', '125mcg'],
    commonFrequencies: ['Once daily in the morning'],
    instructions: 'Take on empty stomach, 30-60 minutes before breakfast',
  ),

  // Acid Reflux
  MedicationPreset(
    name: 'Omeprazole',
    category: 'Acid Reflux',
    commonDosages: ['20mg', '40mg'],
    commonFrequencies: ['Once daily', 'Twice daily'],
    instructions: 'Take before meals',
  ),

  // Blood Thinner
  MedicationPreset(
    name: 'Warfarin',
    category: 'Blood Thinner',
    commonDosages: ['1mg', '2mg', '2.5mg', '5mg', '10mg'],
    commonFrequencies: ['Once daily'],
    instructions: 'Take at the same time each day, requires regular blood tests',
  ),
  MedicationPreset(
    name: 'Aspirin (Low Dose)',
    category: 'Blood Thinner',
    commonDosages: ['81mg'],
    commonFrequencies: ['Once daily'],
    instructions: 'Take with food to reduce stomach upset',
  ),

  // Vitamins & Supplements
  MedicationPreset(
    name: 'Vitamin D',
    category: 'Vitamins',
    commonDosages: ['1000 IU', '2000 IU', '5000 IU'],
    commonFrequencies: ['Once daily'],
    instructions: 'Take with a meal containing fat',
  ),
  MedicationPreset(
    name: 'Calcium',
    category: 'Vitamins',
    commonDosages: ['500mg', '600mg', '1000mg'],
    commonFrequencies: ['Once daily', 'Twice daily'],
    instructions: 'Take with food, space out from other medications',
  ),
];

