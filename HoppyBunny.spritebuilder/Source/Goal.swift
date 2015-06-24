//
//  Goal.swift
//  HoppyBunny
//
//  Created by Varsha Ramakrishnan on 6/24/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import UIKit

import Foundation

class Goal: CCNode
{
    func didLoadFromCCB()
    {
        physicsBody.sensor = true;
    }
}