import Foundation
import Combine
import HealthKit

// MARK: - 健康数据服务
class HealthDataService: ObservableObject {
    static let shared = HealthDataService()
    
    private init() {}
    
    // MARK: - HealthKit授权
    private let healthStore = HKHealthStore()
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws -> Bool {
        guard isHealthKitAvailable else { return false }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        return true
    }
    
    // MARK: - 获取今日步数
    func fetchTodaySteps() async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthDataError.typeNotAvailable
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取今日饮水量
    func fetchTodayWater() async throws -> Int {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthDataError.typeNotAvailable
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let water = statistics?.sumQuantity()?.doubleValue(for: .literUnit(with: .milli)) ?? 0
                continuation.resume(returning: Int(water))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取心率
    func fetchLatestHeartRate() async throws -> Int? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthDataError.typeNotAvailable
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: Int(heartRate))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取今日睡眠
    func fetchTodaySleep() async throws -> Int {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthDataError.typeNotAvailable
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay.addingTimeInterval(-86400), end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var totalSleepMinutes = 0
                for sample in samples ?? [] {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60
                    totalSleepMinutes += Int(duration)
                }
                
                continuation.resume(returning: totalSleepMinutes)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取周趋势数据
    func fetchWeeklySteps() async throws -> [StepDataPoint] {
        var weeklyData: [StepDataPoint] = []
        
        for i in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            
            guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
                continue
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            
            let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, _ in
                    let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: Int(steps))
                }
                healthStore.execute(query)
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayName = formatter.string(from: date)
            
            weeklyData.append(StepDataPoint(day: dayName, value: steps))
        }
        
        return weeklyData
    }
    
    // MARK: - 获取今日卡路里
    func fetchTodayCalories() async throws -> Int {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthDataError.typeNotAvailable
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error = error { continuation.resume(throwing: error); return }
                let cal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: Int(cal))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取体重
    func fetchLatestBodyMass() async throws -> Double? {
        guard let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthDataError.typeNotAvailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: massType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error { continuation.resume(throwing: error); return }
                guard let sample = samples?.first as? HKQuantitySample else { continuation.resume(returning: nil); return }
                continuation.resume(returning: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取身高
    func fetchLatestHeight() async throws -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            throw HealthDataError.typeNotAvailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error { continuation.resume(throwing: error); return }
                guard let sample = samples?.first as? HKQuantitySample else { continuation.resume(returning: nil); return }
                continuation.resume(returning: sample.quantity.doubleValue(for: .meterUnit(with: .centi)))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - 获取周饮水趋势
    func fetchWeeklyWater() async throws -> [WaterDataPoint] {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return (0..<7).reversed().map { i in
                let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                let formatter = DateFormatter(); formatter.dateFormat = "E"
                return WaterDataPoint(day: formatter.string(from: date), value: 0)
            }
        }
        var result: [WaterDataPoint] = []
        for i in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let water = try await withCheckedThrowingContinuation { (c: CheckedContinuation<Int, Error>) in
                let q = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                    c.resume(returning: Int(stats?.sumQuantity()?.doubleValue(for: .literUnit(with: .milli)) ?? 0))
                }
                healthStore.execute(q)
            }
            let formatter = DateFormatter(); formatter.dateFormat = "E"
            result.append(WaterDataPoint(day: formatter.string(from: date), value: water))
        }
        return result
    }
    
    // MARK: - 获取周睡眠趋势
    func fetchWeeklySleep() async throws -> [SleepDataPoint] {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0..<7).reversed().map { i in
                let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                let formatter = DateFormatter(); formatter.dateFormat = "E"
                return SleepDataPoint(day: formatter.string(from: date), value: 0)
            }
        }
        var result: [SleepDataPoint] = []
        for i in (0..<7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start.addingTimeInterval(-86400), end: end, options: .strictStartDate)
            let minutes = try await withCheckedThrowingContinuation { (c: CheckedContinuation<Int, Error>) in
                let q = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                    var total = 0
                    for s in samples ?? [] { total += Int(s.endDate.timeIntervalSince(s.startDate) / 60) }
                    c.resume(returning: total)
                }
                healthStore.execute(q)
            }
            let formatter = DateFormatter(); formatter.dateFormat = "E"
            result.append(SleepDataPoint(day: formatter.string(from: date), value: minutes))
        }
        return result
    }
    
    // MARK: - 统一同步到DataManager
    @MainActor
    func syncAllToDataManager() async {
        let dm = DataManager.shared
        do {
            dm.dailySteps = try await fetchTodaySteps()
        } catch { print("Steps sync failed: \(error)") }
        do {
            dm.waterIntakeMl = try await fetchTodayWater()
        } catch { print("Water sync failed: \(error)") }
        do {
            dm.caloriesBurned = try await fetchTodayCalories()
        } catch { print("Calories sync failed: \(error)") }
        do {
            dm.sleepMinutes = try await fetchTodaySleep()
        } catch { print("Sleep sync failed: \(error)") }
        do {
            if let hr = try await fetchLatestHeartRate() { dm.heartRateAvg = hr }
        } catch { print("HeartRate sync failed: \(error)") }
        do {
            if let weight = try await fetchLatestBodyMass() { dm.weightKg = Float(weight) }
        } catch { print("BodyMass sync failed: \(error)") }
        do {
            if let height = try await fetchLatestHeight() { dm.heightCm = Float(height) }
        } catch { print("Height sync failed: \(error)") }
        do {
            dm.weeklyStepData = try await fetchWeeklySteps()
        } catch { print("WeeklySteps sync failed: \(error)") }
        do {
            dm.weeklyWaterData = try await fetchWeeklyWater()
        } catch { print("WeeklyWater sync failed: \(error)") }
        do {
            dm.weeklySleepData = try await fetchWeeklySleep()
        } catch { print("WeeklySleep sync failed: \(error)") }
    }
    
    // MARK: - 实时步数观察
    func startStepObserver() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, _ in
            Task {
                if let steps = try? await self?.fetchTodaySteps() {
                    await MainActor.run { DataManager.shared.dailySteps = steps }
                }
                completionHandler()
            }
        }
        healthStore.execute(query)
    }
    
    private var sortDescriptor: NSSortDescriptor {
        NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    }
}

// MARK: - 健康数据错误
enum HealthDataError: Error, LocalizedError {
    case typeNotAvailable
    case notAuthorized
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .typeNotAvailable: return "数据类型不可用"
        case .notAuthorized: return "未授权访问健康数据"
        case .queryFailed: return "查询健康数据失败"
        }
    }
}
