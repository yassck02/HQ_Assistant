//
//  Extensions.swift
//  HQ_Assistant
//
//  Created by Connor yass on 12/22/17.
//  Copyright © 2017 Connor yass. All rights reserved.
//

import Foundation

//MARK: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

extension String {
	
	///
	///	Counts how many times a given substring appears in the given string
	///
	func countSubstring(substring: String) -> Int {
		
		let _string = self.lowercased()
		let _substring = substring.lowercased()
		
		let substringArray = _substring.utf8.map { $0 }
		let stringArray = _string.utf8.map { $0 }
		
		var count = 0
		
		var a = 0
		var b = 0
		var i = 0
		
		while a+i < stringArray.count {
			if(stringArray[a+i] == substringArray[b+i]){
				i += 1
				if(i >= substringArray.count){
					count += 1
					a = a+i+1
					b = 0
					i = 0
				}
			} else {
				a += 1
				i = 0
			}
		}
		return count
	}
	
	///
	///	Extracts the given word type (noun, verb...) from the string using NSLinguisticTagger
	///
	func extractWords(types: [NSLinguisticTag]) -> [String] {
		var words = [String]()
		
		let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
		let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
		
		tagger.string = self
		
		let range = NSRange(location: 0, length: self.count)
		tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, stop in
			if let tag = tag {
				for type in types {
					if(tag == type){
						let word = (self as NSString).substring(with: tokenRange)
						words.append(word)
					}
				}
			}
		}
		
		return words
	}
	
	///
	///	Extracts the
	///
	func lemmatize() -> [String] {
		var words = [String]()
		
		let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
		tagger.string = self
		let range = NSRange(location: 0, length: self.count)
		let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation]
		
		tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { (tag, tokenRange, stop) in
			if let lemma = tag?.rawValue {
				words.append(lemma)
			}
		}
		
		return words
	}
	
}

//MARK: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

extension URLSession {
	
	///
	/// Statrs a syncronous data request and waits until it is completed to continue subsequent code execution
	///
	func synchronousDataTask(urlrequest: URLRequest) -> (Data?, URLResponse?, Error?) {
		var data: Data?
		var response: URLResponse?
		var error: Error?
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let dataTask = self.dataTask(with: urlrequest) {
			data = $0
			response = $1
			error = $2
			
			semaphore.signal()
		}
		
		dataTask.resume()
		
		_ = semaphore.wait(timeout: .distantFuture)
		
		return (data, response, error)
	}
}

//MARK: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

extension Int {
	
	///
	/// Converts the number to a string using Swift's ow number formatter (1 -> one, 300 -> three hundred)
	///
	func writtenFormat() -> String? {
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = .spellOut
		let number = NSNumber(value: self)
		let string = numberFormatter.string(from: number)
		return string
	}
}



