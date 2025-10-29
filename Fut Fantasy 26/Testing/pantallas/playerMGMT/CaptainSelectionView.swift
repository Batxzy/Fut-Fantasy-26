//
//  CaptainSelectionView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI

struct CaptainSelectionView: View {
    let squad: Squad
    let onCaptainSelected: (Player) -> Void
    let onViceCaptainSelected: (Player) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Select Team Captain")) {
                    ForEach(squad.startingXI ?? [], id: \.id) { player in
                        Button {
                            onCaptainSelected(player)
                            dismiss()
                        } label: {
                            HStack {
                                PlayerRowView(player: player)
                                Spacer()
                                
                                if squad.captain?.id == player.id {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                } else if squad.viceCaptain?.id == player.id {
                                    Text("V")
                                        .font(.caption)
                                        .padding(4)
                                        .background(Circle().fill(.purple))
                                        .foregroundStyle(.white)
                                } else {
                                    Image(systemName: "star")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Select Vice Captain")) {
                    ForEach(squad.startingXI ?? [], id: \.id) { player in
                        if squad.captain?.id != player.id {
                            Button {
                                onViceCaptainSelected(player)
                                dismiss()
                            } label: {
                                HStack {
                                    PlayerRowView(player: player)
                                    Spacer()
                                    
                                    if squad.viceCaptain?.id == player.id {
                                        Text("V")
                                            .font(.caption)
                                            .padding(4)
                                            .background(Circle().fill(.purple))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("V")
                                            .font(.caption)
                                            .padding(4)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Text("The captain scores double points. If your captain doesn't play, your vice captain will score double points instead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Team Leadership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let squad = MockData.squad
    
    return CaptainSelectionView(
        squad: squad,
        onCaptainSelected: { player in print("Captain selected: \(player.name)") },
        onViceCaptainSelected: { player in print("Vice-captain selected: \(player.name)") }
    )
}
