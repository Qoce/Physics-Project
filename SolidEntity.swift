//
//  SolidEntity.swift
//  Physics
//
//  Created by Adam Hodapp on 2/9/17.
//  Copyright © 2017 Adam Hodapp. All rights reserved.
//

import Foundation
import UIKit

class SolidEntity : Entity{
    let vertices : [(Double, Double)] //General location of the vertices, stays constant
    var rotatedVertices : [(Double, Double)] //Location of the vertices when rotated, but not moved
    var adjustedVertices : [(Double, Double)] //Actual location of vertices on Canvas used for drawing
    var normalVectors : [(Double, Double)] = [] //Normal vectors to every line segment
    var coordinateRect : CGRect //The smallest rectangle the objcet fits in.
    
    init(vertices : [(Double, Double)], position: (Double, Double), mass: Double){
        self.vertices = vertices
        self.adjustedVertices = vertices
        self.rotatedVertices = vertices
        //Calibrates the rect to be the smallest axis aligned rectangle that contians the entire surface.
        var minX = 100000.0, maxX = 0.0, minY = 10000.0, maxY = 0.0
        
        for vert in vertices{
            if vert.0 > maxX {
                maxX = vert.0
            }
            if vert.0 < minX{
                minX = vert.0
            }
            if vert.1 > maxY {
                maxY = vert.1
            }
            if vert.1 < minY{
                minY = vert.1
            }
        }
        self.coordinateRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        super.init(position: position, velocity: (0, 0), mass: mass)
       
    }
    func updateCoordRect(){
        //Calibrates the rect to be the smallest axis aligned rectangle that contians the entire surface.
        var minX = 100000.0, maxX = 0.0, minY = 10000.0, maxY = 0.0
        
        for vert in adjustedVertices{
            if vert.0 > maxX {
                maxX = vert.0
            }
            if vert.0 < minX{
                minX = vert.0
            }
            if vert.1 > maxY {
                maxY = vert.1
            }
            if vert.1 < minY{
                minY = vert.1
            }
        }
        self.coordinateRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

    }
    //Fills the polygon specified by the verticies
    override func drawImage(_ context: CGContext, rect: CGRect){
        
        // NSLog("\(coordinateRect)")
        context.setFillColor([0, 0, 1, 1])
        let path = CGMutablePath()
        let vertices = adjustedVertices
        path.move(to: CGPoint(x: rect.minX + (CGFloat(vertices[vertices.count - 1].0) - coordinateRect.minX) / coordinateRect.width * rect.width,y: rect.minY + (CGFloat(vertices[vertices.count - 1].1) - coordinateRect.minY) / coordinateRect.height * rect.height))
   //     CGPathMoveToPoint(path, nil, rect.minX + (CGFloat(vertices[vertices.count - 1].0) - coordinateRect.minX) / coordinateRect.width * rect.width ,rect.minY + (CGFloat(vertices[vertices.count - 1].1) - coordinateRect.minY) / coordinateRect.height * rect.height)
        for vert in vertices{
            path.addLine(to: CGPoint(x: rect.minX + (CGFloat(vert.0) - coordinateRect.minX) * rect.width / coordinateRect.width, y: rect.minY + (CGFloat(vert.1) - coordinateRect.minY) * rect.height / coordinateRect.height))
            
        }
        //CGPathMoveToPoint(path, nil, 0, 0)
        //CGPathAddLineToPoint(path, nil, 400, 0)
        //CGPathAddLineToPoint(path, nil, 400, 300)
        //CGPathAddLineToPoint(path, nil, 0, 0)
        context.addPath(path)
        
        //  CGContextClosePath(context)
        context.fillPath()
        
    }
    //Returns the minimum bounding box needed to draw the entire surface.
    override func getDimensions() -> CGRect {
        return coordinateRect
    }
    //Detects a collision with another entity based on the entities coordinates.
    //Implemented by the subclasses of entity
    override func isCollidingWith(_ e: Entity) -> Bool{
        
        var normals = getLineVectors()
        //Uses the fact that two conves entites are not colliding only if for every line on either polygon a line perpendicular to that line can be drawn in between the two polygons without intersecting either
        if let entity = e as? SolidEntity{
            normals += entity.getLineVectors()
           
            for normal in normals{
                let ourEx = getExtremeVertices((0,0), axisVector: normal)
                let theirEx = entity.getExtremeVertices((0,0), axisVector: normal)
                if ourEx.1 < theirEx.0 || theirEx.1 < ourEx.0{
                    return false
                }
            }
           
            return true
        }
        if e is CircularEntity{
            return e.isCollidingWith(self)
        }
        return false
    }
    //Returns the normal vectors of all of the lines of this polygon.
    func getLineVectors() -> [(Double, Double)]{
        if normalVectors.count > 0 {
            return normalVectors
        }
        var normals = [(Double, Double)]()
        for i in 0..<adjustedVertices.count{
            let next = i + 1 < adjustedVertices.count ? i + 1 : 0
            let difference = (adjustedVertices[next].0 - adjustedVertices[i].0, adjustedVertices[next].1 - adjustedVertices[i].1)
            normals.append(difference)
        }
        return normals
    }
    //Rotates vertices and runs Euler's method
    override func updatePositionWithAcceleration(_ acc: (Double, Double), time: Double) {
        super.updatePositionWithAcceleration(acc, time: time)
        var newAdjVerts = [(Double, Double)]()
        let rotation = 0.0//CACurrentMediaTime() % 12.0
        rotatedVertices = getRotatedVerticesAbout((0,0), dRadians: rotation * 2.0 * .pi / 12.0)
        for vert in rotatedVertices{
            newAdjVerts.append((vert.0 + position.0, vert.1 + position.1))
        }
        adjustedVertices = newAdjVerts
        

        normalVectors = []
    }
    //Returns the extreme vertices based on the normal normal vectors. If the vector orthagonal to the normal vector was an axis, it returns the points with the greatest and least coordinates when projected onto that axis (it returns their distance from hte reference coord when they are projected onto the axis). The reference coord is used so that when this is called on two "almost colliding" entities, they will be able to compare their vercities to eachother.
    func getExtremeVertices(_ referenceCoord: (Double, Double), axisVector : (Double, Double)) -> (Double, Double){
        var largestDistance = -1000000.0
        var smallestDistance = 1000000.0
        
        for vert in adjustedVertices{
            let projecteeVector = (vert.0 - referenceCoord.0, vert.1 - referenceCoord.1)
            let dotProduct = projecteeVector.0 * axisVector.0 + projecteeVector.1 * axisVector.1
            let distance = dotProduct / sqrt(axisVector.0 * axisVector.0 + axisVector.1 * axisVector.1)
            if distance > largestDistance{
                largestDistance = distance
            }
            if distance < smallestDistance{
                smallestDistance = distance
            }
        }
      //  NSLog("\(largestDistance), \(smallestDistance)")
        return (smallestDistance, largestDistance)
    }
    //Rotates the verticies about a point, does not change the adjusted verticies because this method is to be called before a change in position.
    func getRotatedVerticesAbout(_ point: (Double, Double), dRadians: Double) -> [(Double, Double)]{
        var newVerticies = [(Double, Double)]()
        for vert in vertices{
            let difference = (vert.0 - point.0, vert.1 - point.1)
            var currentRadians = 0.0
            if difference.0 != 0{
                currentRadians = atan(difference.1 / difference.0)
            }
            else if difference.1 > 0{
                currentRadians = Double.pi / 2.0
            }
            else if difference.1 < 0{
                currentRadians = 1.5 * Double.pi
            }
            let adjustedPolar = (currentRadians + dRadians, sqrt(difference.0 * difference.0 + difference.1 * difference.1))
            
            newVerticies.append((cos(adjustedPolar.0) * adjustedPolar.1, sin(adjustedPolar.0) * adjustedPolar.1))
           
            
        }
        return newVerticies
    }
    //Returns all of the vectors representing the sides of the polygon.
    func getSideVectors() -> [LineSegment]{
        var array = [LineSegment]()
        for i in 0..<vertices.count-1{
            array.append(LineSegment(from: adjustedVertices[i], to: adjustedVertices[i+1]))
        }
        array.append(LineSegment(from: adjustedVertices[adjustedVertices.count-1],to: adjustedVertices[0]))
        return array
    }
    //Finds the square of the canvas the that the entity fits in. Used to make collision detection more effecient.
    override func getSquareLocationOnCanvas(_ canvasSize: (Double, Double)) -> (CountableRange<Int>, CountableRange<Int>) {
        var bigX = 0
        var bigY = 0
        var smallX = 9
        var smallY = 9
        for vert in adjustedVertices{
            let x = Int(floor(10.0 * (vert.0 / canvasSize.0)))
            let y = Int(floor(10.0 * (vert.1 / canvasSize.1)))
            if x > bigX{
                bigX = x
            }
            if x < smallX{
                smallX = x
            }
            if y > bigY{
                bigY = y
            }
            if y < smallY{
                smallY = y
            }
        }
        
        return (smallX..<bigX + 1, smallY..<bigY + 1)
    }
    override func collideWith(_ e: Entity) {
        if !canAccelerate && e.canAccelerate{
            e.collideWith(self)
        }
        else if e.canAccelerate{
            if e is CircularEntity{
                e.collideWith(self)
            }
        }
    }
}
//Line segment which is used for collisiosn detection to determine of the two lines collide
struct LineSegment{
    let point : (Double, Double)
    let vector : (Double, Double)
    init(from : (Double, Double), to : (Double, Double)){
        point = from
        vector = (to.0 - from.0, to.1 - from.1)
    }
    static func isIntersecting(_ l1 : LineSegment, l2 : LineSegment) -> Bool{
        
        return false
    }
    //Retuns true if the point is between the two normal lines to this line segment that are drawn at the head and the tail of the segment. 0 if in the inside, negative one if closer to the first tail, one if closer to the head
    func isPointToSide(_ p : (Double, Double)) -> Int{
        let translatedPoint = (p.0 - point.0, p.1 - point.1)
        let dotProduct = translatedPoint.0 * vector.0 + translatedPoint.1 * vector.1
        let selfProduct = vector.0 * vector.0 + vector.1 * vector.1
        //The magnitude of the distance of the projected point from the head of this vector
        let projectionMultiplier = dotProduct / selfProduct
        if projectionMultiplier > 1{
            return 1
        }
        else if projectionMultiplier < 0{
            return -1
        }
        else{
            return 0
        }
        
    }
    //Returns the distance of this line segment from the point, and wheather it was closests to an endpoint or the line itself
    func getDistanceFromPoint(_ p: (Double, Double)) -> (Double, Int){
        let side = isPointToSide(p)
        if side == 0{
            if vector.0 == 0{
                return (abs(p.0 - point.0), side)
            }
            let slope = vector.1 / vector.0
            return (abs(p.1 - slope * p.0 + slope * point.0 - point.1) / sqrt(1 + slope * slope), side)
        }
        if side == -1{
            let difference = (p.0 - point.0, p.1 - point.1)
            return (sqrt(difference.0 * difference.0 + difference.1 * difference.1), side)
        }
        else if side == 1{
            let difference = (p.0 - (point.0 + vector.0), p.1 - (point.1 + vector.1))
            return (sqrt(difference.0 * difference.0 + difference.1 * difference.1), side)
        }
        return (10000, side)
    }
    func getPointYValue(x: Double, y: Double) -> Double{
        if vector.0 == 0{
            return y
        }
        return point.1 + (x - point.0) * vector.1 / vector.0
    }
}
