import AVFoundation
import Foundation
import AppKit

// Usage: swift extract_frames.swift <input.mov> <output_dir> <interval_seconds> <max_width>
let args = CommandLine.arguments
guard args.count >= 5 else {
    print("usage: extract_frames.swift <input> <outdir> <interval> <max_width>")
    exit(1)
}
let inputPath = args[1]
let outDir = args[2]
let interval = Double(args[3]) ?? 2.0
let maxWidth = CGFloat(Double(args[4]) ?? 1280)

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let asset = AVAsset(url: URL(fileURLWithPath: inputPath))
let duration = CMTimeGetSeconds(asset.duration)
print("duration:", duration)

let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = CMTime(seconds: 0.25, preferredTimescale: 600)
gen.requestedTimeToleranceAfter = CMTime(seconds: 0.25, preferredTimescale: 600)
if let track = asset.tracks(withMediaType: .video).first {
    let size = track.naturalSize.applying(track.preferredTransform)
    let w = abs(size.width)
    let scale = maxWidth / w
    if scale < 1 {
        gen.maximumSize = CGSize(width: maxWidth, height: abs(size.height) * scale)
    }
}

var t = 0.0
var idx = 0
while t < duration {
    let time = CMTime(seconds: t, preferredTimescale: 600)
    do {
        let cg = try gen.copyCGImage(at: time, actualTime: nil)
        let rep = NSBitmapImageRep(cgImage: cg)
        if let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
            let name = String(format: "frame_%04d_t%07.2f.jpg", idx, t)
            try data.write(to: URL(fileURLWithPath: outDir + "/" + name))
        }
        idx += 1
    } catch {
        print("skip t=\(t): \(error.localizedDescription)")
    }
    t += interval
}
print("extracted:", idx)
