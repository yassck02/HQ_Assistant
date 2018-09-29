//
//  ViewController.swift
//  HQ_Assistant
//
//  Created by Connor yass on 12/15/17.
//  Copyright © 2017 Connor yass. All rights reserved.
//

/*
base 64 image encoder: https://www.base64-image.de
base 64 image decoder: https://codebeautify.org/base64-to-image-converter
OCR.space api: https://ocr.space/ocrapi
*/

import Cocoa

class ViewController: NSViewController {

	//MARK:-------------------------------------------------------------------------------
	
	///
	///	Extracts the text from the given image by placing a call to the OCR.space web api
	///
	func extractText(from image: CGImage) {
		
		let bitmapRep = NSBitmapImageRep(cgImage: image)
		let imageData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])! as Data
		
		let url = URL(string: "https://api.ocr.space/parse/image")!
		
		let session = URLSession.shared
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		
		let boundary = "--------69-69-69-69-69"
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("6ea787d56088957", forHTTPHeaderField: "apikey")
		request.httpBody = createBody(parameters: nil, filePathKey: "file", imageDataKey: imageData, boundary: boundary)
		
		let task = session.synchronousDataTask(urlrequest: request)
		let data = task.0
		let error = task.2
		
		if data == nil {
			print("ERROR: No response from OCR.space api call")
			return
		}
		
		if error != nil {
			print("ERROR: ", error!)
			return
		}
		
		do {
			let dictionary = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
			
			if let parsedResults = dictionary["ParsedResults"] as? [[String: Any]] {
				if let parsedResult = parsedResults.first {
					if let text = parsedResult["ParsedText"] as? String {
						parsedText = text
						return
					} else {
						print("ERROR: Could not read parsedText")
						return
					}
				} else {
					print("ERROR: Could not read first element of parsedResult")
					return
				}
			} else {
				print("ERROR: Could not read parsedResult")
				return
			}
		} catch let error {
			print("ERROR: Could not serialize jSON Data into dictionary: \(error.localizedDescription)")
			return
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	///
	///	Creates a the body of the url request using the given parameters
	///
	private func createBody(parameters: [String: String]?, filePathKey: String?, imageDataKey: Data, boundary: String) -> Data {
		var body = Data();
		
		if parameters != nil {
			for (key, value) in parameters! {
				body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
				body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
				body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
			}
		}
		
		let filename = "image.jpg"
		let mimetype = "image/jpg"
		
		body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
		body.append("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n".data(using: String.Encoding.utf8)!)
		body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
		body.append(imageDataKey)
		body.append("\r\n".data(using: String.Encoding.utf8)!)
		
		body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
		
		return body
	}

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	//
	private var parsedText: String? {
		didSet {
			processParsedText()
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	///
	/// Cleans the text and separates it into the question and answers.
	///
	private func processParsedText() {
		
		if parsedText == nil {
			print("ERROR: No parsed text to process")
			return
		}
		
		var cleanText = parsedText!
		
		// Remove unencessary characters
		cleanText = cleanText.replacingOccurrences(of: "\"", with: "")
		cleanText = cleanText.replacingOccurrences(of: "\'", with: "")
		cleanText = cleanText.replacingOccurrences(of: "?", with: "")
		cleanText = cleanText.replacingOccurrences(of: ",", with: "")
		cleanText = cleanText.replacingOccurrences(of: "&", with: "and")
		cleanText = cleanText.replacingOccurrences(of: "-", with: " ")
		
		// Convert to lowercased
		//cleanText = cleanText.lowercased()
		
		// Separate the text into lines
		var lines = cleanText.components(separatedBy: " \r\n")
		
		// Dispose of any empty lines
		for (i, line) in lines.enumerated() {
			if line.isEmpty {
				lines.remove(at: i)
			}
		}
		
		// Assume the last 3 lines are the choices
		for _ in 0..<3 {
			if(lines.count <= 0) { return }
			let choice = lines.removeLast()
			solver.choices.append(choice.components(separatedBy: " "))
			solver.choiceRanks.append(0)
		}
		
		// remove unwanted words from the choices
		for (i, choice) in solver.choices.enumerated() {
			for (n, word) in choice.enumerated() {
				if word == "the" {
					solver.choices[i].remove(at: n)
				} else if word == "a" {
					solver.choices[i].remove(at: n)
				} else if word  == "was" {
					solver.choices[i].remove(at: n)
				} else if word == "it" {
					solver.choices[i].remove(at: n)
				} else if word == "of" {
					solver.choices[i].remove(at: n)
				} else if word == "is" {
					solver.choices[i].remove(at: n)
				} else if word == "an" {
					solver.choices[i].remove(at: n)
				} else if word == "of" {
					solver.choices[i].remove(at: n)
				} else if word == "and" {
					solver.choices[i].remove(at: n)
				} else if word == "no" {
					solver.choices[i].remove(at: n)
				}
			}
		}
		
		// Whatever is left over is part of the question
		while (lines.isEmpty == false) {
			let line = lines.removeFirst()
			let words = line.components(separatedBy: " ")
			for word in words {
				solver.question.append(word)
			}
		}
		
		print("\n\n")
		print("QUESTION: ", solver.question)
		print("CHOICES: ", solver.choices)
		print("\n\n")
		
		
		
		
		
		
		
		
		// **********************************************************************
		// **********************************************************************
		// **********************************************************************
		// **********************************************************************
		// **********************************************************************
		
		// output question to file
		
		// **********************************************************************
		// **********************************************************************
		// **********************************************************************
		// **********************************************************************
		// **********************************************************************
	}

	//MARK:-------------------------------------------------------------------------------
	
	///
	///	Captures a screenshot within the given rect
	///
	func caputureScreenshot(within rect: CGRect) -> CGImage? {
		if let screenshot = CGWindowListCreateImage(.infinite, .optionOnScreenBelowWindow, CGWindowID(self.view.window!.windowNumber), []) {
			
			var cropRect = rect
			cropRect.origin.x = view.window!.frame.origin.x * view.window!.backingScaleFactor
			cropRect.origin.y = (view.window!.screen!.frame.height - view.window!.frame.origin.y - view.window!.frame.height + 20) * view.window!.backingScaleFactor
			cropRect.size = CGSize(width: rect.width * view.window!.backingScaleFactor, height: rect.height * view.window!.backingScaleFactor)
			
			let croppedImage = screenshot.cropping(to: cropRect)
			return croppedImage
		} else {
			print("ERROR: screenshot capture failed")
			return nil
		}
	}
	
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	///
	///	Saves a CGImage to the given filepath
	///
	func export(image: CGImage, to filepath: String) {
		let unixTimestamp = Int64(Date().timeIntervalSince1970)
		let fileUrl = URL(fileURLWithPath: filepath + "\(unixTimestamp)" + ".jpg", isDirectory: true)
		let bitmapRep = NSBitmapImageRep(cgImage: image)
		let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
		
		do {
			try jpegData.write(to: fileUrl, options: .atomic)
		}
		catch {
			print("ERROR: Failed to save image to \(filepath)")
			print("ERROR: \(error)")
		}
	}
	
	//MARK:-------------------------------------------------------------------------------
	
	/// The box that defines the reigon of the screen to screenshot
	@IBOutlet weak var captureView: NSBox!
	
	/// The button that kickstarts the whole process
	@IBOutlet weak var button_answer: NSButton!
	
	/// The object that solves the question
	var solver = Solver()
	
	///
	/// Sets up the interfece. (Makes the window transparent, draws borders ...)
	///
	func setupInterface() {
		button_answer.bezelColor = NSColor.white
		button_answer.bezelStyle = .roundRect
		button_answer.isBordered = true
		if let window = view.window {
			window.isOpaque = false
			window.backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0);
			window.level = .floating
		}
		self.view.wantsLayer = true
	}
	
	//MARK:-------------------------------------------------------------------------------
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillLayout() {
		setupInterface()
	}
	
	//MARK:-------------------------------------------------------------------------------
	
	///
	///	Fucntion that gets called then the button is pressed
	///
	@IBAction func answerQuestion(_ sender: Any) {
		
		solver.reset()
		guard let image = caputureScreenshot(within: captureView.frame) else { return }
		extractText(from: image)
		solver.solve()
		
		//let text = "watermellon water"
		//print(text.countSubstring(substring: "water"))
		
		//solver.test()
	}
	
	//MARK:-------------------------------------------------------------------------------	
	
}

