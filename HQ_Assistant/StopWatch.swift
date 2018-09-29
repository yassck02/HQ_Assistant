//
//  StopWatch.swift
//  HQ_Assistant
//
//  Created by Connor yass on 1/4/18.
//  Copyright © 2018 Connor yass. All rights reserved.
//

import Foundation
import CoreFoundation

class StopWatch {
	
	var startTime: CFAbsoluteTime?
	var endTime: CFAbsoluteTime?
	
	func start() {
		startTime = CFAbsoluteTimeGetCurrent()
	}
	
	func stop() {
		endTime = CFAbsoluteTimeGetCurrent()
	}
	
	func reset(){
		startTime = nil
		endTime = nil
	}
	
	func display() {
		if(endTime != nil && startTime != nil) {
			let elapsedTime = endTime! - startTime!
			print("Elapsed time: \(elapsedTime) seconds")
		}
	}
	
}
