//
//  AgentManager.swift
//  HQ_Assistant
//
//  Created by Connor yass on 1/14/18.
//  Copyright © 2018 Connor yass. All rights reserved.
//

import Foundation

class Solver {
	
	static var errorCount = 0
	
	public var question = [String]()
	
	public var choices = [[String]]()
	
	public var choiceRanks = [Int]()
	
	private var stopwatch = StopWatch()
	
	private var I = [ "the", "a", "it", "by", "in", "at",
	                  "here", "there", ]
	
	public func reset() {
		stopwatch.reset()
		choiceRanks.removeAll()
		choices.removeAll()
		question.removeAll()
		spawnCount = 0;
	}
	
	public func solve() {
		
		stopwatch.start()
		
		var tempJob: ProcessJob!
		
		// Convert the quesiton to a single string (for extracting keywords and lemmatizing)
		var questionString = String()
		for word in question {
			questionString.append(word)
			questionString.append(" ")
		}
		
		// Extract the key words from the question
		let keyWords = questionString.extractWords(types: [.noun, .number, .personalName, .placeName, .organizationName])
		print("Keywords: ", keyWords)
		
		// Create the choice process jobs for each choice including lemmas
		var jobs1 = [ProcessJob]()
		for (i, choice) in choices.enumerated() {
			
			var choiceString = String()
			for word in choice {
				choiceString.append(word)
				choiceString.append(" ")
			}
			choiceString.removeLast()
			
			tempJob = ProcessJob(term: choiceString, choiceIndex: i, weight: 100)
			jobs1.append(tempJob)
			
			if(choiceString.lowercased() != choiceString){
				tempJob = ProcessJob(term: choiceString.lowercased(), choiceIndex: i, weight: 100)
				jobs1.append(tempJob)
			}
			
			for word in choice {
				if(word != choiceString){
					tempJob = ProcessJob(term: word, choiceIndex: i, weight: 2)
					jobs1.append(tempJob)
					if let lemma = word.lemmatize().first {
						if lemma.lowercased() != word.lowercased() && question.contains(lemma) == false {
							tempJob = ProcessJob(term: lemma, choiceIndex: i, weight: 1)
							jobs1.append(tempJob)
						}
					}
				}
			}
		}
	
		// Search [whole question], process [each word of each choice]
		spawnAgent(searchType: .google_url, searchStrings: question, processjobs: jobs1)
		
		// Search [each choice], process [each key word fom question]
		for (i, choice) in choices.enumerated() {
			var jobs2 = [ProcessJob]()
			for  word in keyWords {
				let job = ProcessJob(term: word, choiceIndex: i, weight: 1)
				jobs2.append(job)
				if let lemma = word.lemmatize().first {
					if lemma != word {
						tempJob = ProcessJob(term: lemma, choiceIndex: i, weight: 1)
						jobs2.append(tempJob)
					}
				}
			}
			spawnAgent(searchType: .google_url, searchStrings: choice, processjobs: jobs2)
		}
		
		// Search [all keywords from question together], process [each word of each choice]
		spawnAgent(searchType: .google_url, searchStrings: keyWords, processjobs: jobs1)
	}
	
	var spawnCount = 0;
	public func spawnAgent(searchType: SearchType, searchStrings: [String], processjobs: [ProcessJob]){
		spawnCount += 1;
		let agent = SearchAgent(id: spawnCount, delegate: self)
		let searchjob = SearchJob(type: searchType, strings: searchStrings)
		agent.load(searchJob: searchjob, processJobs: processjobs)
		agent.execute()
	}
	
	public func lostAgent(){
		if(SearchAgent.instanceCount <= 0) {
			getAnswer()
			stopwatch.stop()
			stopwatch.display()
			print("\(spawnCount) agents spawned")
			print("\(SearchAgent.searchCount) searches, (\(SearchAgent.succesfullSearchCount) succesful)")
			print("Error count: \(Solver.errorCount)")
		}
	}
	
	public func getAnswer() {
		
		var reverseResult = false;
		if(question.contains("not") || question.contains("NOT")){
			reverseResult = true;
			print("NOTE: Reversing result")
		}
		
		print("\n\n")
		for (i, choice) in choices.enumerated() {
			print(choice, " - ", choiceRanks[i])
		}
		
		var best = Int(0)
		if(reverseResult == true){
			best = Int.max;
		} else {
			best = Int.min
		}
		
		var bestIndex = 0;
		for (i, rank) in choiceRanks.enumerated() {
			if(reverseResult == true){
				if rank < best {
					best = rank;
					bestIndex = i
				}
			} else {
				if rank > best {
					best = rank;
					bestIndex = i
				}
			}
		}
		
		print("\n\n")
		print("suggested answer: \(choices[bestIndex])")
		print("\n\n")
	}
	
	public func test() {
		
		reset()
	
		question = ["the", "japanese", "pottery", "style", "raku", "is", "renowned", "for", "which", "of", "these", "traits"]
		choices = [["extreme", "durability"], ["unpredictable", "results"], ["consistent", "results"]]
		
		print("\n\n")
		print("QUESTION: ", question)
		print("ANSWERS: ", choices)
		print("\n\n")
		
		choiceRanks = Array(repeating: 0, count: 3)
		
		solve()
	}
}



