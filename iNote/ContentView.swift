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
        let manager = NoteManager(noteBook: noteBookManager.noteBooks.isEmpty ? NoteBook() : noteBookManager.noteBooks[noteBookManager.selectedNoteBookIndex])
        manager.setNoteBookManager(noteBookManager)
        return manager
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
                            self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                        },
                        onAddPage: {
                            noteManager.addPage()
                            self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
                        },
                        onMergePages: {
                            noteManager.mergeAllPages()
                        },
                        onDeleteNote: { index in
                            noteManager.deleteNote(at: index)
                            if self.selectedNoteIndex >= self.noteManager.notes.count {
                                self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
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
                                        self.selectedNoteIndex = max(0, self.noteManager.notes.count - 1)
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
                                print("Adding new page - current notes count: \(noteManager.notes.count)")
                                noteManager.addPage()
                                // 新しいページが追加された後、インデックスを最後のページに設定
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    let newIndex = self.noteManager.notes.count - 1
                                    guard newIndex >= 0 && newIndex < self.noteManager.notes.count else {
                                        print("Error: Invalid index \(newIndex) for notes count \(self.noteManager.notes.count)")
                                        return
                                    }
                                    self.selectedNoteIndex = newIndex
                                    print("Page added - selectedNoteIndex updated to: \(self.selectedNoteIndex), notes count: \(self.noteManager.notes.count)")
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
                                withAnimation(.easeInOut(duration: 0.3)) {
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
            // データを読み込む
            noteBookManager.loadNoteBooks()
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
            onDrawingChanged: { recognizedText in
                if !recognizedText.isEmpty && note.title == "新しいメモ" {
                    note.title = recognizedText
                }
                onNoteChanged()
            }
        )
        .background(Color.white)
        .clipped()
        .onAppear {
            print("NoteCanvasView appeared for note: \(note.title)")
        }
        .onDisappear {
            print("NoteCanvasView disappeared for note: \(note.title)")
        }
    }
    
    // OCR機能
    private func performOCR(on canvasView: PKCanvasView, completion: @escaping (String) -> Void) {
        let drawing = canvasView.drawing
        guard !drawing.strokes.isEmpty else {
            completion("")
            return
        }
        
        let image = drawing.image(from: canvasView.bounds, scale: 2.0)
        
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let title = recognizedStrings.joined(separator: "\n").components(separatedBy: .newlines).first ?? ""
            
            DispatchQueue.main.async {
                completion(title)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ja", "en"]
        
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
    let onDrawingChanged: (String) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        
        // ツールと背景色を設定
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.backgroundColor = .white
        canvasView.delegate = context.coordinator
        
        // Apple Pencilと指での描画を有効にする設定
        canvasView.drawingPolicy = .anyInput
        canvasView.isOpaque = true // 背景を不透明に
        canvasView.allowsFingerDrawing = true
        
        // 既存の描画データを安全に設定
        do {
            canvasView.drawing = try PKDrawing(data: note.drawingData)
        } catch {
            print("描画データの設定エラー: \(error)")
            canvasView.drawing = PKDrawing()
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // note ID が変更された場合、または描画データが異なる場合にキャンバスを更新
        if context.coordinator.lastNoteID != note.id {
            do {
                uiView.drawing = try PKDrawing(data: note.drawingData)
                context.coordinator.lastNoteID = note.id
            } catch {
                print("描画データのリセットエラー: \(error)")
                uiView.drawing = PKDrawing()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onDrawingChanged: onDrawingChanged)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PKCanvasViewRepresentable
        var lastNoteID: UUID?
        private var isUpdating = false
        private let onDrawingChanged: (String) -> Void

        init(_ parent: PKCanvasViewRepresentable, onDrawingChanged: @escaping (String) -> Void) {
            self.parent = parent
            self.onDrawingChanged = onDrawingChanged
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // 更新中の重複を防ぐ
            guard !isUpdating else { return }
            isUpdating = true
            
            // 安全に描画データを更新
            DispatchQueue.main.async {
                self.parent.note.drawingData = canvasView.drawing.dataRepresentation()
                
                // OCRを実行してタイトルを更新
                self.performOCR(on: canvasView) { recognizedText in
                    self.onDrawingChanged(recognizedText)
                }

                self.isUpdating = false
            }
        }

        // OCR機能
        private func performOCR(on canvasView: PKCanvasView, completion: @escaping (String) -> Void) {
            let drawing = canvasView.drawing
            guard !drawing.strokes.isEmpty else {
                completion("")
                return
            }
            
            let image = drawing.image(from: canvasView.bounds, scale: 2.0)
            
            guard let cgImage = image.cgImage else {
                completion("")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion("")
                    return
                }
                
                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                let title = recognizedStrings.joined(separator: "\n").components(separatedBy: .newlines).first ?? ""
                
                DispatchQueue.main.async {
                    completion(title)
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ja", "en"]
            
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
    @State private var isTransitioning = false
    @State private var previousIndex: Int = -1  // 無効なインデックスで初期化
    @State private var pageTransitionOpacity: Double = 1.0  // ページ切り替え時の透明度
    
    // 安全なインデックス取得
    private var safeCurrentIndex: Int {
        guard !notes.isEmpty else { 
            print("Warning: notes array is empty")
            return 0 
        }
        let safeIndex = max(0, min(currentIndex, notes.count - 1))
        if safeIndex != currentIndex {
            print("Warning: currentIndex \(currentIndex) adjusted to safeIndex \(safeIndex) for notes.count \(notes.count)")
        }
        return safeIndex
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色を設定
                Color(.systemGray6)
                    .ignoresSafeArea()
                    .zIndex(-1)
                
                // ページの境界線（常に表示）
                VStack {
                    // 上部の境界線
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: -geometry.size.height / 2)
                    
                    // 下部の境界線
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: geometry.size.height / 2)
                }
                .zIndex(1)
                
                // ページ仕切り線（常に表示）
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 2)
                    .offset(x: geometry.size.width / 2)
                    .zIndex(2)
                
                // ページ番号表示（常に表示）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(safeCurrentIndex + 1) / \(notes.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
                .zIndex(3)
                
                // 前のページ（左側に表示）
                if !notes.isEmpty && safeCurrentIndex > 0 {
                    let prevIndex = safeCurrentIndex - 1
                    if prevIndex >= 0 && prevIndex < notes.count {
                        NoteCanvasView(
                            note: .constant(notes[prevIndex]),
                            onNoteChanged: onNoteChanged
                        )
                        .id(notes[prevIndex].id) // IDを追加してビューを再生成
                        .frame(width: geometry.size.width - 4, height: geometry.size.height - 4)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .offset(x: -geometry.size.width + dragOffset)
                        .scaleEffect(0.95)
                        .opacity(0.7)
                        .zIndex(0)
                        .clipped()
                    }
                }
                
                // 現在のページ（中央に表示）
                if !notes.isEmpty && safeCurrentIndex < notes.count {
                    NoteCanvasView(
                        note: Binding(
                            get: { 
                                guard safeCurrentIndex >= 0 && safeCurrentIndex < notes.count else {
                                    print("Warning: safeCurrentIndex \(safeCurrentIndex) is out of range for notes.count \(notes.count)")
                                    return Note()
                                }
                                return notes[safeCurrentIndex] 
                            },
                            set: { newNote in
                                // 描画データを安全に保存
                                guard safeCurrentIndex >= 0 && safeCurrentIndex < notes.count else { 
                                    print("Warning: Cannot update note at index \(safeCurrentIndex) - out of range for notes.count \(notes.count)")
                                    return 
                                }
                                print("Updating note at index \(safeCurrentIndex) with title: \(newNote.title)")
                                notes[safeCurrentIndex].drawingData = newNote.drawingData
                                notes[safeCurrentIndex].title = newNote.title
                                onNoteChanged()
                            }
                        ),
                        onNoteChanged: onNoteChanged
                    )
                    .id(notes[safeCurrentIndex].id) // IDを追加してビューを再生成
                    .frame(width: geometry.size.width - 4, height: geometry.size.height - 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .scaleEffect(isDragging ? 0.98 : 1.0)
                    .offset(x: dragOffset)
                    .opacity(pageTransitionOpacity)
                    .zIndex(2)
                    .clipped()
                }
                
                // 次のページ（右側に表示）
                if !notes.isEmpty && safeCurrentIndex >= 0 && safeCurrentIndex + 1 < notes.count {
                    let nextIndex = safeCurrentIndex + 1
                    if nextIndex >= 0 && nextIndex < notes.count {
                        NoteCanvasView(
                            note: .constant(notes[nextIndex]),
                            onNoteChanged: onNoteChanged
                        )
                        .id(notes[nextIndex].id) // IDを追加してビューを再生成
                        .frame(width: geometry.size.width - 4, height: geometry.size.height - 4)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .offset(x: geometry.size.width + dragOffset)
                        .scaleEffect(0.95)
                        .opacity(0.7)
                        .zIndex(0)
                        .clipped()
                    }
                }
            }
            .clipped()
            .onChange(of: currentIndex) { newIndex in
                // ジェスチャーによるページ切り替え中は、このアニメーションを実行しない
                guard !isTransitioning else { return }

                // インデックスが変更された時にアニメーションを実行
                isTransitioning = true
                
                // PageViewControllerスタイルのページ切り替えアニメーション
                withAnimation(.easeInOut(duration: 0.3)) {
                    pageTransitionOpacity = 0.8
                }
                
                // 安全な範囲内でのみpreviousIndexを更新
                if safeCurrentIndex >= 0 && safeCurrentIndex < notes.count {
                    previousIndex = safeCurrentIndex
                }
                
                // ページ切り替え完了後の処理
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pageTransitionOpacity = 1.0
                    }
                }
                
                // アニメーション完了後に状態をリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTransitioning = false
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isTransitioning else { return }
                        isDragging = true
                        dragOffset = value.translation.width
                        
                        // ドラッグに応じてページの回転を計算
                        let progress = min(abs(value.translation.width) / geometry.size.width, 1.0)
                        pageRotation = progress * 10 * (value.translation.width > 0 ? -1 : 1)
                        
                        // ドラッグ中は透明度を調整してページ間の境界を明確にする
                        pageTransitionOpacity = 1.0 - (progress * 0.3)
                    }
                    .onEnded { value in
                        guard !isTransitioning else { return }
                        isTransitioning = true

                        let translation = value.translation.width
                        let velocity = value.velocity.width
                        let geometryWidth = geometry.size.width

                        // 慣性を考慮したスワイプ終了位置の予測
                        let predictedEndTranslation = translation + velocity * 0.1

                        var targetIndex = safeCurrentIndex

                        // ページ切り替えの閾値（画面幅の半分）
                        let switchThreshold = geometryWidth / 2

                        // 予測位置に基づいて目標インデックスを決定
                        if predictedEndTranslation < -switchThreshold && safeCurrentIndex < notes.count - 1 {
                            targetIndex += 1
                        } else if predictedEndTranslation > switchThreshold && safeCurrentIndex > 0 {
                            targetIndex -= 1
                        }

                        // 最後のページで新しいページを追加する処理
                        if safeCurrentIndex == notes.count - 1 && translation < -geometryWidth / 4 {
                            onAddPage()
                            // 元の位置に戻るアニメーション
                            withAnimation(.interpolatingSpring(stiffness: 170, damping: 30)) {
                                dragOffset = 0
                                isDragging = false
                            }
                            // 状態リセット
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.isTransitioning = false
                            }
                            return
                        }

                        // dragOffset の目標値を計算
                        // (現在のインデックス - 目標インデックス) * 画面幅
                        let targetOffset = CGFloat(safeCurrentIndex - targetIndex) * geometryWidth

                        // スプリングアニメーションで目標オフセットまで移動
                        withAnimation(.interpolatingSpring(stiffness: 170, damping: 30)) {
                            dragOffset = targetOffset
                            isDragging = false
                            pageRotation = 0
                            pageTransitionOpacity = 1.0
                        }

                        // アニメーション完了後に状態を更新・リセット
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.currentIndex = targetIndex
                            // アニメーションなしで dragOffset をリセット
                            self.dragOffset = 0
                            self.isTransitioning = false
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
                    withAnimation(.easeInOut(duration: 0.2)) {
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
class NoteBook: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var createdAt: Date
    @Published var notes: [Note]
    
    init(title: String = "新しいノートブック", createdAt: Date = Date(), notes: [Note] = []) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.notes = notes
    }

    // CodableのためのCodingKeys
    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, notes
    }
    
    // Decodableのためのイニシャライザ
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        notes = try container.decode([Note].self, forKey: .notes)
    }

    // Encodableのためのメソッド
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(notes, forKey: .notes)
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
        print("addPage() called - current notes count: \(notes.count)")
        let newNote = Note()
        notes.append(newNote)
        noteBook.notes = notes
        print("addPage() completed - new notes count: \(notes.count)")
        
        // 配列の整合性を確認
        guard notes.count > 0 else {
            print("Error: notes array is empty after adding page")
            return
        }
        
        // SwiftUIの更新を確実にする
        DispatchQueue.main.async {
            self.objectWillChange.send()
            print("NoteManager objectWillChange sent - notes count: \(self.notes.count)")
        }
        
        saveNotes()
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
        // NoteBookManagerの保存も呼び出す
        if let noteBookManager = noteBookManager {
            noteBookManager.saveNoteBooks()
        }
    }
    
    private weak var noteBookManager: NoteBookManager?
    
    func setNoteBookManager(_ manager: NoteBookManager) {
        self.noteBookManager = manager
    }
    
    func loadNotes() {
        notes = noteBook.notes
    }
}

// ノートデータモデル
class Note: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var createdAt: Date
    
    // PKCanvasViewの描画データをData型で保持
    var drawingData: Data
    
    // PKCanvasViewは表示のたびに生成するため、Noteモデルに保持しない
    // let canvasView: PKCanvasView
    
    init(title: String = "新しいメモ", createdAt: Date = Date(), drawingData: Data = Data()) {
        self.id = UUID() // ここでidを生成
        self.title = title
        self.createdAt = createdAt
        self.drawingData = drawingData
        // self.canvasView = PKCanvasView()
        // self.canvasView.drawing = try! PKDrawing(data: drawingData)
        
        // print("New Note created with title: \(title)")
    }

    // CodableのためのCodingKeys
    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, drawingData
    }
    
    // Decodableのためのイニシャライザ
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        drawingData = try container.decode(Data.self, forKey: .drawingData)
    }

    // Encodableのためのメソッド
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(drawingData, forKey: .drawingData)
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
            let noteBooksData = try encoder.encode(noteBooks)
            UserDefaults.standard.set(noteBooksData, forKey: "savedNoteBooks")
        } catch {
            print("保存エラー: \(error)")
        }
    }
    
    func loadNoteBooks() {
        guard let noteBooksData = UserDefaults.standard.data(forKey: "savedNoteBooks") else { return }
        
        do {
            let decoder = JSONDecoder()
            let savedNoteBooks = try decoder.decode([NoteBook].self, from: noteBooksData)
            
            DispatchQueue.main.async {
                self.noteBooks = savedNoteBooks
            }
        } catch {
            print("読み込みエラー: \(error)")
        }
    }
}

// データ保存用の構造体は不要になる
// struct NoteBookData: Codable { ... }
// struct NoteData: Codable { ... }

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
