// Swift program that overlays motivational text with fade animation and auto-rotating quotes

import Cocoa

class StoicQuotesOverlayApp: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow?
    var textView: NSTextField?
    var isVisible = false
    var quotes: [String] = []
    var currentQuoteIndex = 0
    var quoteTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        loadQuotes()
        setupOverlayWindow()
        registerHotkeyListener()
        startQuoteRotation()
    }

    func loadQuotes() {
        quotes = [
            // Marcus Aurelius
            "You have power over your mind — not outside events. Realize this, and you will find strength. — Marcus Aurelius",
            "The best revenge is not to be like your enemy. — Marcus Aurelius",
            "If it is not right, do not do it; if it is not true, do not say it. — Marcus Aurelius",
            "The happiness of your life depends upon the quality of your thoughts. — Marcus Aurelius",
            "When you arise in the morning, think of what a privilege it is to be alive — to breathe, to think, to enjoy, to love. — Marcus Aurelius",
            "It never ceases to amaze me: we all love ourselves more than other people, but care more about their opinion than our own. — Marcus Aurelius",
            "You could leave life right now. Let that determine what you do and say and think. — Marcus Aurelius",
            "It is not death that a man should fear, but he should fear never beginning to live. — Marcus Aurelius",

            // Seneca
            "We suffer more often in imagination than in reality. — Seneca",
            "Difficulties strengthen the mind, as labor does the body. — Seneca",
            "He who is brave is free. — Seneca",
            "It is not that we have a short time to live, but that we waste a lot of it. — Seneca",
            "No man was ever wise by chance. — Seneca",
            "Begin at once to live, and count each separate day as a separate life. — Seneca",

            // Epictetus
            "It’s not what happens to you, but how you react to it that matters. — Epictetus",
            "No man is free who is not master of himself. — Epictetus",
            "Wealth consists not in having great possessions, but in having few wants. — Epictetus",
            "First say to yourself what you would be; and then do what you have to do. — Epictetus",
            "Freedom is the only worthy goal in life. It is won by disregarding things that lie beyond our control. — Epictetus",
            "Man conquers the world by conquering himself. — Zeno of Citium",
            "Well-being is attained by little and little, and nevertheless is no little thing itself. — Zeno of Citium",
            "Steel your sensibilities, so that life shall hurt you as little as possible. — Zeno of Citium",

            // Cleanthes (successor to Zeno)
            "Fate guides the willing, but drags the unwilling. — Cleanthes",

            // Musonius Rufus (Epictetus’s teacher)
            "Practice yourself, for heaven’s sake, in little things; and thence proceed to greater. — Musonius Rufus",
            "No man is better by chance. Virtue must be learned. — Musonius Rufus",
            "To be angry at something means you’ve forgotten: everything happens according to nature. — Musonius Rufus",

            // Hierocles (Stoic logician and ethicist)
            "Extend your care from yourself to your family, then to your community, then to the whole world. — Hierocles",

            // Aristo of Chios (Stoic radical)
            "What need is there to weep over parts of life? The whole of it calls for tears. — Aristo of Chios",

            // More from Epictetus for completeness
            "Don’t explain your philosophy. Embody it. — Epictetus",
            "Only the educated are free. — Epictetus",
        ]
    }

    func setupOverlayWindow() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame

        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        overlayWindow?.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.ignoresMouseEvents = true
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let contentView = NSView(frame: screenRect)
        overlayWindow?.contentView = contentView

        // Create blurred shadow layers behind text for glow effect
        for i in (1...3).reversed() {
            let shadow = NSTextField(labelWithString: quotes.first ?? "")
            shadow.translatesAutoresizingMaskIntoConstraints = false
            shadow.font = NSFont.systemFont(ofSize: 36, weight: .semibold)
            shadow.textColor = NSColor.white.withAlphaComponent(CGFloat(0.08 * Double(i)))
            shadow.alignment = .center
            shadow.wantsLayer = true
            shadow.layer?.shadowColor = NSColor.white.cgColor
            shadow.layer?.shadowOpacity = 1
            shadow.layer?.shadowRadius = CGFloat(i * 2)
            shadow.layer?.shadowOffset = .zero
            shadow.tag = 100 + i

            // Enable multiline wrapping
            shadow.usesSingleLineMode = false
            shadow.cell?.wraps = true
            shadow.cell?.truncatesLastVisibleLine = false
            shadow.maximumNumberOfLines = 0
            shadow.preferredMaxLayoutWidth = screenRect.width * 0.7

            contentView.addSubview(shadow)

            NSLayoutConstraint.activate([
                shadow.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                shadow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                shadow.widthAnchor.constraint(
                    lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),
            ])
        }

        // Main text view setup
        let text = NSTextField(labelWithString: quotes.first ?? "")
        text.translatesAutoresizingMaskIntoConstraints = false
        text.font = NSFont.systemFont(ofSize: 36, weight: .semibold)
        text.textColor = NSColor.white.withAlphaComponent(0.85)
        text.alignment = .center
        text.lineBreakMode = .byWordWrapping
        text.maximumNumberOfLines = 0
        text.usesSingleLineMode = false
        text.cell?.wraps = true
        text.cell?.truncatesLastVisibleLine = false
        text.alphaValue = 1.0
        text.preferredMaxLayoutWidth = screenRect.width * 0.7

        contentView.addSubview(text)
        self.textView = text

        NSLayoutConstraint.activate([
            text.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            text.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            text.widthAnchor.constraint(
                lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),
        ])
    }

    func startQuoteRotation() {
        showCurrentQuote(animated: false)
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.advanceQuote()
        }
    }
    func returnPreviousQuote() {
        currentQuoteIndex = (currentQuoteIndex - 1 + quotes.count) % quotes.count
        showCurrentQuote(animated: true)
    }
    func advanceQuote() {
        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
        showCurrentQuote(animated: true)
    }

    func showCurrentQuote(animated: Bool) {
        guard let contentView = overlayWindow?.contentView else { return }
        let newQuote = quotes[currentQuoteIndex]

        func updateShadows(with text: String) {
            for i in (1...3) {
                if let shadow = contentView.viewWithTag(100 + i) as? NSTextField {
                    shadow.stringValue = text
                }
            }
        }

        guard let textView = self.textView else { return }

        let shadowLayers: [NSTextField] = (1...3).compactMap {
            contentView.viewWithTag(100 + $0) as? NSTextField
        }
        let allLayers = [textView] + shadowLayers

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.4
                ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                for layer in allLayers {
                    layer.animator().alphaValue = 0.0
                }
            } completionHandler: {
                for layer in allLayers {
                    layer.alphaValue = 0.0
                    layer.stringValue = newQuote
                }
                updateShadows(with: newQuote)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.5
                        ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                        for layer in allLayers {
                            layer.animator().alphaValue =
                                (layer == textView)
                                ? 0.85
                                : CGFloat(0.08 * Double(layer.tag - 100))
                        }
                    }
                }
            }
        } else {
            for layer in allLayers {
                layer.alphaValue =
                    (layer == textView) ? 0.85 : CGFloat(0.08 * Double(layer.tag - 100))
                layer.stringValue = newQuote
            }
            updateShadows(with: newQuote)
        }
    }

    func registerHotkeyListener() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }

            if event.modifierFlags.contains([.control, .shift]) {
                switch event.keyCode {
                case 13: self.toggleOverlay()
                case 2: self.advanceQuote()
                case 0: self.returnPreviousQuote()
                default: break
                }
            }
        }
    }

    func toggleOverlay() {
        if isVisible {
            overlayWindow?.orderOut(nil)
        } else {
            overlayWindow?.makeKeyAndOrderFront(nil)
        }
        isVisible.toggle()
    }
}

let app = NSApplication.shared
let delegate = StoicQuotesOverlayApp()
app.delegate = delegate
app.run()
