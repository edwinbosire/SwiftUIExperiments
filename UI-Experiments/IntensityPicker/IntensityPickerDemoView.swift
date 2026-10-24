import SwiftUI

struct IntensityPickerDemoView: View {
    @Environment(\.dismiss) private var dismiss
    private let levels = IntensityLevel.standard
    @State private var selection = IntensityLevel.medium.id
    @State private var isPickerPresented = false

    private var level: IntensityLevel {
        levels.first { $0.id == selection } ?? levels[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back to experiments")
                .accessibilityIdentifier("close-intensity-picker-demo")
                Text("Intensity Picker")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .blur(radius: isPickerPresented ? 8 : 0)
            .allowsHitTesting(!isPickerPresented)

            GeometryReader { geometry in
                let keyboardHeight: CGFloat = geometry.size.height < 400 ? 0 : min(296, geometry.size.height * 0.46)
                ZStack(alignment: .bottom) {
                    Color.black
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        ComposerBar(level: level) { isPickerPresented = true }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                            .opacity(isPickerPresented ? 0 : 1)
                        if keyboardHeight > 0 {
                            MockKeyboardView()
                                .scaleEffect(x: 1, y: keyboardHeight / MockKeyboardView.height, anchor: .top)
                                .frame(height: keyboardHeight, alignment: .top)
                                .clipped()
                        }
                    }
                    .frame(maxWidth: 760)
                }
                .intensityPicker(isPresented: $isPickerPresented, levels: levels,
                                 selection: $selection, bottomInset: keyboardHeight + 24)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeOut(duration: 0.25), value: isPickerPresented)
    }
}

#Preview {
    NavigationStack { IntensityPickerDemoView() }
}
