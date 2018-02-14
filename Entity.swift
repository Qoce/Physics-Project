//
//  Entity.swift
//  Physics
//
//  Created by Adam Hodapp on 12/15/16.
//  Copyright © 2016 Adam Hodapp. All rights reserved.
//

import Foundation
import UIKit
import Charts

class Entity{
    var position : (Double, Double)
    var velocity : (Double, Double)
    let mass : Double
    var canBeOneDimensional = true
    var canAccelerate = true
    var accType = AccelerationType.eulersMethod
    var shouldDestroy = false
    let elasticity = 0.9
    var gvt = GraphViewType.none
    var values : [ChartDataEntry] = [ChartDataEntry]()
    var time = 0.0
    var graphView : LineChartView?
    init(position: (Double, Double), velocity: (Double, Double), mass: Double){
        self.position = position
        self.velocity = velocity
        self.mass = mass
    }
    func drawImage(_ context: CGContext, rect: CGRect){
        context.setFillColor([0.75, 0, 0.5, 1])
        context.fill(rect)
  //      drawVelocityVector(context, position: (Double(rect.minX + rect.maxX) / 2,(Double(rect.minY + rect.maxY) / 2)))
    }
    func drawVelocityVector(_ context: CGContext, position: (Double, Double), fillColor: CGColor, velocity: (Double, Double)){
        context.setStrokeColor(fillColor)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: position.0,y: position.1))
        path.addLine(to: CGPoint(x: position.0 + velocity.0,y: position.1 + velocity.1))
        path.addLine(to: CGPoint(x: position.0 + velocity.0 * 0.9 - 0.1 * velocity.1, y: position.1 + velocity.1 * 0.9 + 0.1 * velocity.0))
        path.addLine(to: CGPoint(x: position.0 + velocity.0,y: position.1 + velocity.1))
        path.addLine(to: CGPoint(x: position.0 + velocity.0 * 0.9 + 0.1 * velocity.1, y: position.1 + velocity.1 * 0.9 - 0.1 * velocity.0))
//        CGPathMoveToPoint(path, nil, CGFloat(position.0) ,CGFloat(position.1))
//        CGPathAddLineToPoint(path, nil, CGFloat(position.0 + velocity.0) ,CGFloat(position.1 + velocity.1))
//        CGPathAddLineToPoint(path, nil, CGFloat(position.0 + velocity.0 * 0.9 - 0.1 * velocity.1), CGFloat(position.1 + velocity.1 * 0.9 + 0.1 * velocity.0))
//        CGPathAddLineToPoint(path, nil, CGFloat(position.0 + velocity.0) ,CGFloat(position.1 + velocity.1))
//        CGPathAddLineToPoint(path, nil, CGFloat(position.0 + velocity.0 * 0.9 + 0.1 * velocity.1), CGFloat(position.1 + velocity.1 * 0.9 - 0.1 * velocity.0))

        context.addPath(path)
        
        //  CGContextClosePath(context)
        context.strokePath()

    }
    //Used by the canvas to figure out what places the entity is to be drawn on
    func getDimensions() -> CGRect{
        return CGRect(x: position.0, y: position.1, width: 2, height: 2) //TODO implement dynamic widths
    }
    func parseString(){} //Unimplemented: Generates Entity from String
    var mod = 0 //Variable used to make the graph update very N frames.
    
    //Uses Euler's method to update position, with a given acceleration
    func updatePositionWithAcceleration(_ acc : (Double, Double), time: Double){
        mod += 1
        mod %= 5
        self.time += time
        if (!canAccelerate){
            return
        }
        position.0 += velocity.0 * time
        position.1 += velocity.1 * time
        switch accType{
        case .eulersMethod:
            velocity.0 += acc.0 * time
            velocity.1 += acc.1 * time
        case .noAcc: break
        case .conserveMechEnergy(energy: _): break
        }
        if position.0.isInfinite || position.1.isInfinite{
            shouldDestroy = true
        }
        if gvt == .speed && mod == 0{
//            if values.count > 100{
//                var newValues = [ChartDataEntry]()
//                var i = 0
//                while i < values.count{
//                    newValues.append(values[i])
//                    i += 2
//                }
//                values=newValues
//            }
            values.append(ChartDataEntry(x: self.time, y: Double(sqrt((velocity.0 * velocity.0) + (velocity.1 * velocity.1)))))
            
            let data = LineChartData()
            let ds = LineChartDataSet(values: values, label: "Velocity")
            
            ds.mode = .linear
            ds.drawCirclesEnabled = false
            
            data.addDataSet(ds)
            
            graphView!.data = data
            
        }
    }
    //Detects a collision with another entity based on the entities coordinates.
    //Implemented by the subclasses of entity
    func isCollidingWith(_ e: Entity) -> Bool{
        return false
    }
    //React to a collision with an entity once it occurs, what exactly happens here depends on the objects colliding. If a ball bounces off of a ramp, for example, the ramp will not move if it is set not to accelerate. If two balls hit eachother they will bounce in a way that conserves momentum, and if the collision is inelastic some energy will be lost, but momentum will still be conserved.
    func collideWith(_ e: Entity){}
    //Used to make collision detection more effecient.
    func getSquareLocationOnCanvas(_ canvasSize: (Double, Double)) -> (CountableRange<Int>, CountableRange<Int>){
        return (0..<1,0..<1)
    }
   
    //Collides elastically with the other entity
    func elasticlyCollideWith(_ e: Entity){
        
        let surfaceVector = (position.1 - e.position.1, e.position.0 - position.0)
        let normal = getNormalComponent(velocity, onto: surfaceVector)
        let eNormal = getNormalComponent(e.velocity, onto: surfaceVector)
        if e.position.1 >= position.1{
            if normal.1 <= eNormal.1{
                return
            }
        }
        else{
            if normal.1 >= eNormal.1{
                return
            }
        }
        
        var normalLength = abs(normal)
        var eNormalLength = abs(eNormal)
        if normal.0 < 0{
            normalLength *= -1
        }
        if eNormal.0 < 0{
            eNormalLength *= -1
        }
        let normalFLength = (normalLength * (mass - e.mass) + (eNormalLength * 2 * e.mass)) / (mass + e.mass)
        let eNormalFLength = (eNormalLength * (e.mass - mass) + (normalLength * 2 * mass)) / (mass + e.mass)
        let tangent = getTangentialComponent(velocity, onto: surfaceVector)
        let eTangent = getTangentialComponent(e.velocity, onto: surfaceVector)
        self.velocity = (tangent.0 + normal.0 * (normalFLength / normalLength), tangent.1 + normal.1 * (normalFLength / normalLength))
        e.velocity = (eTangent.0 + eNormal.0 * (eNormalFLength / eNormalLength), eTangent.1 + eNormal.1 * (eNormalFLength / eNormalLength))
        
    }
    //Returns the vector "a" projected onto the vector "onto"
    func getTangentialComponent(_ a: (Double, Double), onto: (Double, Double)) -> (Double, Double){
        let multiplier = (a.0 * onto.0 + a.1 * onto.1)/(onto.0 * onto.0 + onto.1 * onto.1)
        return (multiplier * onto.0, multiplier * onto.1)
    }
    //Returns the vector a projected onto the normal vector of onto
    func getNormalComponent(_ a: (Double, Double), onto: (Double, Double)) -> (Double, Double){
        let tan = getTangentialComponent(a, onto: onto)
        return (a.0 - tan.0, a.1 - tan.1)
    }
    //Returns magnitude of avector
    func abs(_ v: (Double, Double)) -> Double{
        return sqrt(v.0 * v.0 + v.1 * v.1)
    }
    
}
enum AccelerationType {
    case eulersMethod //Uses Eueler's Method for approximating differential equations to approximate the position of each object for each successive tick
    case conserveMechEnergy(energy : Double) //Unimplemented: Uses
    case noAcc //Object cannot accelerate
}
enum GraphViewType{
    case none
    case xVel
    case yVel
    case speed
    case bothVel
    
}
