//
//  SignatureViewController.swift
//  pencilKitDemo
//
//  Created by 정유진 on 2022/07/11.
//

import UIKit
import PencilKit

class SignatureViewController: UIViewController, PKCanvasViewDelegate, UIScreenshotServiceDelegate {
    
    @IBOutlet var canvasView: PKCanvasView!
    @IBOutlet var colorSwitch: UISegmentedControl!
    @IBAction func tapClearButton(_ sender: Any) {
        canvasView.drawing = PKDrawing()
    }
    @IBAction func tapSaveButton(_ sender: Any) {
        if hasModifiedSignature {
            dataModelController.updateSignatures(canvasView.drawing, at: signatureIndex)
        }
        dismiss(animated: true)
    }
    @IBAction func colorChanged(_ sender: Any) {
        let colors: [UIColor] = [.black, .blue]
        let selectedColor = colors[colorSwitch.selectedSegmentIndex]
        canvasView.tool = PKInkingTool(.pen, color: selectedColor, width: 20)
    }
    
    static let canvasOverscrollHeight: CGFloat = 0
    var dataModelController: DataModelController!
    var signatureIndex: Int = 0
    var hasModifiedSignature = false
    
    // set up the tool picker
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // set up the canvas view with the first drawing from the data model
        canvasView.delegate = self
        canvasView.drawing = dataModelController.signatures[signatureIndex]
        canvasView.alwaysBounceVertical = true
        
        // always show a back button
        navigationItem.leftItemsSupplementBackButton = true
        
        // set this view controller as the delegate for creating full screenshots
        parent?.view.window?.windowScene?.screenshotService?.delegate = self
        
    }
    
    // when the view is resized, adjust the canvas scale so that it is zoomed to the default
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let canvasScale = canvasView.bounds.width / DataModel.canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        updateContentSizeForSignature()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorChanged(self)
        canvasView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if hasModifiedSignature {
            dataModelController.updateSignatures(canvasView.drawing, at: signatureIndex)
        }
        
        // remove this view controller as the screenshot delegate
        view.window?.windowScene?.screenshotService?.delegate = nil
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // helper method to set a new drwing, with an undo action to go back to the old one
    func setNewSignatureUndoable(_ newSign: PKDrawing) {
        let oldSign = canvasView.drawing
        undoManager?.registerUndo(withTarget: self) {
            $0.setNewSignatureUndoable(oldSign)
        }
        canvasView.drawing = newSign
    }
    
    // Canvas View Delegate
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        hasModifiedSignature = true
        updateContentSizeForSignature()
    }
    
    // helper method to set a suitable content size for the canvas view
    func updateContentSizeForSignature() {
        // update the content size to match the drawing
        let signature = canvasView.drawing
        let contentHeight: CGFloat
        
        // adjust the content size to always be bigger than the drawing height
        if !signature.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (signature.bounds.maxY + SignatureViewController.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        
        canvasView.contentSize = CGSize(width: DataModel.canvasWidth * canvasView.zoomScale, height: contentHeight)
    }
    
    // toolpicker
    
    // screenshot을 pdf로 제공 
}
