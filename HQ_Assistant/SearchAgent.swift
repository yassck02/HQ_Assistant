//
//  SearchAgent.swift
//  HQ_Assistant
//
//  Created by Connor yass on 1/14/18.
//  Copyright © 2018 Connor yass. All rights reserved.
//

import Foundation

class SearchAgent {
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	static var instanceCount = 0
	static var searchCount = 0
	static var succesfullSearchCount = 0
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	var delegate: Solver!
	
	private var ID: Int!
	
	private var searchJob: SearchJob?
	
	private var processJobs = [ProcessJob]()
	
	init(id: Int, delegate: Solver) {
		self.ID = id
		self.delegate = delegate
		SearchAgent.instanceCount += 1
		print("Agent \(ID!) spawned. count: \(SearchAgent.instanceCount)")
	}
	
	deinit {
		SearchAgent.instanceCount -= 1
		print("Agent \(ID!) destroyed. count: \(SearchAgent.instanceCount)")
		delegate.lostAgent()
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	public func load(searchJob: SearchJob, processJobs: [ProcessJob]){
		self.searchJob = searchJob
		self.processJobs = processJobs
	}
	
	
	public func execute() {
		if(searchJob == nil){
			print("ERROR: Agent \(ID!): No search job to execute")
			Solver.errorCount += 1;
		} else {
			switch searchJob!.type {
			case .google_api:
				search_Google_api(searchJob!.strings)
			case .google_url:
				search_Google_url(searchJob!.strings)
			case .link:
				search_Link(searchJob!.strings.first!)
			default:
				print("")
			}
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// MARK: Search
	
	// The number of seconds to wait for a response when perfoming a search
	private var searchTimeout = 3.0;
	
	// The number of pages to search through (Google URL search)
	private var pageSearchCount = 1;
	
	// Makes a search call to the Google API
	private func search_Google_api(_ searchStrings: [String]) {
		
		print("Agent \(ID!): Performing Google Search (API call). terms: \(searchJob!.strings!)")
		
		if(searchStrings.isEmpty) {
			print("ERROR: Agent \(ID!): Attempting google search without a string to search for")
			Solver.errorCount += 1;
			return
		} else {
			let apiKey = "AIzaSyBi-WJXkdbe0ifGP2tFjCTDTADVXpkyGgA"
			let apiEndPoint = "https://www.googleapis.com/customsearch/v1?"
			let cx = "016600630919877572523:3oacbaizxf4"
			let numResults = "10"
			
			var query = String()
			for string in searchStrings {
				query.append(string)
				query.append("+")
			}
			query.removeLast()
			
			let urlString = apiEndPoint + "&key=" + apiKey + "&cx=" + cx + "&num=" + numResults + "&q=" + query
			
			guard let url = URL(string: urlString) else {
				print("ERROR: Agent \(self.ID!): Attempting Google API Search with invalid URL")
				Solver.errorCount += 1
				return
			}
			
			let session = URLSession.shared
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.timeoutInterval = searchTimeout
			
			let task = session.dataTask(with: url, completionHandler: recievedJSON)
			SearchAgent.searchCount += 1
			task.resume();
		}
	}

	// Searches Google by constructing a URL with google.com/search as the base
	// Spawns mutiple other search agents to search the subsequent pages
	private func search_Google_url(_ searchStrings: [String]) {
		
		print("Agent \(ID!): Performing Google Search (URL). terms: \(searchJob!.strings!)")
		
		var baseLink = "https://www.google.com/search?q="
		for string in searchStrings {
			baseLink.append(string)
			baseLink.append("+")
		}
		baseLink.removeLast()
		
		search_Link(baseLink)
		
		/*if(pageSearchCount >= 2){
			// spawn new agents to search the other pages
			for i in 2...pageSearchCount {
				let newLink = baseLink + "&start=\(i*10)"
				delegate.spawnAgent(searchType: .link, searchStrings: [newLink], processjobs: processJobs)
				search_Link(baseLink + "&start=10")
			}
		}*/
	}
	
	// Retrieves the hypertext from the given URL (link)
	private func search_Link(_ link: String) {
		
		print("Agent \(ID!): Performing Link Search. link: \(link)")

		if let url = URL(string: link) {
			
			let session = URLSession.shared
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			request.timeoutInterval = searchTimeout
			
			let task = session.dataTask(with: url, completionHandler: recievedHypertext)
			SearchAgent.searchCount += 1;
			task.resume();
			
		} else {
			print("ERROR: Agent \(ID!) - Attempting Link Search with an invalid url: \(link)")
			Solver.errorCount += 1;
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// MARK: Recieve
	
	// Completion handler for when a JSON response is recieved from a Google API call
	private func recievedJSON(data: Data?, response: URLResponse?, error: Error?) -> Void {
		
		print("Agent \(ID!): Retrieved google search")
		
		if error != nil {
			print("ERROR: Agent \(ID!) - Google api call failed: ", error!)
			Solver.errorCount += 1;
			return
		}
		
		if response == nil {
			print("ERROR: Agent \(ID!) - Google api call failed: response == nil")
			Solver.errorCount += 1;
			return
		}
		
		SearchAgent.succesfullSearchCount += 1
		
		do {
			let dictionary = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
			if let results = dictionary["items"] as? [[String: Any]] {
				
				processJSON(results, searchLinks: true)
				
				return
			} else {
				print("ERROR: Agent \(ID!) - Could not extract 'items' subdictionary from google api call response")
				Solver.errorCount += 1;
				return
			}
		} catch let error {
			print("ERROR: Agent \(ID!) - Could not serialize jSON Data from google api call response: \(error.localizedDescription)")
			Solver.errorCount += 1;
			return
		}
	}
	
	// Completion handeler for when hypertext is recieved (link search, Google URL Search)
	private func recievedHypertext(data: Data?, response: URLResponse?, error: Error?) -> Void {
		
		if error != nil {
			print("ERROR: Agent \(ID!) - Hypertext search failed: ", error!)
			Solver.errorCount += 1;
			return
		}
		
		if response == nil {
			print("ERROR: Agent \(ID!) - Hypertext search failed: response == nil")
			Solver.errorCount += 1;
			return
		}
		
		if(data!.count < 5000){
			print("ERROR: Agent \(ID!) - Google search error...")
			Solver.errorCount += 1;
			//return
		}
		
		SearchAgent.succesfullSearchCount += 1
		
		print("Agent \(ID!): Retrieved hypertext: \(data!)")
	
		if let string = String(data: data!, encoding: .ascii) {
			//print(string)
			processHypertext(string)
		} else {
			print("ERROR: Agent \(ID!) - Hypertext could not be converted to string")
			Solver.errorCount += 1;
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// MARK: Process
	
	// The number of links to search
    private let linkSearchCount = 2
	
	// Processes the JSON dictionary by running each of this agent's process jobs on it
	private func processJSON(_ results: [[String: Any]], searchLinks: Bool) {
		print("Agent \(ID!): Processing google search. jobs: \(processJobs.count)")
		
		if results.isEmpty {
			print("ERROR: Agent \(ID!) - No google search results to process")
			Solver.errorCount += 1;
			return
		}
		
		if processJobs.isEmpty {
			print("ERROR: Agent \(ID!) - Cannot process google search. No processJobs")
			Solver.errorCount += 1;
			return
		}
		
		for (i, item) in results.enumerated() {
			if let snippit = item["snippet"] as? String {
				for job in processJobs {
					
					let count = snippit.countSubstring(substring: job.term)
					delegate.choiceRanks[job.choiceIndex] += (count * job.weight)
					print("> Agent \(ID!) - Processing job on JSON \(i+1) of \(processJobs.count) - [\(job.term!)] count: \(count)")

				}
			} else {
				print("ERROR: Agent \(ID!) - Could not read google search result item description")
				Solver.errorCount += 1;
			}
			
			if searchLinks == true {
				if i < linkSearchCount {
					if let link = item["link"] as? String {
				
						delegate.spawnAgent(searchType: .link, searchStrings: [link], processjobs: processJobs)
						
					} else {
						print("ERROR: Agent \(ID!) - Could not read google search result item link")
						Solver.errorCount += 1;
					}
				}
			}
		}
	}
	
	// Processes the Hypertext by running each of this agent's process jobs on it
	private func processHypertext(_ result: String?) {
		print("Agent \(ID!): Processing Hypertext. jobs: \(processJobs.count)")
		
		if result == nil {
			print("ERROR: Agent \(ID!) - No hypertext search results to process")
			Solver.errorCount += 1;
			return
		}
		
		if processJobs.isEmpty {
			print("ERROR: Agent \(ID!) - Cannot process hypertext search. No jobs to process")
			Solver.errorCount += 1;
			return
		}

		for (i, job) in processJobs.enumerated() {
			
			let count = result!.countSubstring(substring: job.term!)
			let weightedCount = count * job.weight!
			delegate.choiceRanks[job.choiceIndex] += weightedCount
			print("> Agent \(ID!) - Processing job on hypertext \(i+1) of \(processJobs.count) - (weight: \(job.weight!)) - [\(job.term!)] count: \(count)")
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}
