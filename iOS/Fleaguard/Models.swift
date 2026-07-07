import Foundation

struct TreatmentEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var productName: String
    var date: Date
    var durationDays: Int
    var createdAt: Date = Date()
}
