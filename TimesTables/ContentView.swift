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
    // game control
    @State private var gameSetup = true
    @State private var gameRunning = false
    @State private var tableSelections = [Bool](repeating: false, count: 12)
    @State private var questionChoice = 0
    @State private var questions = [Question]()
    @State private var guesses = [Int]()
    @State private var currentQuestion = -1
    @State private var correctAnswer = 0
    @State private var correctIndex = 0
    @State private var guessIndex = -1
    // animation control
    @State private var correctGuess = false
    @State private var incorrectGuess = false
    @State private var animationRunning = false
    @State private var scaleAmount: CGFloat = 1.0
    @State private var opacityAmount = 1.0
    @State private var spinDegrees = 0.0
    @State private var spinAxis: (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
    // score tracking
    @State private var numberCorrect = 0
    @State private var numberWrong = 0

    var body: some View {
        ZStack {
            displayBackground

            VStack(spacing: 15) {
                if gameSetup {
                    Group {
                        displayTimesTableButtons

                        displayQuestionSelection

                        Spacer()

                        displayStartButton
                    }
                    .transition(AnyTransition.scale.animation(.linear(duration: 0.5)))
                } else {
                    Group {
                        displayQuestion

                        displayGamePlay

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
        HStack(alignment: .center) {
            let question = questions[min(currentQuestion, questions.count - 1)]
            let multiplier = question.multiplier - 1
            let multiplicand = question.multiplicand - 1

            TimesTableImage(index: multiplier, color: colors[multiplier % 7], size: 50)
            TimesTableText("x")
                .padding(.horizontal, -10)
            TimesTableImage(index: multiplicand, color: colors[multiplicand % 7], size: 50)
            TimesTableText("=")
                .padding(.horizontal, -10)
            TimesTableText("?")
                .padding(.horizontal, -10)
        }
        .disabled(!gameRunning)
        .opacity(!gameRunning ? 0.5 : 1.0)
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .timesTableGroupBorderStyle()
    }

    var displayGamePlay: some View {
        VStack {
            GridStack(rows: 3, columns: 3) { row, col in
                let index = row * 3 + col

                TimesTableAnswerButton("\(guesses[index])", color: colors[index % 7], size: 80) {
                    if gameRunning && !animationRunning {
                        animationRunning = true
                        guessTileTapped(index)
                        withAnimation(.linear(duration: 1.5)) {
                            scaleAmount = computedScaleEffect
                            opacityAmount = computedOpacity
                            spinDegrees = computedSpinDegrees
                            spinAxis = computedSpinAxis
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            setupNextQuestion()
                        }
                    }
                }
                .scaleEffect(animateSelection(for: index) ? scaleAmount : 1.0)
                .opacity(animateUnselected(for: index) ? opacityAmount : 1.0)
                .rotation3DEffect(
                    .degrees(animateSelection(for: index) ? spinDegrees : 0),
                    axis: animateSelection(for: index) ? spinAxis : (0, 0, 0)
                )
                .disabled(!gameRunning || animationRunning)
                .opacity(!gameRunning ? 0.5 : 1.0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
        .timesTableGroupBorderStyle()
    }

    var displayScoreInfo: some View {
        HStack {
            if correctGuess {
                TimesTableText("😀 Well done! 😀", font: .title2)
            } else if incorrectGuess {
                TimesTableText("Answer was \(correctAnswer)", font: .title2)
            } else {
                TimesTableText("(\(min(currentQuestion + 1, questions.count)) / \(questions.count)) 😀 \(numberCorrect) 😞 \(numberWrong)", font: .title2)
            }
        }
        .timesTableGroupBorderStyle()
    }

    var displayStartButton: some View {
        TimesTableButton("Start the game", color: .green) {
            gameSetup.toggle()
            initialiseGame()
            setupNextQuestion()
            gameRunning.toggle()
        }
        .disabled(!isGameReady)
        .opacity(isGameReady ? 1.0 : 0.5)
    }

    var displayRestartButton: some View {
        TimesTableButton(gameRunning ? "Next question" : "Start a new game", color: gameRunning ? .red : .green) {
            resetGame()
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

    var computedOpacity: Double {
        if correctGuess || incorrectGuess {
            return 0.25
        }
        return 1.0
    }

    var computedScaleEffect: CGFloat {
        if correctGuess {
            return 1.1
        } else if incorrectGuess {
            return 0.0
        } else {
            return 1.0
        }
    }

    var computedSpinDegrees: Double {
        if correctGuess {
            return 720
        } else if incorrectGuess {
            return -720
        }
        return 0
    }

    var computedSpinAxis: (CGFloat, CGFloat, CGFloat) {
        if correctGuess {
            return (0, 0, 1)
        } else if incorrectGuess {
            return (0, 1, 0)
        }
        return (0, 0, 0)
    }

    func initialiseGame() {
        questions = generateQuestions(from: selectedTables.shuffled())
    }

    func guessTileTapped(_ index: Int) {
        guessIndex = index
        if guessIndex == correctIndex {
            numberCorrect += 1
            correctGuess = true
        } else {
            numberWrong += 1
            correctGuess = false
        }
        incorrectGuess = !correctGuess
    }

    func setupNextQuestion() {
        resetAnimation()
        currentQuestion += 1
        if currentQuestion < questions.count {
            let question = questions[currentQuestion]
            guesses = question.guesses
            correctAnswer = question.multiplier * question.multiplicand
            correctIndex = Int.random(in: 0 ..< guesses.count)
            guesses.insert(correctAnswer, at: correctIndex)
        } else {
            gameRunning.toggle()
        }
    }

    func resetGame() {
        resetAnimation()
        currentQuestion = -1
        numberCorrect = 0
        numberWrong = 0
        tableSelections = [Bool](repeating: false, count: 12)
        gameSetup.toggle()
    }

    func resetAnimation() {
        correctGuess = false
        incorrectGuess = false
        animationRunning = false
        scaleAmount = 1.0
        opacityAmount = 1.0
        spinDegrees = 0.0
        spinAxis = (0, 0, 0)
    }

    func animateSelection(for choice: Int) -> Bool {
        return (correctGuess && choice == correctIndex) || (incorrectGuess && choice == guessIndex)
    }

    func animateUnselected(for choice: Int) -> Bool {
        return (correctGuess && choice != correctIndex) || (incorrectGuess && choice != correctIndex)
    }

    func generateQuestions(from tables: [Int]) -> [Question] {
        // compute a distribution for the questions that will be generated
        let distribution = computeDistribution(from: tables)
        // generate questions for each times table according to the computed distribution
        var multipliers = [Int]()

        return
            (0 ..< distribution.count).map { index in
                (0 ..< distribution[index]).map { _ in
                    // we don't want to repeat questions unless we have to so we use a shuffled
                    // array of integers, remove the first each time, and replenish it if there
                    // are still more questions to be generated
                    if multipliers.isEmpty {
                        multipliers = Array(1 ... 12).shuffled()
                    }
                    let multiplier = multipliers.removeFirst()
                    let multiplicand = tables[index] + 1
                    return Question(
                        multiplier: multiplier,
                        multiplicand: multiplicand,
                        guesses: generateGuesses(for: multiplier, in: multiplicand, count: 8)
                    )
                }
            }
            .reduce([], +)
            .shuffled()
    }

    func computeDistribution(from tables: [Int]) -> [Int] {
        // compute the number of questions for each of the selected times tables taking
        // into account that the user may have selected more tables than questions
        let numberOfTables = tables.count
        let value = questionChoices[questionChoice].value
        let numberOfQuestions = value > 0 ? value : numberOfTables * 12

        let quotient = numberOfQuestions / numberOfTables
        var remainder = numberOfQuestions % numberOfTables

        // this method of calculating the distribution aims to create a smooth distribution
        // by spreading the remainder among as many of the distribution buckets as possible
        // before there's no more remainder to distribute
        return
            (0 ..< numberOfTables)
                .map { _ in
                    if remainder > 0 {
                        remainder -= 1
                        return quotient + 1
                    }
                    return quotient
                }
    }

    func generateGuesses(for value: Int, in table: Int, count: Int) -> [Int] {
        return Array(
            Array(1 ... 12)
                .filter { $0 != value }
                .map { $0 * table }
                .shuffled()
                .prefix(count)
        )
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
    let font: Font
    let shadow: Bool

    init(_ label: String, color: Color = .white, font: Font = .title, shadow: Bool = true) {
        self.label = label
        self.color = color
        self.font = font
        self.shadow = shadow
    }

    var body: some View {
        Text(label)
            .font(font)
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

struct TimesTableAnswerButton: View {
    let label: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    init(_ label: String, color: Color, size: CGFloat, action: @escaping () -> Void = {}) {
        self.label = label
        self.color = color
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            TimesTableText(label)
                .frame(width: size, height: size)
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
