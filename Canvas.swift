//
//  File.swift
//  Physics
//
//  Created by Adam Hodapp on 12/19/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import Foundation
import UIKit
import Charts

class Canvas{
    var entities = [Entity]()
    let shownCoords : CGRect
    var graphView : LineChartView!
    init(shownCoords: CGRect, graphView : LineChartView){
        self.shownCoords = shownCoords
        self.graphView = graphView

//        loadBouncingScenario(shownCoords: shownCoords, graphView: graphView)
        loadRampScenario(shownCoords: shownCoords, graphView: graphView)
    }
    func loadBouncingScenario(shownCoords: CGRect, graphView : LineChartView){
        for i in 1...5{
            for j in 1...5{
                let circle = CircularEntity(position: (Double(i) * 60 + Double(j) * 5, Double(j) * 50), velocity: (Double(i + j) * 40 ,50), mass: 10, radius: 5)
                    entities.append(circle)
                if i==1 && j == 1{
                    circle.gvt = .speed
                    circle.graphView = graphView
                }
            }
        }
        
        let surfaceOne = Surface(vertices: [(0, 0), (0, 10), (400, 10), (400, 0)], position: (0, 0), mass: 0)
        surfaceOne.canAccelerate = false
        entities.append(surfaceOne)
        let surfaceTwo = Surface(vertices: [(0, 300), (0, 290), (400, 290), (400, 300)], position: (0, 0), mass: 0)
        surfaceTwo.canAccelerate = false
        entities.append(surfaceTwo)
        let surfaceThree = Surface(vertices: [(0, 0), (10, 0), (10, 300), (0, 300)], position: (0, 0), mass: 0)
           surfaceThree.canAccelerate = false
        entities.append(surfaceThree)
        let surfaceFour = Surface(vertices: [(400, 300), (400, 0), (390, 0), (390, 300)], position: (0, 0), mass: 0)
        surfaceFour.canAccelerate = false
        entities.append(surfaceFour)
    }
    func loadRampScenario(shownCoords: CGRect, graphView : LineChartView){
        let circle = CircularEntity(position: (50, 50), velocity: (0, 0),mass: 10, radius: 10)
        circle.gvt = .speed
        circle.graphView = graphView
        entities.append(circle)

        let surface = Surface(vertices: [(400, 300), (0, 300), (0, 225)], position: (0,0), mass: 0)
        surface.canAccelerate = false
        entities.append(surface)
        
    }
    func createTestEntity(_ position: (Double, Double), velocity : (Double, Double), mass: Double) -> SolidEntity{
        var verticies = [(Double, Double)]()
        verticies.append((0, 0))
        verticies.append((5, 0))
        verticies.append((5, 5))
        verticies.append((0, 5))

        let e = SolidEntity(vertices: verticies, position: position, mass: 10)
        e.velocity = velocity
        return e
    }
    func getEntitiesForRendering() -> [(Entity, CGRect)]{
        var returnValue = [(Entity, CGRect)]()
        for entity in entities{
            let x = (Double(entity.getDimensions().minX) - Double(shownCoords.minX)) / Double(shownCoords.width)
            let y = (Double(entity.getDimensions().minY) - Double(shownCoords.minY)) / Double(shownCoords.height)
            let width = (Double(entity.getDimensions().width) / Double(shownCoords.width))
            let height = (Double(entity.getDimensions().height) / Double(shownCoords.height))
            returnValue.append((entity, CGRect(x: x, y: y, width: width, height: height)))
        }
        return returnValue
    }
    var mod = 0
    func updateEntities(){
        mod += 1
        mod %= 1
        for i in 0..<entities.count{
            
          //  entity.updatePositionWithAcceleration(accelerationToPoint((200, 150), position: entity.position, pointMass: 100000), time: 0.01)
       //     entities[i].updatePositionWithAcceleration(wonkyAcc(entities[i].position), time: 0.01)
            entities[i].updatePositionWithAcceleration((0, 400), time: 0.01)
       //     entities[i].updatePositionWithAcceleration((0, 0), time: 0.01)

            if mod == 0{
                for j in i + 1..<entities.count{
                    if checkCollision(entities[i], b: entities[j]){
                        entities[i].collideWith(entities[j])
                        //entities[i].shouldDestroy = true
                        //entities[j].shouldDestroy = true
                    }
                }
            }
        }
        entities[entities.count - 1].shouldDestroy = false
        entities = entities.filter() { !$0.shouldDestroy }
    }
    
    
    func wonkyAcc(_ position : (Double, Double)) -> (Double, Double){
        let distX = abs(position.0) > abs(400 - position.0) ? position.0 - 400 : position.0
        let xAcc = 100000 / (distX * abs(distX))
        let distY = abs(position.1) > abs(300 - position.1) ? position.1 - 300 : position.1
        let yAcc = 100000 / (distY * abs(distY))
        return (xAcc, yAcc)
    }
    
    func accelerationToPoint(_ point: (Double, Double), position: (Double, Double), pointMass: Double) -> (Double, Double){
        let BA = (point.0 - position.0, point.1 - position.1)
        let magBA = pow(BA.0 * BA.0 + BA.1 * BA.1, 1.5)
        return (pointMass * BA.0 / magBA, pointMass * BA.1 / magBA)
    }
    //Checks to see if the entities are close and could possibly colliding, and then performs more intensive checks by attmepting to draw a line between the entity and the other entity
    var total = 0.0
    var totalChecked = 0.0
    func checkCollision(_ a : Entity, b : Entity) -> Bool{
        total += 1
        let aRange = a.getSquareLocationOnCanvas((Double(shownCoords.width), Double(shownCoords.height)))
        let bRange = b.getSquareLocationOnCanvas((Double(shownCoords.width), Double(shownCoords.height)))
        if (aRange.0.lowerBound >= bRange.0.lowerBound && aRange.0.lowerBound <= bRange.0.upperBound) || (aRange.0.upperBound >= bRange.0.lowerBound && aRange.0.upperBound <= bRange.0.upperBound){
             if (aRange.1.lowerBound >= bRange.1.lowerBound && aRange.1.lowerBound <= bRange.1.upperBound) || (aRange.1.upperBound >= bRange.1.lowerBound && aRange.1.upperBound <= bRange.1.upperBound){
                totalChecked += 1
                return a.isCollidingWith(b)
            }
        }
        return false
    }
}
