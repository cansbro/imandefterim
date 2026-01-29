import SwiftUI

// MARK: - Notes View
struct NotesView: View {
    @EnvironmentObject var notesService: NotesService
    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var showNewFolderSheet = false
    @State private var selectedNote: FirestoreNote?
    @State private var noteToMove: FirestoreNote?
    @State private var selectedFolder: FirestoreFolder?

    private let segments = [Strings.Notes.all, Strings.Notes.folders]

    private var filteredNotes: [FirestoreNote] {
        if searchText.isEmpty {
            return notesService.notes
        }
        return notesService.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header (Always visible)
                CustomNavigationHeader(title: Strings.Notes.title)

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.islamicWarmGray)
                            TextField(Strings.Notes.search, text: $searchText)
                                .font(AppFont.bodyText)
                                .foregroundColor(.islamicTextPrimary)
                        }
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.islamicLightGray)
                        )
                        .padding(.horizontal, Spacing.md)

                        // Premium Banner
                        PremiumBanner()
                            .padding(.horizontal, Spacing.md)

                        // Segment Control
                        SegmentControl(options: segments, selectedIndex: $selectedSegment)
                            .padding(.horizontal, Spacing.md)

                        // Content based on segment
                        if selectedSegment == 0 {
                            allNotesSection
                        } else {
                            foldersSection
                        }
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.islamicBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            notesService.startListening()
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note)
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewFolderSheet()
        }
        .sheet(item: $selectedFolder) { folder in
            FolderDetailView(folder: folder)
        }
        .sheet(item: $noteToMove) { note in
            FolderSelectionSheet(note: note)
        }
    }

    // MARK: - All Notes Section
    private var allNotesSection: some View {
        VStack(spacing: Spacing.md) {
            if filteredNotes.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: Strings.Notes.emptyTitle,
                    message: Strings.Notes.emptyMessage
                )
                .padding(.top, Spacing.xxxl)
            } else {
                ForEach(filteredNotes) { note in
                    FirestoreNoteCard(note: note)
                        .onTapGesture {
                            selectedNote = note
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task {
                                    try? await notesService.deleteNote(noteId: note.id ?? "")
                                }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }

                            Button {
                                noteToMove = note
                            } label: {
                                Label("Klasöre Ekle", systemImage: "folder.badge.plus")
                            }
                        }

                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Folders Section
    private var foldersSection: some View {
        VStack(spacing: Spacing.md) {
            if notesService.folders.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: Strings.Notes.emptyFolderTitle,
                    message: Strings.Notes.emptyMessage,
                    actionTitle: Strings.Notes.createFolder
                ) {
                    showNewFolderSheet = true
                }
                .padding(.top, Spacing.xxxl)
            } else {
                // Add folder button
                Button(action: { showNewFolderSheet = true }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 20))
                        Text(Strings.Notes.newFolder)
                            .font(AppFont.bodyMedium(15))
                    }
                    .foregroundColor(.islamicGold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Color.islamicGold.opacity(0.05))
                            )
                    )
                }

                ForEach(notesService.folders) { folder in
                    FirestoreFolderCard(
                        folder: folder, noteCount: notesService.notes(for: folder.id ?? "").count
                    )
                    .onTapGesture {
                        selectedFolder = folder
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                try? await notesService.deleteFolder(folderId: folder.id ?? "")
                            }
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Firestore Note Card
struct FirestoreNoteCard: View {
    let note: FirestoreNote

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header: Title + Date
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.xs) {
                            // Status indicator
                            if note.status == .processing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else if note.status == .failed {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }

                            Text(note.title)
                                .font(AppFont.headline)
                                .foregroundColor(.islamicBrown)
                                .lineLimit(2)
                        }

                        Text(note.formattedDate)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicTextSecondary)
                    }

                    Spacer()

                    // Duration badge
                    if note.durationSec != nil {
                        Text(note.formattedDuration)
                            .font(AppFont.caption)
                            .foregroundColor(.islamicGold)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(
                                Capsule()
                                    .fill(Color.islamicGold.opacity(0.1))
                            )
                    }
                }

                // Type icon
                HStack(spacing: Spacing.xs) {
                    Image(systemName: note.type.icon)
                        .font(.system(size: 12))
                    Text(note.type.displayName)
                        .font(AppFont.caption)
                }
                .foregroundColor(.islamicTextTertiary)

                // Tags
                if !note.tags.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(note.tags, id: \.self) { tag in
                            TagChip(tag)
                        }
                    }
                }

                // Speaker if available
                if let speaker = note.speaker, !speaker.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                        Text(speaker)
                            .font(AppFont.caption)
                    }
                    .foregroundColor(.islamicTextTertiary)
                }
            }
        }
    }
}

// MARK: - Firestore Folder Card
struct FirestoreFolderCard: View {
    let folder: FirestoreFolder
    let noteCount: Int

    var body: some View {
        AppCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.islamicGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(AppFont.headline)
                        .foregroundColor(.islamicBrown)

                    Text("\(noteCount) not")
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.islamicWarmGray)
            }
        }
    }
}

// MARK: - New Folder Sheet
struct NewFolderSheet: View {
    @EnvironmentObject var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                TextField(Strings.Notes.folderName, text: $folderName)
                    .font(AppFont.bodyText)
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.islamicLightGray)
                    )
                    .foregroundColor(.islamicBrown)
                    .colorScheme(.light)

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle(Strings.Notes.newFolder)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Notes.create) {
                        createFolder()
                    }
                    .disabled(folderName.isEmpty || isLoading)
                }
            }
        }
    }

    private func createFolder() {
        isLoading = true
        Task {
            do {
                _ = try await notesService.createFolder(name: folderName)
                dismiss()
            } catch {
                print("Folder creation error: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Folder Detail View
struct FolderDetailView: View {
    let folder: FirestoreFolder
    @EnvironmentObject var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNote: FirestoreNote?

    private var folderNotes: [FirestoreNote] {
        notesService.notes(for: folder.id ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if folderNotes.isEmpty {
                        EmptyStateView(
                            icon: "doc.text",
                            title: "Klasör Boş",
                            message: "Bu klasörde henüz not yok"
                        )
                        .padding(.top, Spacing.xxxl)
                    } else {
                        ForEach(folderNotes) { note in
                            FirestoreNoteCard(note: note)
                                .onTapGesture {
                                    selectedNote = note
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task {
                                            try? await notesService.deleteNote(
                                                noteId: note.id ?? "")
                                        }
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }

                                    Button {
                                        Task {
                                            try? await notesService.moveNoteToFolder(
                                                noteId: note.id ?? "", folderId: nil)
                                        }
                                    } label: {
                                        Label("Klasörden Çıkar", systemImage: "folder.badge.minus")
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 100)
            }
            .background(Color.islamicBackground)
            .navigationTitle(folder.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.islamicBrown)
                    }
                }
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }
}

#Preview {
    NotesView()
        .environmentObject(NotesService.shared)
}
