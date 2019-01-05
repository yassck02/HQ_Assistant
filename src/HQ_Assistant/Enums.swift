//
//  Enums.swift
//  HQ_Assistant
//
//  Created by Connor yass on 1/14/18.
//  Copyright © 2018 Connor yass. All rights reserved.
//

import Foundation

enum SearchType {
	
	// Make a call to a google api -> results = JSON
	case google_api
	
	// Searches google using a hyperlink -> results = hypertext
	case google_url
	
	// Retrieve hypertext from a link -> results = hypertext
	case link
}

struct SearchJob {
	
	init(type: SearchType, strings: [String]){
		self.type = type
		self.strings = strings
	}
	
	// The type of job
	var type: SearchType!
	
	// The string related to the job (could be a URL or search terms)
	var strings: [String]!
}

struct ProcessJob {
	
	init(term: String, choiceIndex: Int, weight: Int) {
		self.term = term
		self.choiceIndex = choiceIndex
		self.weight = weight
		print("Creating process job: [\(term)] i = \(choiceIndex), weight = \(weight)")
	}
	
	// The term to process the results with
	var term: String!
	
	// The choice index to tabulate the results for
	var choiceIndex: Int!
	
	// The amount of weight to apply when tabulating this result
	var weight: Int!
	
}
