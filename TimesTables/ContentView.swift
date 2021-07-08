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
        ("5", 5), ("10", 10), ("20", 20), ("all", 0)
    ]

    @State private var questions = [Question]()

    @State private var gameSetup = true
    @State private var gameRunning = false
    @State private var questionChoice = 0
    @State private var tableSelections = [Bool](repeating: false, count: 12)

    var body: some View {
        ZStack {
            displayBackground

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
                        displayQuestion

                        Spacer()

                        displayGamePlay

                        Spacer()

                        displayScoreInfo

                        Spacer()

                        displayRestartButton
                    }
                    .transition(AnyTransition.scale.animation(.linear(duration: 0.5)))
                }
            }
            .padding(10)
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

                TimesTableToggle(index: index, color: colors[index % 7], selected: $tableSelections[index])
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
                ForEach(0 ..< questionChoices.count) { index in
                    Text(questionChoices[index].label)
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

    var displayQuestion: some View {
        TimesTableText("Questions: \(questions.count)")
            .timesTableGroupBorderStyle()
    }

    var displayGamePlay: some View {
        VStack {
            ScrollView {
                ForEach(questions, id: \.self) { question in
                    let multiplier = question.multiplier - 1
                    let multiplicand = question.multiplicand - 1

                    HStack(alignment: .center) {
                        TimesTableImage(index: multiplier, color: colors[multiplier % 7], size: 40)
                        TimesTableText("x")
                            .padding(.horizontal, -10)
                        TimesTableImage(index: multiplicand, color: colors[multiplicand % 7], size: 40)
                        TimesTableText("=")
                            .padding(.horizontal, -10)
                        TimesTableText("?")
                            .padding(.horizontal, -10)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
        }
        .timesTableGroupBorderStyle()
    }

    var displayScoreInfo: some View {
        TimesTableText("Questions: \(questions.count)")
            .timesTableGroupBorderStyle()
    }

    var displayStartButton: some View {
        TimesTableButton("Start the game", color: .green) {
            gameSetup.toggle()
            initialiseGame()
            gameRunning.toggle()
            // temporary...
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("toggle game running")
                gameRunning.toggle()
            }
        }
        .disabled(!isGameReady)
        .opacity(isGameReady ? 1.0 : 0.5)
    }

    var displayRestartButton: some View {
        TimesTableButton("Start a new game", color: .red) {
            print("toggle game setup")
            tableSelections = [Bool](repeating: false, count: 12)
            gameSetup.toggle()
        }
        .disabled(gameRunning)
        .opacity(gameRunning ? 0.5 : 1.0)
    }

    var selectedTables: [Int] {
        // create a filtered collection of the indices of selected toggle buttons
        (0 ..< tableSelections.count).filter {
            tableSelections[$0]
        }.reduce([]) {
            $0 + [$1]
        }
    }

    var isGameReady: Bool {
        // at least one toggle button needs to be in the selected state
        selectedTables.count > 0
    }

    func initialiseGame() {
        let shuffledTables = selectedTables.shuffled()
        let numberOfTables = shuffledTables.count
        let value = questionChoices[questionChoice].value
        let numberOfQuestions = value > 0 ? value : numberOfTables * 12

        // compute the number of questions for each of the selected times tables taking
        // into account that the user may have selected more tables than questions
        let quotient = numberOfQuestions / numberOfTables
        let remainder = numberOfQuestions % numberOfTables

        var distribution = [Int]()

        if quotient == 0 {
            // more tables than questions so it's first come first served, one question each
            distribution = [Int](repeating: 1, count: numberOfQuestions)
        } else {
            // this method of computing the distribution simply adds any remainder onto the
            // final distribution entry rather than trying to spread it over as many as possible
            // which can result in a lumpy distribution
            //
            // numberOfTables = 3
            // numberOfQuestions = 5
            // distribution = [ 1, 1, 3] rather than [ 2, 2, 1 ]
            distribution = [Int](repeating: quotient, count: remainder == 0 ? numberOfTables : numberOfTables - 1)
            if remainder != 0 {
                distribution.append(quotient + remainder)
            }
        }

        // generate questions for each times table according to the computed distribution
        questions = []
        var multipliers = [Int]()

        for index in 0 ..< distribution.count {
            for _ in 0 ..< distribution[index] {
                // we don't want to repeat questions unless we have to so we used a shuffled
                // array of integers, remove the first each time, and replenish it if there
                // are still more questions to be generated
                if multipliers.isEmpty {
                    multipliers = Array(1 ... 12).shuffled()
                }
                questions.append(
                    Question(
                        multiplier: multipliers.removeFirst(),
                        multiplicand: shuffledTables[index] + 1,
                        guesses: [])
                )
            }
        }

        // shuffle the questions to mix up the tables
        questions.shuffle()
    }

}

// unashamedly stolen from the 100 days of swiftui course (created by paul hudson)
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
                        content(row, column)
                    }
                }
            }
        }
    }
}

struct TimesTableText: View {
    let label: String
    let color: Color
    let shadow: Bool

    init(_ label: String, color: Color = .white, shadow: Bool = true) {
        self.label = label
        self.color = color
        self.shadow = shadow
    }

    var body: some View {
        Text(label)
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .shadow(color: Color.black, radius: shadow ? 2 : 0)
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
    }
}

struct TimesTableButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    init(_ label: String, color: Color, action: @escaping () -> Void = {}) {
        self.label = label
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            TimesTableText(label)
        }
        .buttonStyle(TimesTableButtonStyle(color))
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

struct TimesTableButtonStyle: ButtonStyle {
    let color: Color

    init(_ color: Color) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(color)
            .timesTableGroupBorderStyle()
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
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

struct TimesTableGroupBorderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
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

struct Question: Hashable {
    let multiplier: Int    // randomly generated
    let multiplicand: Int  // one of the selected times tables
    let guesses: [Int]     // some wrong answers to be displayed
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
