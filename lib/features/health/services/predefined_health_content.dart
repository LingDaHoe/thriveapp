import '../models/health_content.dart';

class PredefinedHealthContent {
  static List<HealthContent> getPredefinedContent() {
    return [
      // Cardiovascular Health
      HealthContent(
        id: 'cv_heart_health',
        title: 'Understanding Heart Health',
        description: 'Learn essential tips for maintaining a healthy heart as you age.',
        type: ContentType.article,
        category: ContentCategory.cardiovascular,
        content: '''# Understanding Heart Health

Your heart is one of the most vital organs in your body. Here are key strategies to maintain heart health as you age:

## Key Factors for Heart Health

### 1. Regular Exercise
- Aim for 150 minutes of moderate exercise per week
- Include activities like walking, swimming, or gentle cycling
- Start slow and gradually increase intensity
- Consult your doctor before starting a new exercise routine

### 2. Healthy Diet
- Focus on whole foods: fruits, vegetables, whole grains
- Limit processed foods and added sugars
- Reduce sodium intake
- Include healthy fats like olive oil and nuts

### 3. Stress Management
- Practice mindfulness and meditation
- Get adequate sleep (7-9 hours per night)
- Maintain social connections
- Find activities you enjoy

### 4. Regular Check-ups
- Monitor blood pressure regularly
- Get cholesterol checked annually
- Follow your doctor's recommendations

## Warning Signs to Watch For
- Chest pain or discomfort
- Shortness of breath
- Irregular heartbeat
- Fatigue or weakness
- Swelling in legs or ankles
- Dizziness or fainting

**Remember**: Always consult your healthcare provider for personalized advice and if you experience any concerning symptoms.''',
        duration: 8,
        createdAt: DateTime.now(),
      ),
      HealthContent(
        id: 'cv_exercise',
        title: 'Heart-Healthy Exercises for Seniors',
        description: 'Safe and effective exercises to improve cardiovascular health.',
        type: ContentType.article,
        category: ContentCategory.cardiovascular,
        content: '''# Heart-Healthy Exercises for Seniors

Regular physical activity is essential for maintaining heart health. Here are safe exercises recommended for seniors:

## Low-Impact Exercises

### Walking
- Start with 10-15 minutes daily
- Gradually increase to 30 minutes
- Walk at a comfortable pace
- Use proper footwear and stay hydrated

### Swimming
- Excellent for joint-friendly cardio
- Works all major muscle groups
- 20-30 minutes, 3-4 times per week
- Consider water aerobics classes

### Cycling
- Stationary bike is safest option
- Start with 10-15 minutes
- Maintain a steady, moderate pace
- Great for improving circulation

### Strength Training
- Light weights or resistance bands
- Focus on major muscle groups
- 2-3 times per week
- Always warm up first

## Exercise Safety Tips
- Always warm up for 5-10 minutes
- Cool down after exercise
- Stay hydrated
- Listen to your body
- Stop if you feel pain or dizziness
- Consult your doctor before starting

**Start slow and gradually build up your routine!**''',
        duration: 10,
        createdAt: DateTime.now(),
      ),

      // Nutrition
      HealthContent(
        id: 'nutrition_healthy_eating',
        title: 'Healthy Eating for Seniors',
        description: 'Nutritional guidelines to maintain good health as you age.',
        type: ContentType.article,
        category: ContentCategory.nutrition,
        content: '''# Healthy Eating for Seniors

Proper nutrition is crucial for maintaining health, energy, and independence as you age.

## Essential Nutrients

### Protein
- Important for maintaining muscle mass
- Sources: lean meats, fish, eggs, beans, nuts
- Include protein in every meal
- Aim for 0.8-1g per kg of body weight

### Calcium and Vitamin D
- Critical for bone health
- Sources: dairy products, leafy greens, fortified foods
- Consider supplements if needed
- Get sunlight exposure for vitamin D

### Fiber
- Supports digestion and heart health
- Sources: whole grains, fruits, vegetables
- Aim for 25-30g daily
- Drink plenty of water with fiber intake

### B Vitamins
- Important for energy and brain function
- Sources: whole grains, lean meats, eggs
- B12 is especially important for seniors

## Healthy Eating Tips

### Meal Planning
- Plan meals ahead of time
- Include a variety of foods
- Prepare in batches for convenience
- Keep healthy snacks available

### Hydration
- Drink 6-8 glasses of water daily
- Limit sugary drinks
- Include herbal teas
- Eat water-rich foods like fruits

### Portion Control
- Use smaller plates
- Eat slowly and mindfully
- Stop when you feel satisfied
- Avoid eating large meals before bed

### Special Considerations
- Difficulty chewing: choose softer foods
- Reduced appetite: eat smaller, frequent meals
- Medication interactions: consult your pharmacist
- Budget concerns: focus on nutrient-dense foods

**Remember**: A balanced diet with variety is key to good health!''',
        duration: 12,
        createdAt: DateTime.now(),
      ),
      HealthContent(
        id: 'nutrition_meal_planning',
        title: 'Simple Meal Planning for Better Nutrition',
        description: 'Easy strategies to plan nutritious meals throughout the week.',
        type: ContentType.article,
        category: ContentCategory.nutrition,
        content: '''# Simple Meal Planning for Better Nutrition

Meal planning can help you eat healthier, save time, and reduce food waste.

## Benefits of Meal Planning
- Ensures balanced nutrition
- Saves time and reduces stress
- Helps with grocery shopping
- Reduces food waste
- Supports healthy eating habits

## Weekly Planning Strategy

### Step 1: Plan Your Meals
- Choose 2-3 breakfast options
- Plan 4-5 lunch ideas
- Create a dinner rotation
- Include healthy snacks

### Step 2: Make a Shopping List
- Organize by store sections
- Check what you already have
- Focus on fresh produce
- Don't shop when hungry

### Step 3: Prep Ahead
- Wash and cut vegetables
- Cook grains and proteins
- Prepare snacks in containers
- Store properly for freshness

## Easy Meal Ideas

### Breakfast
- Oatmeal with fruits and nuts
- Scrambled eggs with vegetables
- Whole grain toast with avocado
- Greek yogurt with berries

### Lunch
- Soup with whole grain bread
- Salad with lean protein
- Wraps with vegetables
- Leftovers from dinner

### Dinner
- Baked fish with vegetables
- Stir-fry with lean meat
- Pasta with vegetables and sauce
- Slow cooker meals

## Tips for Success
- Start small with 2-3 days of planning
- Keep it simple - use familiar recipes
- Prep on weekends for easier weekdays
- Have backup options for busy days
- Involve family or friends

**Meal planning doesn't have to be complicated - start simple!**''',
        duration: 10,
        createdAt: DateTime.now(),
      ),

      // Mental Health
      HealthContent(
        id: 'mental_stress',
        title: 'Managing Stress as You Age',
        description: 'Practical strategies to reduce stress and improve mental well-being.',
        type: ContentType.article,
        category: ContentCategory.mentalHealth,
        content: '''# Managing Stress as You Age

Stress management becomes increasingly important as we age. Here are effective strategies:

## Understanding Stress in Later Life

### Common Stressors
- Health concerns
- Financial worries
- Loss of loved ones
- Changes in routine
- Family responsibilities
- Social isolation

## Effective Stress Management Techniques

### 1. Physical Activity
- Regular exercise reduces stress hormones
- Walking, yoga, or tai chi
- Even 10 minutes can help
- Improves mood and sleep

### 2. Relaxation Techniques
- Deep breathing exercises
- Progressive muscle relaxation
- Meditation or mindfulness
- Guided imagery

### 3. Social Connection
- Stay connected with family and friends
- Join clubs or community groups
- Volunteer in your community
- Regular phone calls or visits

### 4. Hobbies and Interests
- Engage in activities you enjoy
- Learn something new
- Gardening, reading, or crafts
- Provides sense of purpose

### 5. Time Management
- Prioritize important tasks
- Break large tasks into smaller steps
- Learn to say no when needed
- Delegate when possible

### 6. Healthy Lifestyle
- Get adequate sleep
- Eat balanced meals
- Limit alcohol and caffeine
- Maintain regular routine

## When to Seek Help
- Persistent feelings of sadness or anxiety
- Difficulty sleeping
- Loss of interest in activities
- Changes in appetite
- Difficulty concentrating

**Don't hesitate to talk to your doctor or a mental health professional if stress becomes overwhelming.**''',
        duration: 10,
        createdAt: DateTime.now(),
      ),
      HealthContent(
        id: 'mental_social',
        title: 'Staying Socially Connected',
        description: 'The importance of social connections for mental and physical health.',
        type: ContentType.article,
        category: ContentCategory.mentalHealth,
        content: '''# Staying Socially Connected

Social connections are vital for both mental and physical health, especially as we age.

## Benefits of Social Connection

### Mental Health
- Reduces feelings of loneliness
- Improves mood and outlook
- Provides emotional support
- Enhances sense of purpose

### Physical Health
- Lower risk of depression
- Better immune function
- Reduced risk of cognitive decline
- Longer lifespan

## Ways to Stay Connected

### Family Connections
- Regular phone calls or video chats
- Family gatherings and celebrations
- Share meals together
- Participate in family activities

### Friends and Peers
- Meet for coffee or lunch
- Join walking groups
- Attend community events
- Play cards or games together

### Community Involvement
- Join local clubs or groups
- Volunteer for causes you care about
- Attend religious or spiritual gatherings
- Participate in community centers

### Technology
- Use video calling apps
- Join online communities
- Social media to stay in touch
- Online classes or groups

### New Activities
- Join a book club
- Take a class
- Participate in exercise groups
- Attend local events

## Overcoming Barriers

### Transportation
- Use public transit
- Arrange carpooling
- Request rides from family
- Use senior transportation services

### Mobility Issues
- Host gatherings at home
- Use video calls
- Join online communities
- Home visits from friends

### Hearing or Vision Loss
- Use assistive devices
- Choose quiet locations
- Face people when talking
- Communicate in writing

**Remember**: It's never too late to build new connections. Small steps can lead to meaningful relationships!''',
        duration: 10,
        createdAt: DateTime.now(),
      ),

      // Sleep
      HealthContent(
        id: 'sleep_basics',
        title: 'Quality Sleep for Better Health',
        description: 'Tips to improve sleep quality and establish healthy sleep habits.',
        type: ContentType.article,
        category: ContentCategory.sleep,
        content: '''# Quality Sleep for Better Health

Good sleep is essential for physical and mental health. Here's how to improve your sleep quality:

## Why Sleep Matters

### Health Benefits
- Supports immune function
- Improves memory and concentration
- Reduces risk of chronic diseases
- Enhances mood and emotional well-being
- Helps with weight management

## Sleep Requirements for Seniors
- Most seniors need 7-9 hours of sleep
- Sleep patterns may change with age
- Waking up during the night is normal
- Focus on total sleep quality, not just duration

## Tips for Better Sleep

### 1. Establish a Routine
- Go to bed and wake up at the same time
- Create a relaxing bedtime ritual
- Avoid naps after 3 PM
- Keep weekends consistent

### 2. Create a Sleep-Friendly Environment
- Keep bedroom cool (65-68°F)
- Ensure darkness with curtains
- Reduce noise or use white noise
- Comfortable mattress and pillows

### 3. Limit Evening Activities
- Avoid large meals before bed
- Limit fluids 2 hours before sleep
- Avoid caffeine after noon
- Limit alcohol before bed

### 4. Daytime Habits
- Get morning sunlight exposure
- Regular exercise (not too close to bedtime)
- Stay active during the day
- Limit daytime naps

### 5. Relaxation Techniques
- Reading before bed
- Gentle stretching
- Deep breathing exercises
- Meditation or mindfulness

## Common Sleep Issues

### Insomnia
- Difficulty falling or staying asleep
- May be related to stress or health conditions
- Talk to your doctor if persistent
- Consider cognitive behavioral therapy

### Sleep Apnea
- Pauses in breathing during sleep
- Snoring loudly
- Waking up gasping
- Requires medical evaluation

### Restless Legs
- Uncomfortable sensations in legs
- Strong urge to move legs
- May be related to medications
- Discuss with healthcare provider

## When to See a Doctor
- Persistent sleep problems
- Excessive daytime sleepiness
- Loud snoring with pauses
- Sleep-related concerns affecting daily life

**Good sleep is a foundation for good health - prioritize it!**''',
        duration: 12,
        createdAt: DateTime.now(),
      ),

      // Exercise
      HealthContent(
        id: 'exercise_safety',
        title: 'Safe Exercise for Seniors',
        description: 'Guidelines for safe and effective exercise routines.',
        type: ContentType.article,
        category: ContentCategory.exercise,
        content: '''# Safe Exercise for Seniors

Regular exercise is one of the best things you can do for your health. Here's how to exercise safely:

## Benefits of Regular Exercise
- Improves strength and balance
- Reduces risk of falls
- Enhances mood and energy
- Supports heart health
- Helps maintain independence

## Types of Exercise

### Aerobic Exercise
- Walking, swimming, cycling
- 150 minutes per week recommended
- Can be done in 10-minute sessions
- Moderate intensity - able to talk while exercising

### Strength Training
- Light weights or resistance bands
- 2-3 times per week
- Focus on major muscle groups
- Prevents muscle loss

### Balance Exercises
- Standing on one foot
- Heel-to-toe walking
- Tai chi or yoga
- Crucial for fall prevention

### Flexibility
- Stretching exercises
- Improves range of motion
- Reduces stiffness
- Can be done daily

## Safety Guidelines

### Before Starting
- Consult your doctor
- Start slowly and gradually increase
- Choose appropriate activities
- Warm up before exercise

### During Exercise
- Listen to your body
- Stop if you feel pain
- Stay hydrated
- Use proper form

### Warning Signs to Stop
- Chest pain or pressure
- Severe shortness of breath
- Dizziness or lightheadedness
- Nausea
- Pain in joints or muscles

### After Exercise
- Cool down properly
- Stretch gently
- Rest and recover
- Stay hydrated

## Exercise Modifications

### For Joint Problems
- Low-impact activities
- Swimming or water aerobics
- Cycling instead of walking
- Consult physical therapist

### For Balance Issues
- Chair-based exercises
- Hold onto support
- Exercise with supervision
- Focus on balance training

### For Limited Mobility
- Chair exercises
- Arm exercises
- Range of motion exercises
- Work with a physical therapist

## Building a Routine
- Start with 10-15 minutes
- Gradually increase duration
- Mix different types of exercise
- Find activities you enjoy
- Exercise with friends for motivation

**Remember**: Any amount of physical activity is better than none. Start where you are and progress gradually!''',
        duration: 12,
        createdAt: DateTime.now(),
      ),

      // General Health
      HealthContent(
        id: 'general_wellness',
        title: 'Overall Wellness Tips for Seniors',
        description: 'Comprehensive guide to maintaining health and wellness.',
        type: ContentType.article,
        category: ContentCategory.general,
        content: '''# Overall Wellness Tips for Seniors

Maintaining overall wellness involves multiple aspects of health. Here's a comprehensive guide:

## Key Areas of Wellness

### Physical Health
- Regular medical check-ups
- Preventive screenings
- Medication management
- Staying physically active
- Eating nutritious foods

### Mental Health
- Stay socially connected
- Engage in mental activities
- Manage stress effectively
- Seek help when needed
- Maintain purpose and meaning

### Emotional Health
- Express feelings appropriately
- Practice gratitude
- Maintain relationships
- Find joy in daily activities
- Accept change gracefully

## Preventive Care

### Regular Screenings
- Blood pressure checks
- Cholesterol monitoring
- Diabetes screening
- Vision and hearing exams
- Cancer screenings as recommended

### Vaccinations
- Annual flu vaccine
- COVID-19 vaccines
- Pneumonia vaccine
- Shingles vaccine
- Tetanus booster

### Dental Care
- Regular dental check-ups
- Daily brushing and flossing
- Address dental issues promptly
- Consider denture care if needed

## Health Monitoring

### Know Your Numbers
- Blood pressure
- Cholesterol levels
- Blood sugar
- Weight
- Body mass index (BMI)

### Medication Management
- Take medications as prescribed
- Keep an updated medication list
- Use a pill organizer
- Review medications with doctor
- Be aware of side effects

## Healthy Habits

### Daily Routines
- Consistent sleep schedule
- Regular meal times
- Daily physical activity
- Time for relaxation
- Social interaction

### Safety
- Home safety modifications
- Regular eye exams
- Proper footwear
- Remove fall hazards
- Emergency contacts available

## When to Seek Medical Attention
- Persistent symptoms
- Sudden changes in health
- Unexplained weight loss
- Changes in mental state
- Severe pain or discomfort

**Remember**: Prevention and early intervention are key to maintaining health and independence!''',
        duration: 12,
        createdAt: DateTime.now(),
      ),
    ];
  }
}


