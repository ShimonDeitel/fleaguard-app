import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var purchases: PurchaseManager
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var editingEntry: TreatmentEntry?

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    ContentUnavailableView("No entries yet", systemImage: "pawprint.fill", description: Text("Tap + to log your first entry."))
                } else {
                    List {
                        ForEach(store.entries) { entry in
                            Button {
                                editingEntry = entry
                            } label: {
                                HStack {
                                    Text(entry.productName)
                                        .font(Theme.headlineFont)
                                    Spacer()
                                    Text(entry.date, style: .date)
                                        .foregroundStyle(Theme.accent)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("entryRow_\(entry.id.uuidString)")
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Fleaguard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddMore {
                            showingAdd = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addButton")
                }
            }
            .sheet(isPresented: $showingAdd) {
                EntryFormView(mode: .add)
                    .environmentObject(store)
            }
            .sheet(item: $editingEntry) { entry in
                EntryFormView(mode: .edit(entry))
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(purchases)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environmentObject(purchases)
            }
        }
    }
}

enum FormMode: Equatable {
    case add
    case edit(TreatmentEntry)
}

struct EntryFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    let mode: FormMode

    @State private var draftProductName: String = ""
    @State private var draftDate: Date = Date()
    @State private var draftDurationDays: Int = 0

    init(mode: FormMode) {
        self.mode = mode
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Productname", text: $draftProductName)
                        .accessibilityIdentifier("field_productName")
                    DatePicker("Date", selection: $draftDate, displayedComponents: .date)
                    Stepper("Durationdays: \(draftDurationDays)", value: $draftDurationDays, in: 0...365)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .accessibilityIdentifier("saveButton")
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func populateIfEditing() {
        if case .edit(let entry) = mode {
            draftProductName = entry.productName
            draftDate = entry.date
            draftDurationDays = entry.durationDays
        }
    }

    private func save() {
        switch mode {
        case .add:
            let entry = TreatmentEntry(productName: draftProductName, date: draftDate, durationDays: draftDurationDays)
            store.add(entry)
        case .edit(var entry):
            entry.productName = draftProductName
            entry.date = draftDate
            entry.durationDays = draftDurationDays
            store.update(entry)
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
