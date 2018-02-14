//  ViewController.swift
//  Physics
//
//  Created by Adam Hodapp on 12/8/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController {
    var canvasView : CanvasView!
    var lineGraphView : LineChartView!
    override func viewDidLoad() {
        super.viewDidLoad()
      //   Initializes the CanvasView and a Canvas, right now just creates a blank canvas...
        let frame = self.view.bounds
        canvasView = CanvasView(frame: frame)
        lineGraphView = LineChartView()
        canvasView.canvas = Canvas(shownCoords : CGRect(x: 0, y: 0, width: 400, height: 300), graphView: lineGraphView)
        self.view.addSubview(canvasView)
        canvasView.frame = CGRect(x: frame.minX,y: frame.minY, width: frame.width, height: frame.height * 0.75)
        lineGraphView.frame = CGRect(x: frame.minX,y: frame.minY + frame.height * 0.75, width: frame.width, height: frame.height * 0.25)
      
        canvasView.addSubview(lineGraphView)
        canvasView.canvas!.graphView = lineGraphView
        
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.updateTimer), userInfo: nil, repeats: true)
        view.setNeedsDisplay()
     
    }
    func updateTimer(){
        self.canvasView.setNeedsDisplay()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
