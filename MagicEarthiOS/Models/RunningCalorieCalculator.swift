import Foundation

/**
 * High-precision Running & Jogging Calorie Calculator.
 * Based on ACSM (American College of Sports Medicine) metabolic calculation:
 * Gross Calories = Distance (km) * Body Weight (kg) * 1.036
 */
enum RunningCalorieCalculator {
    private static let weightKey = "magic_earth_runner_weight_kg"
    static let defaultWeightKg: Double = 65.0
    
    static func getUserWeight() -> Double {
        let stored = UserDefaults.standard.double(forKey: weightKey)
        return stored > 30.0 ? stored : defaultWeightKg
    }
    
    static func setUserWeight(_ weightKg: Double) {
        let clamped = max(30.0, min(200.0, weightKg))
        UserDefaults.standard.set(clamped, forKey: weightKey)
    }
    
    static func calculateCalories(distanceKm: Double, weightKg: Double? = nil) -> Int {
        if distanceKm <= 0.01 { return 0 }
        let weight = weightKg ?? getUserWeight()
        let calories = distanceKm * weight * 1.036
        return Int(calories.rounded())
    }
    
    static func estimateDurationMinutes(distanceKm: Double, paceMinPerKm: Double = 6.0) -> Int {
        if distanceKm <= 0.02 { return 0 }
        return max(1, Int((distanceKm * paceMinPerKm).rounded()))
    }
}
