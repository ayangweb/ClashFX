//
//  ImagePickerView.swift
//  ClashFX
//

import Cocoa
import UniformTypeIdentifiers

/// Configuration describing the differences between image picker variants.
struct ImagePickerConfig {
    let imagePreviewSize: CGFloat
    let descriptionText: String
    let selectPanelTitle: String
    let dragUTI: String
    let maxDimension: CGFloat
    let customImagePath: String

    let changeFailedText: String
    let resetFailedText: String
    let sizeWarningFormat: String

    /// File types for the open panel (macOS < 11).
    let allowedFileTypes: [String]

    /// Content types for the open panel (macOS 11+).
    /// The closure is typed as `() -> Any` to avoid referencing `UTType` on macOS < 11.
    /// Callers inside an `#available(macOS 11.0, *)` block cast the result to `[UTType]`.
    let allowedContentTypesProvider: () -> Any
}

/// Base image picker view with preview, description, select and reset buttons.
/// Subclasses provide configuration via `pickerConfig` and override
/// `currentImage()` / `didReloadImage()` for variant-specific behaviour.
class ImagePickerView: NSView {
    let previewWell = NSView()
    let imageView = NSImageView()
    private let descriptionLabel = NSTextField(labelWithString: "")
    private let selectButton = NSButton()
    let resetButton = NSButton()

    // MARK: - Subclass hooks

    /// Return the configuration for this picker variant.
    var pickerConfig: ImagePickerConfig {
        fatalError("Subclasses must override pickerConfig")
    }

    /// Return the image to display in the preview.
    func currentImage() -> NSImage {
        fatalError("Subclasses must override currentImage()")
    }

    /// Called after the image file has been changed or reset.
    func didReloadImage() {
        // Subclasses can override to perform additional actions.
    }

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Call from subclass init after `pickerConfig` is ready.
    func commonInit() {
        setupViews()
        registerForDraggedTypes([.fileURL])
    }

    // MARK: - UI Setup

    private func setupViews() {
        let config = pickerConfig
        translatesAutoresizingMaskIntoConstraints = false

        previewWell.translatesAutoresizingMaskIntoConstraints = false
        previewWell.wantsLayer = true
        applyNormalBorder()
        addSubview(previewWell)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = currentImage()
        previewWell.addSubview(imageView)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.stringValue = config.descriptionText
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.font = NSFont.systemFont(ofSize: 11)
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.maximumNumberOfLines = 0

        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.title = NSLocalizedString("Select Image", comment: "") + "..."
        selectButton.bezelStyle = .rounded
        selectButton.target = self
        selectButton.action = #selector(selectImage)

        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.title = NSLocalizedString("Reset to Default", comment: "")
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetImage)

        let buttonStack = NSStackView(views: [selectButton, resetButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .leading
        buttonStack.spacing = 6

        let rightStack = NSStackView(views: [descriptionLabel, buttonStack])
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.orientation = .vertical
        rightStack.alignment = .leading
        rightStack.spacing = 8
        addSubview(rightStack)

        NSLayoutConstraint.activate([
            previewWell.topAnchor.constraint(equalTo: topAnchor),
            previewWell.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewWell.widthAnchor.constraint(equalToConstant: 48),
            previewWell.heightAnchor.constraint(equalToConstant: 48),

            imageView.centerXAnchor.constraint(equalTo: previewWell.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: previewWell.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: config.imagePreviewSize),
            imageView.heightAnchor.constraint(equalToConstant: config.imagePreviewSize),

            rightStack.leadingAnchor.constraint(equalTo: previewWell.trailingAnchor, constant: 12),
            rightStack.topAnchor.constraint(equalTo: topAnchor),
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            descriptionLabel.widthAnchor.constraint(equalTo: rightStack.widthAnchor),

            bottomAnchor.constraint(equalTo: rightStack.bottomAnchor)
        ])

        updatePreview()
    }

    func updatePreview() {
        let hasCustom = FileManager.default.fileExists(atPath: pickerConfig.customImagePath)
        imageView.image = currentImage()
        resetButton.isEnabled = hasCustom
    }

    private func applyNormalBorder() {
        previewWell.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        previewWell.layer?.borderColor = NSColor.separatorColor.cgColor
        previewWell.layer?.borderWidth = 1.0
        previewWell.layer?.cornerRadius = 6.0
    }

    private func applyHighlightedBorder() {
        previewWell.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        previewWell.layer?.borderColor = NSColor.controlAccentColor.cgColor
        previewWell.layer?.borderWidth = 2.0
        previewWell.layer?.cornerRadius = 6.0
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let uti = pickerConfig.dragUTI
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: [uti]
        ]) as? [URL], !urls.isEmpty else {
            return []
        }
        applyHighlightedBorder()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        applyNormalBorder()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        applyNormalBorder()
        let uti = pickerConfig.dragUTI
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: [uti]
        ]) as? [URL], let srcURL = urls.first else {
            return false
        }
        return applyImage(from: srcURL)
    }

    // MARK: - Actions

    @objc private func selectImage() {
        let config = pickerConfig
        let panel = NSOpenPanel()
        panel.title = config.selectPanelTitle
        if #available(macOS 11.0, *) {
            if let types = config.allowedContentTypesProvider() as? [UTType] {
                panel.allowedContentTypes = types
            }
        } else {
            panel.allowedFileTypes = config.allowedFileTypes
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let srcURL = panel.url else { return }
        _ = applyImage(from: srcURL)
    }

    @objc private func resetImage() {
        let config = pickerConfig
        let destPath = config.customImagePath
        if FileManager.default.fileExists(atPath: destPath) {
            do {
                try FileManager.default.removeItem(atPath: destPath)
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = config.resetFailedText
                alert.informativeText = error.localizedDescription
                alert.runModal()
                return
            }
        }
        reloadImage()
    }

    private func applyImage(from srcURL: URL) -> Bool {
        let config = pickerConfig
        guard let image = NSImage(contentsOf: srcURL) else {
            let alert = NSAlert()
            alert.messageText = config.changeFailedText
            alert.informativeText = NSLocalizedString("The file could not be loaded as an image.", comment: "")
            alert.runModal()
            return false
        }

        if let rep = image.representations.first {
            let pixelSize = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            if pixelSize.width > config.maxDimension || pixelSize.height > config.maxDimension {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = config.changeFailedText
                alert.informativeText = String(
                    format: config.sizeWarningFormat,
                    Int(pixelSize.width), Int(pixelSize.height),
                    Int(config.maxDimension), Int(config.maxDimension)
                )
                alert.runModal()
                return false
            }
        }

        let destPath = config.customImagePath
        let destURL = URL(fileURLWithPath: destPath)
        let destDir = destURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destPath) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: destURL)
        } catch {
            let alert = NSAlert()
            alert.messageText = config.changeFailedText
            alert.informativeText = error.localizedDescription
            alert.runModal()
            return false
        }
        reloadImage()
        return true
    }

    private func reloadImage() {
        didReloadImage()
        imageView.image = currentImage()
        updatePreview()
    }
}
