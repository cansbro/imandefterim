import SwiftUI

struct FolderSelectionSheet: View {
    @EnvironmentObject var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    let note: FirestoreNote

    var body: some View {
        NavigationStack {
            VStack {
                if notesService.folders.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "Klasör Yok",
                        message: "Henüz hiç klasör oluşturmadınız."
                    )
                } else {
                    List {
                        // "Klasörden Çıkar" option if note is already in a folder
                        if note.folderId != nil {
                            Button {
                                moveNote(to: nil)
                            } label: {
                                HStack {
                                    Image(systemName: "folder.badge.minus")
                                        .foregroundColor(.red)
                                    Text("Klasörden Çıkar")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        ForEach(notesService.folders) { folder in
                            Button {
                                moveNote(to: folder.id)
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.islamicGold)
                                    Text(folder.name)
                                        .foregroundColor(.islamicTextPrimary)

                                    Spacer()

                                    if note.folderId == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.islamicGreen)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Klasöre Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func moveNote(to folderId: String?) {
        Task {
            // Optimistic update handled in service? Note quite, but UI will update when service returns.
            // For move, we typically wait or could do optimistic too.
            // Given the user wants "speed", let's rely on standard async for now but we could improve later.
            // Actually, let's just do it.

            if let noteId = note.id {
                try? await notesService.moveNoteToFolder(noteId: noteId, folderId: folderId)
            }
            dismiss()
        }
    }
}
