// OCR helper for hover-peek.lua: prints every whitespace-separated token in an
// image with its bounding box, normalized to 0..1 with a top-left origin.
// Runs as a long-lived process so Vision loads once: reads one image path per
// line on stdin and writes one JSON array per line on stdout.
import CoreGraphics
import Foundation
import ImageIO
import Vision

let word = try! NSRegularExpression(pattern: "\\S+")

func tokens(in path: String) throws -> [[String: Any]] {
	let url = URL(fileURLWithPath: path)
	guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
		let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
	else { return [] }

	let request = VNRecognizeTextRequest()
	request.recognitionLevel = .accurate
	// Language correction "fixes" identifiers like SHE-120 into words.
	request.usesLanguageCorrection = false
	try VNImageRequestHandler(cgImage: image).perform([request])

	var tokens: [[String: Any]] = []
	for observation in request.results ?? [] {
		guard let candidate = observation.topCandidates(1).first else { continue }
		let line = candidate.string
		for match in word.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
			guard let range = Range(match.range, in: line),
				let box = try? candidate.boundingBox(for: range)?.boundingBox
			else { continue }
			tokens.append([
				"text": String(line[range]),
				"x": box.minX, "y": 1 - box.maxY, "w": box.width, "h": box.height,
			])
		}
	}
	return tokens
}

setvbuf(stdout, nil, _IOLBF, 0)
while let path = readLine() {
	let result = (try? tokens(in: path)) ?? []
	let data = try JSONSerialization.data(withJSONObject: result)
	print(String(data: data, encoding: .utf8)!)
}
