import SwiftUI
import UserNotifications
import AVFoundation // Import for playing audio
import ConfettiSwiftUI // Import the Confetti library

struct PomodoroTimer: View {
    @State private var timeRemaining = 25 * 60 // Initial work session duration
    @State private var timerRunning = false
    @State private var timer: Timer?
    @State private var currentInterval = 0 // Current interval (0–7)
    @State private var completedPomodoros = 0 // Number of full cycles completed
    @State private var totalWorkMinutes = 0 // Total minutes of studying completed, including partial intervals
    @State private var hoverScaleStart = false // State for hover effect on Start/Stop button
    @State private var hoverScaleSkip = false // State for hover effect on Skip button
    @State private var confettiCounter = 0 // State to trigger confetti animation
    @State private var player: AVAudioPlayer? // Audio player instance

    private let workTime =  25 * 60 // 25 minutes for work
    private let shortBreakTime = 5 * 60 // 5 minutes for short break
    private let longBreakTime = 15 * 60 // 15 minutes for long break
    private let totalIntervals = 8 // Total intervals: 4 work + 3 short breaks + 1 long break

    var body: some View {
        VStack(spacing: 16) {
            // Confetti Animation
            ConfettiCannon(counter: $confettiCounter, num: 100, colors: [.green, .red, .cyan, .yellow], radius: 500)

            // Dot Tracker
            HStack(spacing: 10) {
                ForEach(0..<7) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
            .padding(.top, 20) // Padding to move the dots away from the top edge

            // Main Content
            VStack(spacing: 12) {
                // Title
                Text(intervalTitle())
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                // Timer
                Text(timeFormatted(timeRemaining))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                // Loading Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(currentInterval % 2 == 0
                                  ? LinearGradient(gradient: Gradient(colors: [Color.teal, Color.green]), startPoint: .leading, endPoint: .trailing) // Green for work
                                  : LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .leading, endPoint: .trailing)) // Blue for breaks
                            .frame(width: CGFloat(Double(geometry.size.width) * elapsedPercentage()), height: 8)
                            .cornerRadius(4)
                            .animation(.linear(duration: 0.25), value: timeRemaining)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 20)

                // Buttons
                HStack(spacing: 16) {
                    // Dynamic Start/Stop Button with Hover Effect
                    Button(action: toggleTimer) {
                        Text(timerRunning ? "Stop" : "Start")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 70, height: 40)
                            .background(LinearGradient(gradient: Gradient(colors: timerRunning ? [Color.red, Color.orange] : [Color.teal, Color.green]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(color: timerRunning ? Color.red.opacity(0.6) : Color.teal.opacity(0.6), radius: 3, x: 0, y: 2)
                            .scaleEffect(hoverScaleStart ? 1.1 : 1.0) // Scale up on hover
                            .animation(.easeInOut(duration: 0.2), value: hoverScaleStart) // Smooth animation
                    }
                    .onHover { isHovering in
                        hoverScaleStart = isHovering
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Skip Button with Hover Effect
                    Button(action: skipInterval) {
                        Text("Skip")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 70, height: 40)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(color: Color.purple.opacity(0.6), radius: 3, x: 0, y: 2)
                            .scaleEffect(hoverScaleSkip ? 1.1 : 1.0) // Scale up on hover
                            .animation(.easeInOut(duration: 0.2), value: hoverScaleSkip) // Smooth animation
                    }
                    .onHover { isHovering in
                        hoverScaleSkip = isHovering
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Stats
                HStack(spacing: 16) {
                    Text("Pomodoros: \(completedPomodoros)")
                        .font(.system(size: 12))
                        .foregroundColor(.white)

                    Text("Minutes: \(totalWorkMinutes)")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 260, height: 300) // Adjusted dimensions for a slightly larger popup
        .background(Color.black)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: 5)
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Helper Functions
    func toggleTimer() {
        if timerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    func dotColor(for index: Int) -> Color {
        if index < currentInterval {
            return index % 2 == 0 ? .green : .white // Green for work, blue for breaks
        }
        return .gray.opacity(0.3) // Gray for upcoming intervals
    }

    func intervalTitle() -> String {
        if currentInterval == 7 {
            return "Long Break 😌"
        }
        return currentInterval % 2 == 0 ? "Focus Time 😏" : "Break Time 😊"
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func elapsedPercentage() -> Double {
        let total = currentInterval == 7
            ? Double(longBreakTime)
            : (currentInterval % 2 == 0 ? Double(workTime) : Double(shortBreakTime))
        return 1 - (Double(timeRemaining) / total)
    }

    func startTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                playSound() // Play sound when timer ends
                handleIntervalCompletion()
            }
        }
    }

    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }

    func skipInterval() {
        stopTimer()
        handleIntervalCompletion(skip: true)
    }

    func handleIntervalCompletion(skip: Bool = false) {
        // Add elapsed time for work intervals
        if currentInterval % 2 == 0 { // It's a work interval
            let elapsedMinutes = (workTime - timeRemaining) / 60
            totalWorkMinutes += elapsedMinutes
            confettiCounter += 1 // Trigger confetti when work session ends
        }

        if currentInterval == 7 {
            completedPomodoros += 1
            resetCycle()
        } else {
            currentInterval += 1
            timeRemaining = currentInterval == 7
                ? longBreakTime
                : (currentInterval % 2 == 0 ? workTime : shortBreakTime)
        }
    }

    func resetCycle() {
        currentInterval = 0
        timeRemaining = workTime
        timerRunning = false
    }

    func playSound() {
        guard let soundURL = Bundle.main.url(forResource: "sound", withExtension: "wav") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
                        player?.play()
                    } catch {
                        print("Failed to play sound: \(error.localizedDescription)")
                    }
                }
            }

            #Preview {
                PomodoroTimer()
            }
