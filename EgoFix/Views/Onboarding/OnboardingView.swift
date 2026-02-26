import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    init(viewModel: OnboardingViewModel, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome:
                WelcomeStepView(onContinue: viewModel.goToRankBugs)

            case .rankBugs:
                BugRankingView(
                    bugs: $viewModel.rankedBugs,
                    isLoading: viewModel.isLoading,
                    onConfirm: viewModel.confirmRanking,
                    onBack: viewModel.goBack
                )

            case .confirmation:
                PriorityConfirmationView(
                    topBugs: viewModel.topPriorities,
                    totalCount: viewModel.rankedBugs.count,
                    isLoading: viewModel.isLoading,
                    onConfirm: {
                        Task {
                            await viewModel.confirmSelection()
                        }
                    },
                    onBack: viewModel.goBack
                )
            }
        }
        .task {
            await viewModel.loadBugs()
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                onComplete()
            }
        }
    }
}

struct WelcomeStepView: View {
    let onContinue: () -> Void

    @State private var logoAppeared = false
    @State private var textAppeared = false
    @State private var buttonAppeared = false
    @State private var cursorVisible = true

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("EGOFIX")
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .opacity(logoAppeared ? 1 : 0)
                    .scaleEffect(logoAppeared ? 1 : 0.9)

                Text("v1.0.0")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .opacity(logoAppeared ? 1 : 0)
            }
            .padding(.bottom, 48)

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    Text("> Your ego is legacy software.")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(cursorVisible ? "_" : " ")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                }
                .opacity(textAppeared ? 1 : 0)

                Text("> Let's debug it.")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .opacity(textAppeared ? 1 : 0)
            }

            Spacer()

            Button(action: onContinue) {
                Text("[ Initialize ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(2)
            }
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 20)

            Spacer()
                .frame(height: 80)
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                textAppeared = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
                buttonAppeared = true
            }
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                cursorVisible.toggle()
            }
        }
    }
}

struct BugRankingView: View {
    @Binding var bugs: [Bug]
    let isLoading: Bool
    let onConfirm: () -> Void
    let onBack: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onBack) {
                Text("[ < Back ]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
            }
            .padding(.bottom, 20)

            Text("RANK YOUR BUGS")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)
                .padding(.bottom, 6)

            Text("// Drag to reorder")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
                .padding(.bottom, 2)

            Text("// Top = highest priority")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
                .padding(.bottom, 20)

            if isLoading {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView().tint(.green)
                    Spacer()
                }
                Spacer()
            } else {
                ReorderableList(items: $bugs)
                    .opacity(appeared ? 1 : 0)

                Spacer()
            }

            Button(action: onConfirm) {
                HStack {
                    Spacer()
                    Text("[ Continue ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color.green.opacity(0.1))
                .cornerRadius(2)
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}

struct ReorderableList: View {
    @Binding var items: [Bug]

    private let rowHeight: CGFloat = 88
    private let spacing: CGFloat = 8

    @State private var draggingItemID: UUID?
    @State private var dragStartIndex: Int = 0
    @State private var currentDragIndex: Int = 0
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Non-dragging items
            VStack(spacing: spacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let displayRank = displayRankFor(itemIndex: index)

                    BugRowView(bug: item, rank: displayRank, isDragging: false)
                        .opacity(draggingItemID == item.id ? 0 : 1)
                        .offset(y: offsetForItem(at: index))
                        .animation(.easeInOut(duration: 0.2), value: currentDragIndex)
                }
            }

            // Dragging item overlay
            if let draggingID = draggingItemID,
               let draggingItem = items.first(where: { $0.id == draggingID }),
               let originalIndex = items.firstIndex(where: { $0.id == draggingID }) {
                BugRowView(bug: draggingItem, rank: currentDragIndex + 1, isDragging: true)
                    .offset(y: CGFloat(originalIndex) * (rowHeight + spacing) + dragTranslation)
                    .zIndex(100)
            }
        }
        .frame(height: CGFloat(items.count) * rowHeight + CGFloat(items.count - 1) * spacing)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let startY = value.startLocation.y
                    let currentY = value.location.y

                    // Initialize drag
                    if draggingItemID == nil {
                        let index = min(max(0, Int(startY / (rowHeight + spacing))), items.count - 1)
                        draggingItemID = items[index].id
                        dragStartIndex = index
                        currentDragIndex = index
                    }

                    // Update translation
                    dragTranslation = currentY - value.startLocation.y

                    // Calculate target index based on current position
                    let draggedY = CGFloat(dragStartIndex) * (rowHeight + spacing) + dragTranslation + rowHeight / 2
                    let targetIndex = min(max(0, Int(draggedY / (rowHeight + spacing))), items.count - 1)

                    if targetIndex != currentDragIndex {
                        currentDragIndex = targetIndex
                    }
                }
                .onEnded { _ in
                    // Commit the reorder
                    if let draggingID = draggingItemID,
                       let fromIndex = items.firstIndex(where: { $0.id == draggingID }) {
                        if currentDragIndex != fromIndex {
                            withAnimation(.easeOut(duration: 0.2)) {
                                items.move(fromOffsets: IndexSet(integer: fromIndex),
                                          toOffset: currentDragIndex > fromIndex ? currentDragIndex + 1 : currentDragIndex)
                            }
                        }
                    }

                    withAnimation(.easeOut(duration: 0.15)) {
                        draggingItemID = nil
                        dragTranslation = 0
                    }
                }
        )
    }

    // Calculate visual offset for non-dragging items to make room
    private func offsetForItem(at index: Int) -> CGFloat {
        guard draggingItemID != nil else { return 0 }

        let itemID = items[index].id
        if itemID == draggingItemID { return 0 }

        // If item is between dragStart and currentDrag, shift it
        if dragStartIndex < currentDragIndex {
            // Dragging down: items between start and current shift up
            if index > dragStartIndex && index <= currentDragIndex {
                return -(rowHeight + spacing)
            }
        } else if dragStartIndex > currentDragIndex {
            // Dragging up: items between current and start shift down
            if index >= currentDragIndex && index < dragStartIndex {
                return rowHeight + spacing
            }
        }

        return 0
    }

    // Calculate display rank accounting for visual reorder
    private func displayRankFor(itemIndex: Int) -> Int {
        guard draggingItemID != nil else { return itemIndex + 1 }

        let itemID = items[itemIndex].id
        if itemID == draggingItemID {
            return currentDragIndex + 1
        }

        var visualIndex = itemIndex

        if dragStartIndex < currentDragIndex {
            if itemIndex > dragStartIndex && itemIndex <= currentDragIndex {
                visualIndex = itemIndex - 1
            }
        } else if dragStartIndex > currentDragIndex {
            if itemIndex >= currentDragIndex && itemIndex < dragStartIndex {
                visualIndex = itemIndex + 1
            }
        }

        return visualIndex + 1
    }
}

struct BugRowView: View {
    let bug: Bug
    let rank: Int
    let isDragging: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(bug.title)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(bug.bugDescription)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(white: 0.35))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .frame(height: 88)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(white: isDragging ? 0.12 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDragging ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .shadow(color: isDragging ? Color.black.opacity(0.5) : .clear, radius: 10, y: 4)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .green
        case 2: return Color(red: 0.5, green: 0.75, blue: 0.35)
        case 3: return Color(red: 0.65, green: 0.65, blue: 0.3)
        case 4: return Color(white: 0.45)
        case 5: return Color(white: 0.35)
        default: return Color(white: 0.3)
        }
    }
}

struct PriorityConfirmationView: View {
    let topBugs: [Bug]
    let totalCount: Int
    let isLoading: Bool
    let onConfirm: () -> Void
    let onBack: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Text("[ < Back ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))
                }
                Spacer()
            }
            .padding(.bottom, 40)

            VStack(spacing: 20) {
                Text("PRIORITY QUEUE")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))

                VStack(spacing: 14) {
                    ForEach(Array(topBugs.enumerated()), id: \.element.id) { index, bug in
                        HStack(spacing: 12) {
                            Text("#\(index + 1)")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(priorityColor(for: index))
                                .frame(width: 32, alignment: .trailing)

                            Text(bug.title)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }

                if totalCount > 3 {
                    Text("+ \(totalCount - 3) more")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))
                }

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 12)

                VStack(spacing: 6) {
                    Text("// Fixes from all bugs")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))

                    Text("// Weighted by your priorities")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                }
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(.green)
                    .padding(.bottom, 80)
            } else {
                Button(action: onConfirm) {
                    Text("[ Commit ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }
                .padding(.bottom, 80)
                .opacity(appeared ? 1 : 0)
            }
        }
        .padding(24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private func priorityColor(for index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return Color(red: 0.5, green: 0.75, blue: 0.35)
        case 2: return Color(red: 0.65, green: 0.65, blue: 0.3)
        case 3: return Color(white: 0.45)
        case 4: return Color(white: 0.35)
        default: return Color(white: 0.3)
        }
    }
}
