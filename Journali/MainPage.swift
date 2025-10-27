//
//  Untitled 3.swift
//  Journali
//
//  Created by Raghad Alamoudi on 04/05/1447 AH.
//


import SwiftUI

// نموذج اليومية
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let body: String
    let date: Date
    var bookmarked: Bool = false
}

struct MainPage: View {
    @FocusState private var titleFieldFocused: Bool
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: Date())
    }

    @AppStorage("journalEntriesData") private var journalEntriesData: Data = Data()
    @State private var entries: [JournalEntry] = []
    @State private var showingComposer = false
    @State private var composeTitle: String = ""
    @State private var composeBody: String = ""
    @State private var sortNewestFirst: Bool = true
    @State private var searchText: String = ""
    @State private var selectedEntryID: UUID? = nil
    @State private var showDeleteAlert = false
    @State private var entryToDelete: JournalEntry? = nil
    @State private var startApp = false
    @State private var sortByBookmark: Bool = false

    // discard modal state + nav bar frame for positioning
    @State private var showDiscardAlert: Bool = false
    @State private var navBarFrame: CGRect = .zero

    private let journalTitlePurple = Color(red: 0.76, green: 0.68, blue: 0.90)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                // رأس الصفحة
                HStack {
                    Text("Journal")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 14) {
                        Menu {
                            Button(action: {
                                sortByBookmark = true
                            }) {
                                Label("Sort by Bookmark", systemImage: sortByBookmark ? "checkmark" : "")
                            }

                            Button(action: {
                                sortByBookmark = false
                            }) {
                                Label("Sort by Entry Date", systemImage: !sortByBookmark ? "checkmark" : "")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            composeTitle = ""
                            composeBody = ""
                            showingComposer = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal)

                // محتوى الصفحة / بطاقات اليوميات
                if entries.isEmpty {
                    Spacer()

                    Image("Book")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)

                    VStack(spacing: 8) {
                        Text("Begin Your Journal")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(journalTitlePurple)

                        Text("Craft your personal diary, tap the plus icon to begin")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 59)
                    }

                    Spacer()
                } else {
                    List {
                        ForEach(filteredEntries()) { entry in
                            LargeJournalCard(
                                entry: entry,
                                titleColor: journalTitlePurple,
                                isSelected: entry.id == selectedEntryID,
                                onTap: {
                                    withAnimation(.spring()) {
                                        selectedEntryID = (selectedEntryID == entry.id) ? nil : entry.id
                                    }
                                },
                                onToggleBookmark: { toggleBookmark(entryID: entry.id) }
                            )
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        entryToDelete = entry
                                        showDeleteAlert = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Spacer()

                // شريط البحث
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))

                    TextField("Search your entries...", text: $searchText)
                        .foregroundColor(.white)
                        .disableAutocorrection(true)

                    Spacer()

                    Image(systemName: "mic.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.gray.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadEntries()
            sortEntries()
        }
        .sheet(isPresented: $showingComposer) {
            composerView
        }
        // Delete modal overlay — color dark-gray and left-aligned text
        .overlay {
            if showDeleteAlert, let entry = entryToDelete {
                // dim background
                Color.black.opacity(0.35).ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut) { showDeleteAlert = false }
                    }

                // Modal box with dark-gray background and left-aligned title/message
                VStack(alignment: .leading, spacing: 16) {
                    // Title (left)
                    Text("Delete Journal?")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(white: 0.96))
                        .padding(.top, 14)
                        .padding(.horizontal, 20)

                    // Message (left)
                    Text("Are you sure you want to delete this journal?")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color(white: 0.87))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                        .fixedSize(horizontal: false, vertical: true)

                    // Buttons row
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.easeOut) { showDeleteAlert = false }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(white: 0.92)) // light gray button bg
                                .cornerRadius(16)
                        }

                        Button(action: {
                            deleteEntry(entry)
                            withAnimation(.easeOut) {
                                showDeleteAlert = false
                                entryToDelete = nil
                            }
                        }) {
                            Text("Delete")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.86, green: 0.22, blue: 0.22))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                }
                .frame(maxWidth: 360)
                .background(
                    // dark-gray (not pure black)
                    Color(red: 0.12, green: 0.12, blue: 0.13)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 22, x: 0, y: 12)
                .padding(.horizontal, 16)
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }
        }
    }

    // Composer view with gray background and cleaned discard modal (no black caret/arrow)
    private var composerView: some View {
        ZStack(alignment: .topLeading) {
            NavigationView {
                VStack(spacing: 12) {
                    TextField("Title", text: $composeTitle)
                        .font(.system(size: 30, weight: .semibold))
                        .padding(.leading, 9)
                        .foregroundColor(.white)
                        .accentColor(Color.purple.opacity(0.7))
                        .focused($titleFieldFocused)

                    Text(formattedDate)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 9)

                    TextField("Type your Journal...", text: $composeBody)
                        .font(.system(size: 20, design: .rounded))
                        .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 25)
                .onAppear { titleFieldFocused = true }
                .background(Color.gray.opacity(0.12).ignoresSafeArea())
                .background(
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            navBarFrame = CGRect(x: 8, y: 0, width: 64, height: 44)
                        }
                        return Color.clear
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            let titleChanged = !composeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            let bodyChanged = !composeBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            if titleChanged || bodyChanged {
                                withAnimation(.spring()) {
                                    showDiscardAlert = true
                                }
                            } else {
                                showingComposer = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            addEntry(title: composeTitle, body: composeBody)
                            showingComposer = false
                        }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                        .disabled(
                            composeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                            composeBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())

            // Custom discard modal: dark translucent, rounded, no caret/arrow
            if showDiscardAlert {
                VStack(spacing: 14) {
                    VStack(spacing: 14) {
                        Text("Are you sure you want to discard your changes?")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(white: 0.95))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 14)

                        VStack(spacing: 8) {
                            Button(action: {
                                composeTitle = ""
                                composeBody = ""
                                showingComposer = false
                                withAnimation(.easeOut) { showDiscardAlert = false }
                            }) {
                                Text("Discard Changes")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }

                            Button(action: {
                                withAnimation(.easeOut) { showDiscardAlert = false }
                            }) {
                                Text("Keep Editing")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color(white: 0.85))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    .background(Color.black.opacity(0.78))
                    .cornerRadius(24) // softer roundness
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                    .frame(maxWidth: 320)
                }
                .padding(.top, max(navBarFrame.minY + 10, 10))
                .padding(.leading, 12)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
    }

    // MARK: - Helpers
    private func filteredEntries() -> [JournalEntry] {
        var list = entries
        if sortByBookmark {
            list = list.filter { $0.bookmarked }
        }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q) }
        }
        return list
    }

    private func sortEntries() {
        entries.sort { sortNewestFirst ? $0.date > $1.date : $0.date < $1.date }
    }

    private func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    private func addEntry(title: String, body: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle
        entries.append(JournalEntry(id: UUID(), title: finalTitle, body: body, date: Date()))
        sortEntries()
        saveEntries()
    }

    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            journalEntriesData = encoded
        }
    }

    private func loadEntries() {
        if let decoded = try? JSONDecoder().decode([JournalEntry].self, from: journalEntriesData) {
            entries = decoded
        } else {
            entries = [
                JournalEntry(id: UUID(), title: "My Birthday", body: "Lorem ipsum...", date: Date()),
                JournalEntry(id: UUID(), title: "Today's Journal", body: "Lorem ipsum...", date: Date().addingTimeInterval(-86400))
            ]
            saveEntries()
        }
    }

    private func toggleBookmark(entryID: UUID) {
        if let i = entries.firstIndex(where: { $0.id == entryID }) {
            entries[i].bookmarked.toggle()
            saveEntries()
        }
    }
}

// Small blur wrapper so background of modal matches system materials
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    MainPage()
}
