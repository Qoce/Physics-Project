//
//  CircularEntity.swift
//  Physics
//
//  Created by Adam Hodapp on 3/1/17.
//  Copyright © 2017 Adam Hodapp. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

//Circular Objects
class CircularEntity : Entity{
    var radius : Double //Radius of the circle
    var lastCollisionWithSolid : Any? //Last entity it collided with. Determines which collison response method to use.
    init(position: (Double, Double), velocity: (Double, Double), mass: Double, radius: Double){
        self.radius = radius
        super.init(position: position, velocity: velocity, mass: mass)
    }
    //Draws Circle onto screen using fill elipse
    override func drawImage(_ context: CGContext, rect: CGRect) {
        context.setFillColor([0,0,1,1])
        if self.gvt != .none{
            context.setFillColor([1,0,0,1])
        }
        context.fillEllipse(in: rect)
        drawVelocityVector(UIGraphicsGetCurrentContext()!, position: (Double(rect.minX + rect.width / 2), Double(rect.minY + rect.height/2)), fillColor: UIColor.green.cgColor, velocity: velocity)

    }
    override func isCollidingWith(_ e: Entity) -> Bool {
        //If the other object is a circle determine if the distance between the two centers is greater than the sum of the radii of the two circles
        if let circle = e as? CircularEntity{
            if getSquareOfPointDistance(e.position, p2: position) <= pow(radius + circle.radius, 2.0){
                return true
            }
        }
        //Otherwise, if the object is a polygon determine if the circle is colliding with any of the line segmenents on the polygon
        else if let solid = e as? SolidEntity{
            for lineSegment in solid.getSideVectors(){
                let dist = lineSegment.getDistanceFromPoint(self.position)
                if  dist.0 < radius {
                    if dist.1 == -1{
                        lastCollisionWithSolid = lineSegment.point
                    }
                    else if dist.1 == 1{
                        lastCollisionWithSolid = (lineSegment.point.0 + lineSegment.vector.0, lineSegment.point.1 + lineSegment.vector.1)
                    }
                    else if dist.1 == 0{
                        lastCollisionWithSolid = lineSegment
                    }
                    return true
                }
            }
        }
        return false
    }
    //Returns the square of the distance of two points. More effeicent to do this than to calculate tehe actual distance because it avoids calculating the square root.
    func getSquareOfPointDistance(_ p1 : (Double, Double), p2 : (Double, Double)) -> Double{
        let dX = p1.0 - p2.0
        let dY = p1.1 - p2.1
        return dX * dX + dY * dY
    }
    //Returns the smallest square which the circle fits within
    override func getSquareLocationOnCanvas(_ canvasSize: (Double, Double)) -> (CountableRange<Int>, CountableRange<Int>){
        let minX = Int(floor(10 * (position.0 - radius) / canvasSize.0))
        let maxX = Int(floor(10 * (position.0 + radius) / canvasSize.0))
        let minY = Int(floor(10 * (position.1 - radius) / canvasSize.1))
        let maxY = Int(floor(10 * (position.1 + radius) / canvasSize.1))
        return(minX..<maxX + 1, minY..<maxY + 1)
    }
    override func collideWith(_ e: Entity){
        //If this entity cannot accelerate, than let the code in e determine the outcome of the collision.
        if !canAccelerate{
            e.collideWith(self)
        }
        if !e.canAccelerate{
            if e is CircularEntity{
                bounceOffOfSurface((position.1 - e.position.1, e.position.0 - position.0))
            }
            else if e is SolidEntity{
                if let lineSegment = lastCollisionWithSolid as? LineSegment{
                    //The line segment the circle collided with
                    let y = lineSegment.getPointYValue(x: position.0, y: position.1)
                    //If the circle is already moving away from the obejct it collided with. Do nothing.
                    //This avoids inaccuacies with Euler's method causing the circle to get stuck in a nother object, repeated bouncing inside of it.
                    if y > position.1{
                        if velocity.1 < 0{
                            return
                        }
                    }
                    else if y < position.1{
                        if velocity.1 > 0{
                            return
                        }
                    }
                    else{
                        if position.0 > lineSegment.point.0{
                            if velocity.0 > 0{
                                return
                            }
                        }
                        else if position.0 < lineSegment.point.0{
                            if velocity.0 < 0{
                                return
                            }
                        }
                    }
                    bounceOffOfSurface(lineSegment.vector)
                }
                else if let point = lastCollisionWithSolid as? (Double, Double){
                    bounceOffOfSurface((position.1 - point.1, point.0 - position.0))
                }
            }
        }
        else{
            elasticlyCollideWith(e) //Do elastic collision if both objects can accelerate.
        }
            
    }
    //Bounces off of an immovable surface. Makes sure exit angle equals enterance angle.
    func bounceOffOfSurface(_ surfaceVector: (Double, Double)){
        let multiplier = (surfaceVector.0 * velocity.0 + surfaceVector.1 * velocity.1)/(surfaceVector.0 * surfaceVector.0 + surfaceVector.1 * surfaceVector.1)
        let velocityChange = (velocity.0 - multiplier * surfaceVector.0, velocity.1 - multiplier * surfaceVector.1)
        self.velocity = (self.velocity.0 - 2 * velocityChange.0, self.velocity.1 - 2 * velocityChange.1)
        self.velocity = (velocity.0 * elasticity , velocity.1 * elasticity)
    }
    //Returns the minimum bounding box needed to draw the entire surface.
    override func getDimensions() -> CGRect {
        return CGRect(x: position.0 - radius,y: position.1 - radius,width: 2 * radius, height: 2 * radius)
    }
}
