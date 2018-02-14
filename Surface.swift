//
//  Surface.swift
//  Physics
//
//  Created by Adam Hodapp on 1/9/17.
//  Copyright © 2017 Adam Hodapp. All rights reserved.
//

import Foundation
import UIKit

// Surface class. This is an entity that has a velocity of zero and cannot accelerate. An example of a surface would be the "ground" or a "ramp". Will only display correctly if the verticies are "simplistic". If it is a complicated concave polygon for which there is no direction where it passes the "verticle line test" then it will not be displayed correctly.
class Surface : SolidEntity{
    override init(vertices : [(Double, Double)], position: (Double, Double), mass: Double) {
        super.init(vertices: vertices, position: position, mass: mass)
        super.accType = .noAcc
    }
}
