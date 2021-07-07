//
//  ContentView.swift
//  TimesTables
//
//  Created by Bruce Gilmour on 2021-07-05.
//

import SwiftUI

struct ContentView: View {
    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .pink, .purple]
    let questionChoices: [(label: String, value: Int)] = [
        ("5", 5),
        ("10", 10),
        ("20", 20),
        ("all", 0)
    ]

    @State private var gameSetup = true
    @State private var gameRunning = false
    @State private var questionChoice = 0
    @State private var tableSelections = [
        false, false, false, false,
        false, false, false, false,
        false, false, false, false
    ]

    var body: some View {
        ZStack {
            displayBackground

            Group {
                VStack(spacing: 15) {
                    if gameSetup {
                        Group {
                            displayTimesTableButtons

                            Spacer()

                            displayQuestionSelection

                            Spacer()

                            displayStartButton
                        }
                        .transition(AnyTransition.scale.animation(.linear(duration: 0.5)))
                    } else {
                        Group {
                            Spacer()

                            displayGamePlay

                            Spacer()

                            displayRestartButton
                        }
                        .transition(AnyTransition.scale.animation(.linear(duration: 0.5)))
                    }
                }
                .padding(10)
            }
        }
    }

    var displayBackground: some View {
        AngularGradient(
            gradient: Gradient(colors: [.green, .red, .yellow, .orange, .green]),
            center: .center
        )
        .edgesIgnoringSafeArea(.all)
    }

    var displayTimesTableButtons: some View {
        VStack {
            TimesTableText("Pick some times tables")

            GridStack(rows: 3, columns: 4) { row, col in
                let index = row * 4 + col

                TimesTableToggle(index: index, color: colors[index % 7], selected: $tableSelections[index]) {
                    // do nothing
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 15)
        }
        .timesTableGroupBorderStyle()
    }

    var displayQuestionSelection: some View {
        VStack {
            TimesTableText("How many questions?")

            Picker("How many questions?", selection: $questionChoice) {
                ForEach(0 ..< questionChoices.count) {
                    Text(questionChoices[$0].label)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorMultiply(.purple).colorInvert()
            .padding(.horizontal, 15)
            .padding(.top, -5)
            .padding(.bottom, 15)
        }
        .timesTableGroupBorderStyle()
    }

    var displayGamePlay: some View {
        VStack {
            TimesTableText("Questions: \(questionChoices[questionChoice].label)")

            ScrollView {
                ForEach(selectedTables, id: \.self) { index in
                    HStack {
                        TimesTableImage(index: index, color: colors[index % 7], size: 35)

                        Spacer()

                        Text("table[\(index + 1)]")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .listRowBackground(Color.clear)

                        Spacer()
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .timesTableGroupBorderStyle()
        }
    }

    var displayStartButton: some View {
        Button {
            gameSetup.toggle()
            initialiseGame()
            gameRunning.toggle()
            // temporary...
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("toggle game running")
                gameRunning.toggle()
            }
        } label: {
            TimesTableText("Start the game")
        }
        .buttonStyle(TimesTableButtonStyle(.green))
        .disabled(!isGameReady)
        .opacity(isGameReady ? 1.0 : 0.5)
    }

    var displayRestartButton: some View {
        Button {
            print("toggle game setup")
            gameSetup.toggle()
        } label: {
            TimesTableText("Start a new game")
        }
        .buttonStyle(TimesTableButtonStyle(.red))
        .disabled(gameRunning)
        .opacity(gameRunning ? 0.5 : 1.0)
    }

    var selectedTables: [Int] {
        (0 ..< tableSelections.count).filter {
            tableSelections[$0]
        }.reduce([]) {
            $0 + [$1]
        }
    }

    var isGameReady: Bool {
        selectedTables.count > 0
    }

    func initialiseGame() {
        // create questions based on selected times tables and
        // desired number of questions
        print("initialise game")
    }

}

struct TimesTableText: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .shadow(color: Color.black, radius: 2)
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
    }
}

struct TimesTableToggle: View {
    let index: Int
    let color: Color
    @Binding var selected: Bool
    let action: () -> Void

    init(index: Int, color: Color, selected: Binding<Bool>, action: @escaping () -> Void = {}) {
        self.index = index
        self.color = color
        self._selected = selected
        self.action = action
    }

    var body: some View {
        Toggle(isOn: $selected, label: {
            EmptyView()
        })
        .toggleStyle(TimesTableToggleStyle(index: index, color: color, isOn: selected, action: {
            selected.toggle()
        }))
    }
}

struct TimesTableToggleStyle: ToggleStyle {
    let index: Int
    let color: Color
    let isOn: Bool
    let action: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        Button(
            action: action,
            label: {
                Label {
                    configuration.label
                } icon: {
                    TimesTableImage(index: index, color: color, isWonky: true, isOn: configuration.isOn)
                }
            }
        )
    }
}

struct TimesTableImage: View {
    let index: Int
    let color: Color
    let size: CGFloat
    let isWonky: Bool
    let isOn: Bool

    init(index: Int, color: Color, size: CGFloat = 55, isWonky: Bool = false, isOn: Bool = false) {
        self.index = index
        self.color = color
        self.size = size
        self.isWonky = isWonky
        self.isOn = isOn
    }

    var body: some View {
        Image(systemName: "\(index + 1).square.fill")
            .resizable()
            .timesTableImageBodyStyle(color: color, width: size, height: size)
            .timesTableImageBorderStyle(isOn: isOn)
            .opacity(isOn ? 0.5 : 1.0)
            .animation(.easeOut)
            .padding(5)
            .rotationEffect(.degrees(!isWonky ? 0 : index % 2 == 0 ? -10 : 10), anchor: .center)
    }
}

struct TimesTableGroupBorderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white, lineWidth: 2)
                    .shadow(color: Color.black, radius: 4)
            )
    }
}

extension View {
    func timesTableGroupBorderStyle() -> some View {
        self.modifier(TimesTableGroupBorderStyle())
    }
}

struct TimesTableImageBodyStyle: ViewModifier {
    let color: Color
    let width: CGFloat
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .foregroundColor(color)
            .frame(width: width, height: height)
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
    }
}

extension View {
    func timesTableImageBodyStyle(color: Color, width: CGFloat, height: CGFloat) -> some View {
        self.modifier(TimesTableImageBodyStyle(color: color, width: width, height: height))
    }
}

struct TimesTableImageBorderStyle: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? Color.black : Color.white, lineWidth: 2)
                    .shadow(color: Color.black, radius: 2)
                    .animation(.easeOut)

            )
    }
}

extension View {
    func timesTableImageBorderStyle(isOn: Bool) -> some View {
        self.modifier(TimesTableImageBorderStyle(isOn: isOn))
    }
}

struct TimesTableButtonStyle: ButtonStyle {
    let color: Color

    init(_ color: Color) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .timesTableGroupBorderStyle()
    }
}

struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let content: (Int, Int) -> Content

    init(rows: Int, columns: Int, @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.content = content
    }

    var body: some View {
        VStack {
            ForEach(0 ..< rows, id: \.self) { row in
                HStack {
                    ForEach(0 ..< columns, id: \.self) { column in
                        self.content(row, column)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
