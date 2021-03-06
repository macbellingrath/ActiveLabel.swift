//
//  ActiveLabel.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

public protocol ActiveLabelDelegate: class {
    func didSelectText(text: String, type: ActiveType)
}

@IBDesignable public class ActiveLabel: UILabel {
    
    // MARK: - public properties
    public weak var delegate: ActiveLabelDelegate?
    public var highlightColor: UIColor = UIColor.lightGrayColor()
    
    @IBInspectable public var URLColor: UIColor = .blueColor() {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var URLSelectedColor: UIColor? {
        didSet { updateTextStorage(parseText: false) }
    }
    @IBInspectable public var lineSpacing: Float? {
        didSet { updateTextStorage(parseText: false) }
    }
    
    // MARK: - public methods
    public func handleURLTap(handler: (NSURL) -> ()) {
        urlTapHandler = handler
    }
    
    public var copyable: Bool? {
        didSet { updateTextStorage(parseText: false) }
    }
    
    // MARK: - override UILabel properties
    override public var text: String? {
        didSet { updateTextStorage() }
    }
    
    override public var attributedText: NSAttributedString? {
        didSet { updateTextStorage() }
    }
    
    override public var font: UIFont! {
        didSet { updateTextStorage(parseText: false) }
    }
    
    override public var textColor: UIColor! {
        didSet { updateTextStorage(parseText: false) }
    }
    
    override public var textAlignment: NSTextAlignment {
        didSet { updateTextStorage(parseText: false)}
    }
    
    // MARK: - init functions
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _customizing = false
        setupLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _customizing = false
        setupLabel()
    }
    
    func setupTap() {
        userInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ActiveLabel.showMenu(_:))))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActiveLabel.hideEditMenu), name: UIMenuControllerWillHideMenuNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func showMenu(sender: AnyObject?) {
        becomeFirstResponder()
        let menu = UIMenuController.sharedMenuController()
        if !menu.menuVisible {
            backgroundColor = highlightColor
            menu.setTargetRect(bounds, inView: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    public override func copy(sender: AnyObject?) {
        let board = UIPasteboard.generalPasteboard()
        board.string = text
        let menu = UIMenuController.sharedMenuController()
        menu.setMenuVisible(false, animated: true)
    }
    
    public override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    public override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == #selector(NSObject.copy(_:)) {
            return true
        }
        return false
    }
    
    func hideEditMenu() {
        backgroundColor = UIColor.clearColor()
    }
    
    public override func drawTextInRect(rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackgroundForGlyphRange(range, atPoint: newOrigin)
        layoutManager.drawGlyphsForGlyphRange(range, atPoint: newOrigin)
    }
    
    
    // MARK: - customzation
    public func customize(block: (label: ActiveLabel) -> ()) -> ActiveLabel{
        _customizing = true
        block(label: self)
        _customizing = false
        updateTextStorage()
        return self
    }
    
    // MARK: - touch events
    func onTouch(touch: UITouch) -> Bool {
        let location = touch.locationInView(self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .Began, .Moved:
            if let element = elementAtLocation(location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    updateAttributesWhenSelected(false)
                    selectedElement = element
                    updateAttributesWhenSelected(true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(false)
                selectedElement = nil
            }
        case .Ended:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            switch selectedElement.element {
            case .URL(let url): didTapStringURL(url)
            case .Phone(let number): didTapPhoneNumber(number)
            case .None: ()
            }
            
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue()) {
                self.updateAttributesWhenSelected(false)
                self.selectedElement = nil
            }
            avoidSuperCall = true
        case .Cancelled:
            updateAttributesWhenSelected(false)
            selectedElement = nil
        case .Stationary:
            break
        }
        
        return avoidSuperCall
    }
    
    // MARK: - private properties
    private var _customizing: Bool = true
    
    private var urlTapHandler: ((NSURL) -> ())?
    private var phoneTapHandler: ((String) -> ())?
    
    private var selectedElement: (range: NSRange, element: ActiveElement)?
    private var heightCorrection: CGFloat = 0
    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()
    internal lazy var activeElements: [ActiveType: [(range: NSRange, element: ActiveElement)]] = [
        .URL: [],
        .Phone: []
    ]
    
    // MARK: - helper functions
    private func setupLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        userInteractionEnabled = true
    }
    
    private func updateTextStorage(parseText parseText: Bool = true) {
        if _customizing { return }
        // clean up previous active elements
        guard let attributedText = attributedText
            where attributedText.length > 0 else {
                return
        }
        
        if copyable ?? false {
            setupTap()
        }
        
        let mutAttrString = addLineBreak(attributedText)
        
        if parseText {
            selectedElement = nil
            for (type, _) in activeElements {
                activeElements[type]?.removeAll()
            }
            parseTextAndExtractActiveElements(mutAttrString)
        }
        
        self.addLinkAttribute(mutAttrString)
        self.textStorage.setAttributedString(mutAttrString)
        self.setNeedsDisplay()
    }
    
    private func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRectForTextContainer(textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    /// add link attribute
    private func addLinkAttribute(mutAttrString: NSMutableAttributedString) {
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributesAtIndex(0, effectiveRange: &range)
        
        attributes[NSFontAttributeName] = font!
        attributes[NSForegroundColorAttributeName] = textColor
        mutAttrString.addAttributes(attributes, range: range)
        
        for (type, elements) in activeElements {
            switch type {
            case .URL, .Phone: attributes[NSForegroundColorAttributeName] = URLColor
            case .None: ()
            }
            
            for element in elements {
                mutAttrString.setAttributes(attributes, range: element.range)
            }
        }
    }
    
    /// use regex check all link ranges
    private func parseTextAndExtractActiveElements(attrString: NSAttributedString) {
        let textString = attrString.string
        let textLength = textString.utf16.count
        let textRange = NSRange(location: 0, length: textLength)
        
        //URLS
        let urlElements = ActiveBuilder.createURLElements(fromText: textString, range: textRange)
        activeElements[.URL]?.appendContentsOf(urlElements)
        
        //PHONE
        let phoneElements = ActiveBuilder.createPhoneNumberElements(fromText: textString, range: textRange)
        activeElements[.Phone]?.appendContentsOf(phoneElements)
    }
    
    
    /// add line break mode
    private func addLineBreak(attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributesAtIndex(0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = textAlignment
        if let lineSpacing = lineSpacing {
            paragraphStyle.lineSpacing = CGFloat(lineSpacing)
        }
        
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    private func updateAttributesWhenSelected(isSelected: Bool) {
        guard let selectedElement = selectedElement else {
            return
        }
        
        var attributes = textStorage.attributesAtIndex(0, effectiveRange: nil)
        if isSelected {
            switch selectedElement.element {
            case .URL(_), .Phone(_): attributes[NSForegroundColorAttributeName] = URLSelectedColor ?? URLColor
            case .None: ()
            }
        } else {
            switch selectedElement.element {
            case .URL(_), .Phone(_): attributes[NSForegroundColorAttributeName] = URLColor
            case .None: ()
            }
        }
        
        textStorage.addAttributes(attributes, range: selectedElement.range)
        
        setNeedsDisplay()
    }
    
    private func elementAtLocation(location: CGPoint) -> (range: NSRange, element: ActiveElement)? {
        guard textStorage.length > 0 else {
            return nil
        }
        
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRectForGlyphRange(NSRange(location: 0, length: textStorage.length), inTextContainer: textContainer)
        guard boundingRect.contains(correctLocation) else {
            return nil
        }
        
        let index = layoutManager.glyphIndexForPoint(correctLocation, inTextContainer: textContainer)
        
        for element in activeElements.map({ $0.1 }).flatten() {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
            }
        }
        
        return nil
    }
    
    
    //MARK: - Handle UI Responder touches
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, withEvent: event)
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let touch = touches?.first else { return }
        onTouch(touch)
        super.touchesCancelled(touches, withEvent: event)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, withEvent: event)
    }
    
    //MARK: - ActiveLabel handler
    private func didTapStringURL(stringURL: String) {
        guard let urlHandler = urlTapHandler, let url = NSURL(string: stringURL) else {
            delegate?.didSelectText(stringURL, type: .URL)
            return
        }
        urlHandler(url)
    }
    
    private func didTapPhoneNumber(phoneNumber: String) {
        guard let phoneHandler = phoneTapHandler else {
            delegate?.didSelectText(phoneNumber, type: .Phone)
            return
        }
        phoneHandler(phoneNumber)
    }
}

extension ActiveLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
