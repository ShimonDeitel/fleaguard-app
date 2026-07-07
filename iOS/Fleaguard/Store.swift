import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    static let freeLimit = 8 // seed data has 3 entries; keep this above that

    @Published var entries: [TreatmentEntry] = []
    @Published var isPro: Bool = false

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("fleaguard_entries.json")
        load()
    }

    var canAddMore: Bool {
        isPro || entries.count < Store.freeLimit
    }

    func add(_ entry: TreatmentEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func update(_ entry: TreatmentEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func delete(_ entry: TreatmentEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([TreatmentEntry].self, from: data) {
            entries = decoded
        } else {
            entries = [
        TreatmentEntry(productName: "Sample 1", date: Date().addingTimeInterval(-604800), durationDays: 1),
        TreatmentEntry(productName: "Sample 2", date: Date().addingTimeInterval(-1209600), durationDays: 2),
        TreatmentEntry(productName: "Sample 3", date: Date().addingTimeInterval(-1814400), durationDays: 3)
            ]
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }
}
