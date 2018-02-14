//
//  CanvasView.swift
//  Physics
//
//  Created by Adam Hodapp on 12/8/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import UIKit

class CanvasView: UIView {
    
    //The rectangle of the view based on the dimensions of the screen
    var rect : CGRect?
    //The Canvas model that this view is rendering
    var canvas : Canvas?
    override func draw(_ rect: CGRect) {
        self.rect = rect
        updateView()
    }
    //Updates the view, has each entity draw an image in their specified box
    func updateView(){
        let context = UIGraphicsGetCurrentContext()
        self.clearContext(context!, rect: self.rect!)
        if let canvas = self.canvas{
            let imagesToDisplay = canvas.getEntitiesForRendering()
            for (entity, eRect) in imagesToDisplay{
                let imageRect = CGRect(x: eRect.minX * rect!.width + rect!.minX , y: eRect.minY * rect!.height + rect!.minY, width: eRect.width * rect!.width, height: eRect.height * rect!.height)
                entity.drawImage(UIGraphicsGetCurrentContext()!, rect: imageRect)
            }
            canvas.updateEntities()
        }
        else{
            NSLog("Error, no Canvas")
        }
    }
    //Clears the canvas to a white screen, allowing it to be redrawn
    func clearContext(_ context: CGContext, rect: CGRect){
        context.setFillColor([1, 1, 1, 1])
        context.fill(rect)
    }
}
