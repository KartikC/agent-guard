import Foundation
let preset = resolvePreset(.solving, .px64)
var frames: [[[Double]]] = []
for index in 0..<480 {
    let frame = orbFrame(preset, size: 64, t: Double(index) / 30 * preset.speed)
    frames.append(frame.dots.map { [$0.x, $0.y, $0.r, $0.white, $0.a] })
}
let data = try JSONSerialization.data(withJSONObject: frames)
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
