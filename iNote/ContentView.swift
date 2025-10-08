//
//  ContentView.swift
//  iNote
//
//  Created by Kosuke Shigematsu on 10/1/25.
//

import SwiftUI
import PencilKit
import Vision
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var noteBookManager = NoteBookManager()
    @State private var showingSideMenu = false
    @State private var showingTitleEditor = false
    @State private var editingTitle = ""
    @State private var showingNoteList = false
    @State private var selectedNoteIndex = 0
    
    // 現在のノートブックのメモを取得
    private var noteManager: NoteManager {
        NoteManager(noteBook: noteBookManager.noteBooks.isEmpty ? NoteBook() : noteBookManager.noteBooks[noteBookManager.selectedNoteBookIndex])
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // サイドメニュー
                if showingSideMenu {
                    SideMenuView(
                        notes: noteManager.notes,
                        selectedIndex: $selectedNoteIndex,
                        onAddNote: {
                            noteManager.addNote()
                            DispatchQueue.main.async {
                                self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                            }
                        },
                        onAddPage: {
                            noteManager.addPage()
                            DispatchQueue.main.async {
                                self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                            }
                        },
                        onMergePages: {
                            noteManager.mergeAllPages()
                        },
                        onDeleteNote: { index in
                            noteManager.deleteNote(at: index)
                            DispatchQueue.main.async {
                                if self.selectedNoteIndex >= self.noteManager.notes.count {
                                    self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                                }
                            }
                        }
                    )
                    .frame(width: 300)
                    .transition(.move(edge: .leading))
                }
                
                // メインコンテンツ
                VStack(spacing: 0) {
                    // ヘッダー
                    HStack {
                        Button(action: {
                            withAnimation {
                                showingSideMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        if !noteManager.notes.isEmpty && selectedNoteIndex >= 0 && selectedNoteIndex < noteManager.notes.count {
                            Button(action: {
                                editingTitle = noteManager.notes[selectedNoteIndex].title
                                showingTitleEditor = true
                            }) {
                                HStack {
                                    Text(noteManager.notes[selectedNoteIndex].title)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // 新しいメモ追加ボタン
                            Button(action: {
                                // ハプティックフィードバック
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    noteManager.addNote()
                                    DispatchQueue.main.async {
                                        self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("新しいメモ")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.black)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // ページ追加ボタン（メモが存在する場合のみ表示）
                            if !noteManager.notes.isEmpty {
                                Button(action: {
                                    // ハプティックフィードバック
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        noteManager.addPage()
                                        DispatchQueue.main.async {
                                            self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.title3)
                                        Text("ページ追加")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray4))
                    
                    // キャンバスエリア
                    if !noteManager.notes.isEmpty {
                        PageFlipView(
                            notes: noteManager.notes,
                            currentIndex: $selectedNoteIndex,
                            onNoteChanged: {
                                noteManager.saveNotes()
                            },
                            onAddPage: {
                                noteManager.addPage()
                                // 新しいページが追加された後、インデックスを最後のページに設定
                                DispatchQueue.main.async {
                                    self.selectedNoteIndex = self.noteManager.notes.count - 1
                                }
                            }
                        )
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            VStack(spacing: 12) {
                                Text("メモを追加してください")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                Text("上の「新しいメモ」ボタンをタップして\n最初のメモを作成しましょう")
                                    .font(.body)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            
                            // 大きな追加ボタンを中央に配置
                            Button(action: {
                                // ハプティックフィードバック
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    noteManager.addNote()
                                    DispatchQueue.main.async {
                                        self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                                    }
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("最初のメモを作成")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.black)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                    }
                    
                    // ページビュー（下のナビゲーション）
                    if noteManager.notes.count > 1 {
                        PageIndicatorView(
                            currentIndex: selectedNoteIndex,
                            totalPages: noteManager.notes.count,
                            onPageSelected: { index in
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                                    selectedNoteIndex = index
                                }
                            }
                        )
                        .padding()
                        .background(Color(.systemGray4))
                    }
                }
            }
        }
        .onAppear {
            print("ContentView onAppear - noteBooks count: \(noteBookManager.noteBooks.count)")
            if noteBookManager.noteBooks.isEmpty {
                print("Creating initial notebook")
                noteBookManager.addNoteBook()
            }
            noteManager.loadNotes()
            print("After loadNotes - notes count: \(noteManager.notes.count)")
        }
        .sheet(isPresented: $showingTitleEditor) {
            TitleEditorView(
                title: $editingTitle,
                onSave: { newTitle in
                    if !noteManager.notes.isEmpty && selectedNoteIndex >= 0 && selectedNoteIndex < noteManager.notes.count {
                        noteManager.notes[selectedNoteIndex].title = newTitle
                        noteManager.saveNotes()
                    }
                },
                onCancel: {
                    showingTitleEditor = false
                }
            )
        }
    }
}

// サイドメニュービュー
struct SideMenuView: View {
    let notes: [Note]
    @Binding var selectedIndex: Int
    let onAddNote: () -> Void
    let onAddPage: () -> Void
    let onMergePages: () -> Void
    let onDeleteNote: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("メモ一覧")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                HStack {
                    Button(action: onAddNote) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: onAddPage) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: onMergePages) {
                        Image(systemName: "doc.on.doc")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                        NoteListItemView(
                            note: note,
                            isSelected: index == selectedIndex,
                            onTap: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                                    selectedIndex = index
                                }
                            },
                            onDelete: {
                                onDeleteNote(index)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGray6))
    }
}

// メモリストアイテムビュー
struct NoteListItemView: View {
    let note: Note
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingTitleEditor = false
    @State private var editingTitle = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    editingTitle = note.title
                    showingTitleEditor = true
                }) {
                    HStack {
                        Text(note.title)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding()
        .background(isSelected ? Color.black.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
        .sheet(isPresented: $showingTitleEditor) {
            TitleEditorView(
                title: $editingTitle,
                onSave: { newTitle in
                    note.title = newTitle
                },
                onCancel: {
                    showingTitleEditor = false
                }
            )
        }
    }
}

// ノートキャンバスビュー
struct NoteCanvasView: View {
    @Binding var note: Note
    let onNoteChanged: () -> Void
    
    var body: some View {
        PKCanvasViewRepresentable(
            note: $note,
            onDrawingChanged: {
                print("Drawing changed for note: \(note.title)")
                onNoteChanged()
                // 描画後にOCRを実行してタイトルを自動更新
                performOCR(on: note.canvasView) { recognizedText in
                    if !recognizedText.isEmpty && note.title == "新しいメモ" {
                        note.title = recognizedText
                    }
                }
            }
        )
        .background(Color.white)
        .onAppear {
            print("NoteCanvasView appeared for note: \(note.title)")
        }
    }
    
    // OCR機能
    private func performOCR(on canvasView: PKCanvasView, completion: @escaping (String) -> Void) {
        let drawing = canvasView.drawing
        guard !drawing.strokes.isEmpty else {
            completion("")
            return
        }
        
        // PKCanvasViewの描画をUIImageに変換
        let image = drawing.image(from: canvasView.bounds, scale: 2.0) // 高解像度で変換
        
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            // 複数の候補を取得し、最も信頼度の高いものを選択
            var allTexts: [(String, Float)] = []
            
            for observation in observations {
                for candidate in observation.topCandidates(3) {
                    allTexts.append((candidate.string, candidate.confidence))
                }
            }
            
            // 信頼度でソートし、最も信頼度の高いテキストを選択
            let sortedTexts = allTexts.sorted { $0.1 > $1.1 }
            
            // 最初の数行を結合してタイトルとして使用（改行で区切られた最初の部分）
            let title = sortedTexts.first?.0 ?? ""
            let cleanTitle = title.components(separatedBy: .newlines).first ?? title
            
            DispatchQueue.main.async {
                completion(cleanTitle)
            }
        }
        
        // より高精度な設定
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // 日本語と英語の両方をサポート（iOS 13.0以降）
        if #available(iOS 13.0, *) {
            request.recognitionLanguages = ["ja", "en"]
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion("")
                }
            }
        }
    }
}

// PencilKitキャンバスビューのラッパー
struct PKCanvasViewRepresentable: UIViewRepresentable {
    @Binding var note: Note
    let onDrawingChanged: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        
        // ツールと背景色を設定
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.backgroundColor = .white
        canvasView.delegate = context.coordinator
        
        // Apple Pencilと指での描画を有効にする設定
        canvasView.drawingPolicy = .anyInput
        canvasView.isOpaque = false
        canvasView.allowsFingerDrawing = true
        
        // タッチとペンの両方を有効にする
        canvasView.isUserInteractionEnabled = true
        canvasView.isMultipleTouchEnabled = true
        
        // フレームを明示的に設定
        canvasView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // 既存の描画データを安全に設定
        do {
            canvasView.drawing = note.canvasView.drawing
            print("Canvas drawing data set successfully")
        } catch {
            print("描画データの設定エラー: \(error)")
            canvasView.drawing = PKDrawing()
        }
        
        print("PKCanvasView created with frame: \(canvasView.frame)")
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 描画データが変更された場合のみ安全に更新
        do {
            if uiView.drawing != note.canvasView.drawing {
                print("Updating canvas drawing data")
                uiView.drawing = note.canvasView.drawing
            }
        } catch {
            print("描画データの更新エラー: \(error)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PKCanvasViewRepresentable
        private var isUpdating = false
        
        init(_ parent: PKCanvasViewRepresentable) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // 更新中の重複を防ぐ
            guard !isUpdating else { return }
            isUpdating = true
            
            // 安全に描画データを更新
            DispatchQueue.main.async {
                do {
                    self.parent.note.canvasView.drawing = canvasView.drawing
                    self.parent.onDrawingChanged()
                } catch {
                    print("描画データの保存エラー: \(error)")
                }
                self.isUpdating = false
            }
        }
    }
}

// ページめくりビュー
struct PageFlipView: View {
    let notes: [Note]
    @Binding var currentIndex: Int
    let onNoteChanged: () -> Void
    let onAddPage: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var pageRotation: Double = 0
    
    // 安全なインデックス取得
    private var safeCurrentIndex: Int {
        guard !notes.isEmpty else { return 0 }
        return max(0, min(currentIndex, notes.count - 1))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 現在のページ
                if !notes.isEmpty && safeCurrentIndex < notes.count {
                    NoteCanvasView(
                        note: Binding(
                            get: { 
                                guard safeCurrentIndex >= 0 && safeCurrentIndex < notes.count else {
                                    return Note()
                                }
                                return notes[safeCurrentIndex] 
                            },
                            set: { newNote in
                                // 描画データを安全に保存
                                guard safeCurrentIndex >= 0 && safeCurrentIndex < notes.count else { return }
                                DispatchQueue.main.async {
                                    notes[safeCurrentIndex].canvasView.drawing = newNote.canvasView.drawing
                                    notes[safeCurrentIndex].title = newNote.title
                                    onNoteChanged()
                                }
                            }
                        ),
                        onNoteChanged: onNoteChanged
                    )
                    .scaleEffect(isDragging ? 0.95 : 1.0)
                    .offset(x: dragOffset)
                    .rotation3DEffect(
                        .degrees(pageRotation),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .zIndex(2)
                }
                
                // 前のページ（右側に隠れている）
                if safeCurrentIndex > 0 && safeCurrentIndex - 1 < notes.count {
                    NoteCanvasView(
                        note: .constant(notes[safeCurrentIndex - 1]),
                        onNoteChanged: onNoteChanged
                    )
                    .offset(x: -geometry.size.width + dragOffset)
                    .rotation3DEffect(
                        .degrees(-15 + pageRotation * 0.3),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .zIndex(1)
                }
                
                // 次のページ（左側に隠れている）
                if safeCurrentIndex >= 0 && safeCurrentIndex + 1 < notes.count {
                    NoteCanvasView(
                        note: .constant(notes[safeCurrentIndex + 1]),
                        onNoteChanged: onNoteChanged
                    )
                    .offset(x: geometry.size.width + dragOffset)
                    .rotation3DEffect(
                        .degrees(15 - pageRotation * 0.3),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .zIndex(1)
                }
            }
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                        
                        // ドラッグに応じてページの回転を計算
                        let progress = min(abs(value.translation.width) / geometry.size.width, 1.0)
                        pageRotation = progress * 15 * (value.translation.width > 0 ? -1 : 1)
                    }
                    .onEnded { value in
                        let threshold: CGFloat = geometry.size.width * 0.2
                        let velocity = value.velocity.width
                        
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            print("Swipe detected - translation: \(value.translation.width), velocity: \(velocity), threshold: \(threshold)")
                            print("Current index: \(safeCurrentIndex), notes count: \(notes.count)")
                            
                            if value.translation.width > threshold || velocity > 300 {
                                // 右スワイプ - 前のページ
                                print("Right swipe - going to previous page")
                                if safeCurrentIndex > 0 {
                                    currentIndex = max(0, safeCurrentIndex - 1)
                                    print("Updated currentIndex to: \(currentIndex)")
                                }
                            } else if value.translation.width < -threshold || velocity < -300 {
                                // 左スワイプ - 次のページ
                                print("Left swipe - going to next page")
                                if safeCurrentIndex < notes.count - 1 {
                                    currentIndex = min(notes.count - 1, safeCurrentIndex + 1)
                                    print("Updated currentIndex to: \(currentIndex)")
                                } else if safeCurrentIndex == notes.count - 1 {
                                    // 最後のページで左スワイプ - 新しいページを追加
                                    print("Last page - adding new page")
                                    onAddPage()
                                    // 新しいページが追加された後にインデックスを最後のページに設定
                                    DispatchQueue.main.async {
                                        currentIndex = notes.count - 1
                                        print("Updated currentIndex to: \(currentIndex)")
                                    }
                                }
                            }
                            
                            dragOffset = 0
                            pageRotation = 0
                            isDragging = false
                        }
                    }
            )
        }
    }
}

// ページインジケータービュー
struct PageIndicatorView: View {
    let currentIndex: Int
    let totalPages: Int
    let onPageSelected: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<totalPages, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        onPageSelected(index)
                    }
                }) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(index == currentIndex ? .white : .black)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(index == currentIndex ? Color.black : Color.gray.opacity(0.3))
                        )
                }
            }
        }
    }
}

// タイトルエディタービュー
struct TitleEditorView: View {
    @Binding var title: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var tempTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タイトルを編集")
                        .font(.headline)
                    
                    TextField("メモのタイトルを入力", text: $tempTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onAppear {
                            tempTitle = title
                            isTextFieldFocused = true
                        }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("タイトル編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(tempTitle.isEmpty ? "新しいメモ" : tempTitle)
                    }
                    .disabled(tempTitle.isEmpty)
                }
            }
        }
    }
}

// ノートブック（ファイル）データモデル
class NoteBook: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var createdAt: Date
    @Published var notes: [Note]
    
    init(title: String = "新しいノートブック", createdAt: Date = Date()) {
        self.title = title
        self.createdAt = createdAt
        self.notes = []
    }
}

// ノートマネージャー
class NoteManager: ObservableObject {
    @Published var notes: [Note]
    private let noteBook: NoteBook
    
    init(noteBook: NoteBook) {
        self.noteBook = noteBook
        self.notes = noteBook.notes
    }
    
    func addNote() {
        print("addNote() called - current notes count: \(notes.count)")
        let newNote = Note()
        notes.append(newNote)
        noteBook.notes = notes
        print("addNote() completed - new notes count: \(notes.count)")
        
        // SwiftUIの更新を確実にする
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        saveNotes()
    }
    
    func addPage() {
        addNote()
    }
    
    func deleteNote(at index: Int) {
        guard index >= 0 && index < notes.count else { return }
        notes.remove(at: index)
        noteBook.notes = notes
        saveNotes()
    }
    
    func mergeAllPages() {
        // 全ページをマージする機能（実装は省略）
    }
    
    func saveNotes() {
        noteBook.notes = notes
    }
    
    func loadNotes() {
        notes = noteBook.notes
    }
}

// ノートデータモデル
class Note: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var createdAt: Date
    let canvasView: PKCanvasView
    
    init(title: String = "新しいメモ", createdAt: Date = Date()) {
        self.title = title
        self.createdAt = createdAt
        self.canvasView = PKCanvasView()
    }
}

// ノートブックマネージャー
class NoteBookManager: ObservableObject {
    @Published var noteBooks: [NoteBook] = []
    @Published var selectedNoteBookIndex: Int = 0
    
    func addNoteBook() {
        print("addNoteBook() called")
        DispatchQueue.main.async {
            let newNoteBook = NoteBook()
            self.noteBooks.append(newNoteBook)
            print("addNoteBook() completed - noteBooks count: \(self.noteBooks.count)")
            
            // SwiftUIの更新を確実にする
            self.objectWillChange.send()
            
            self.saveNoteBooks()
        }
    }
    
    func deleteNoteBook(at index: Int) {
        guard index >= 0 && index < noteBooks.count else { return }
        
        DispatchQueue.main.async {
            self.noteBooks.remove(at: index)
            if self.selectedNoteBookIndex >= self.noteBooks.count {
                self.selectedNoteBookIndex = max(0, self.noteBooks.count - 1)
            }
            self.saveNoteBooks()
        }
    }
    
    func addNoteToCurrentBook() {
        guard selectedNoteBookIndex >= 0 && selectedNoteBookIndex < noteBooks.count else { return }
        
        DispatchQueue.main.async {
            let newNote = Note()
            self.noteBooks[self.selectedNoteBookIndex].notes.append(newNote)
            self.saveNoteBooks()
        }
    }
    
    func deleteNoteFromCurrentBook(at noteIndex: Int) {
        guard selectedNoteBookIndex >= 0 && selectedNoteBookIndex < noteBooks.count else { return }
        guard noteIndex >= 0 && noteIndex < noteBooks[selectedNoteBookIndex].notes.count else { return }
        
        DispatchQueue.main.async {
            self.noteBooks[self.selectedNoteBookIndex].notes.remove(at: noteIndex)
            self.saveNoteBooks()
        }
    }
    
    func saveNoteBooks() {
        do {
            let encoder = JSONEncoder()
            let noteBooksData = try encoder.encode(noteBooks.map { noteBook in
                NoteBookData(
                    id: noteBook.id,
                    title: noteBook.title,
                    createdAt: noteBook.createdAt,
                    notes: noteBook.notes.map { note in
                        NoteData(
                            id: note.id,
                            title: note.title,
                            createdAt: note.createdAt,
                            drawingData: note.canvasView.drawing.dataRepresentation()
                        )
                    }
                )
            })
            UserDefaults.standard.set(noteBooksData, forKey: "savedNoteBooks")
        } catch {
            print("保存エラー: \(error)")
        }
    }
    
    func loadNoteBooks() {
        guard let noteBooksData = UserDefaults.standard.data(forKey: "savedNoteBooks") else { return }
        
        do {
            let decoder = JSONDecoder()
            let savedNoteBooks = try decoder.decode([NoteBookData].self, from: noteBooksData)
            
            DispatchQueue.main.async {
                self.noteBooks = savedNoteBooks.map { noteBookData in
                    let noteBook = NoteBook(title: noteBookData.title, createdAt: noteBookData.createdAt)
                    noteBook.notes = noteBookData.notes.map { noteData in
                        let note = Note(title: noteData.title, createdAt: noteData.createdAt)
                        do {
                            let drawing = try PKDrawing(data: noteData.drawingData)
                            note.canvasView.drawing = drawing
                        } catch {
                            print("描画データの読み込みエラー: \(error)")
                            note.canvasView.drawing = PKDrawing()
                        }
                        return note
                    }
                    return noteBook
                }
            }
        } catch {
            print("読み込みエラー: \(error)")
        }
    }
}

// データ保存用の構造体
struct NoteBookData: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let notes: [NoteData]
}

struct NoteData: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let drawingData: Data
}

// カスタムボタンスタイル（タップ効果付き）
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
