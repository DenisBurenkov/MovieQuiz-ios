import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - Private functions
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var showingAlert: ShowAlertProtocol?
    private var statisticService: StatisticService?
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var textLabel: UILabel!
    @IBOutlet weak private var counterLabel: UILabel!
    @IBOutlet weak private var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        buttonAction(answer: true)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        buttonAction(answer: false)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showingAlert = AlertPresenter(alertDelegate: self)
        questionFactory = QuestionFactory(delegate: self)
        statisticService = StatisticServiceImplementation()
        
        questionFactory?.requestNextQuestion()
        
        viewClearBorder()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Actions
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named:  model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func viewClearBorder() {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.showNextQuestionOrResults()
        }
        buttonBlocked(answer: false)
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            showFinelResults()
            viewClearBorder()
            buttonBlocked(answer: true)
            
            
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
            
            viewClearBorder()
            buttonBlocked(answer: true)
        }
    }
    
    private func showFinelResults() {
        
        statisticService?.store(correct: correctAnswers, total: questionsAmount)
        
        let viewModel = AlertModel(titel: "Этот раунд окончен!",
                                   message: makeResultMassege(),
                                   buttonText: "Сыграть ещё раз",
                                   completion: { [weak self] _ in guard let self else { return }
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.questionFactory?.requestNextQuestion()
        })
        showingAlert?.showAlert(viewModel)
    }
    
    private func makeResultMassege() -> String {
        
        guard let statistic = statisticService, let bestGame = statistic.bestGame else {
            assertionFailure("Неизвестная ошибка")
            return ""
        }
        
        return
"""
Количество сыгранных квизов: \(String(describing: statistic.gamesCount))
Ваш результат: \(correctAnswers)/\(questionsAmount)
Рекорд: \(bestGame.correct)\\\(questionsAmount) (\(bestGame.date.dateTimeString))
Средняя точность: \(String(format: "%.2f", statistic.totalAccuracy))%
"""
    }
    
    private func buttonAction(answer givenAnswer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func buttonBlocked(answer: Bool) {
        noButton.isEnabled = answer
        yesButton.isEnabled = answer
    }
    
}
