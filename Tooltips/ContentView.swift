//

import SwiftUI
import Observation

@Observable
final class CurrentTooltip {
    var current: Namespace.ID?
}

@propertyWrapper
struct TooltipState: DynamicProperty {
    @Namespace private var id
    @Environment(CurrentTooltip.self) private var state
    var wrappedValue: Bool {
        get { state.current == id }
        nonmutating set {
            if newValue {
                state.current = id
            } else {
                if state.current == id {
                    state.current = nil
                }
            }
        }
    }
    init() { }
}

struct TooltipModifier<TooltipContent: View>: ViewModifier {
    var tooltipContent: TooltipContent
//    @State private var isShowing = false
    @TooltipState var isShowing
    @State var rootMinY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                isShowing.toggle()
            }
            .overlay {
                GeometryReader { proxy in
                    ZStack {
                        if isShowing {
                            tooltipContent
                                .padding(8)
                                .background(.regularMaterial.shadow(.drop(color: Color.primary.opacity(0.2), radius: 2)), in: .rect(cornerRadius: 4))
                                .fixedSize()
                                .font(.body)
                                .onAppear {
                                    rootMinY = proxy.bounds(of: .named("root"))!.minY
                                }
                        }
                    }
                    .alignmentGuide(.top, computeValue: { dimension in
                        var attempt = dimension[.bottom] + 8
                        if rootMinY + attempt > 0 {
                            return -(proxy.size.height + 8)
                        }
                        return attempt
                    })
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
                }
            }
    }
}

extension View {
    func tooltip<Other: View>(@ViewBuilder other: () -> Other) -> some View {
        modifier(TooltipModifier(tooltipContent: other()))
    }
}


struct ContentView: View {

    var body: some View {
        ScrollView {
            Spacer().frame(height: 80)
            HStack(spacing: 32) {
                Image(systemName: "house")
                    .tooltip {
                        HStack {
                            Text("Home")
                            Circle()
                                .fill(.green)
                                .frame(width: 10, height: 10)
                        }
                    }
                Image(systemName: "video")
                    .tooltip {
                        HStack {
                            Text("Camera")
                            Circle()
                                .fill(.red)
                                .frame(width: 10, height: 10)
                        }
                    }
                Image(systemName: "mic")

            }
            .frame(maxWidth: .infinity)
            Spacer().frame(height: 8000)
        }
        .font(.largeTitle)
        .frame(maxHeight: .infinity, alignment: .top)
        .modifier(TooltipHelper())
    }
}

struct TooltipHelper: ViewModifier {
    @State var current = CurrentTooltip()
    func body(content: Content) -> some View {
        content
            .coordinateSpace(.named("root"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture {
                        current.current = nil
                    }
            }
            .environment(current)
    }
}

#Preview {
    ContentView()
}
