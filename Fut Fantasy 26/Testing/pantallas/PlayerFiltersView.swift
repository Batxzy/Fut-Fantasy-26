//
//  PlayerFiltersView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//


import SwiftUI

struct PlayerFiltersView: View {
    @Binding var selectedPosition: PlayerPosition?
    @Binding var selectedNation: Nation?
    @Binding var maxPrice: Double?
    @Binding var sortType: PlayerSortType
    
    let onApply: () -> Void
    let onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    Picker("Position", selection: $selectedPosition) {
                        Text("All").tag(nil as PlayerPosition?)
                        ForEach([PlayerPosition.goalkeeper, .defender, .midfielder, .forward], id: \.self) { position in
                            Text(position.rawValue).tag(position as PlayerPosition?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Nation") {
                    Picker("Nation", selection: $selectedNation) {
                        Text("All Nations").tag(nil as Nation?)
                        ForEach([Nation.argentina, .brazil, .england, .france, .germany, .spain, .portugal], id: \.self) { nation in
                            Text(nation.rawValue).tag(nation as Nation?)
                        }
                    }
                }
                
                Section("Price") {
                    Toggle("Set Max Price", isOn: Binding(
                        get: { maxPrice != nil },
                        set: { if !$0 { maxPrice = nil } else { maxPrice = 10.0 } }
                    ))
                    
                    if maxPrice != nil {
                        HStack {
                            Text("Max:")
                            Slider(value: Binding(
                                get: { maxPrice ?? 10.0 },
                                set: { maxPrice = $0 }
                            ), in: 4.0...15.0, step: 0.5)
                            Text("$\(String(format: "%.1f", maxPrice ?? 10.0))M")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Sort By") {
                    Picker("Sort", selection: $sortType) {
                        Text("Points").tag(PlayerSortType.points)
                        Text("Price").tag(PlayerSortType.price)
                        Text("Value").tag(PlayerSortType.value)
                        Text("Form").tag(PlayerSortType.form)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Reset") {
                        onReset()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PlayerFiltersView(
        selectedPosition: .constant(nil),
        selectedNation: .constant(nil),
        maxPrice: .constant(nil),
        sortType: .constant(.points),
        onApply: { print("Apply tapped") },
        onReset: { print("Reset tapped") }
    )
}
