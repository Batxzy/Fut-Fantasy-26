//
//  ActionPrediction.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 08/11/25.
//



import SwiftUI
import Vision
import CoreML

// MARK: - Type Aliases
// FUSED: Use the "New" observation types
// --- FIX 1: Removed `typealias Observation = HumanBodyPoseObservation` ---
// This alias was conflicting with SwiftUI's `Observation` framework.
typealias JointName = HumanBodyPoseObservation.JointName

// MARK: - ActionPrediction (From "Old" file)
/// Bundles an action label with a confidence value.
struct ActionPrediction {
    let label: String
    let confidence: Double!

    var confidenceString: String? {
        guard let confidence = confidence else { return label } // Return label if no confidence
        let percent = confidence * 100
        let formatString = percent >= 99.5 ? "%.0f %%" : "%.1f %%"
        return String(format: formatString, percent)
    }

    init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
    
    private enum AppLabel: String {
        case starting = "Starting Up"
        case noPerson = "No Person"
        case lowConfidence = "Low Confidence"
    }

    static let startingPrediction = ActionPrediction(.starting)
    static let noPersonPrediction = ActionPrediction(.noPerson)
    static let lowConfidencePrediction = ActionPrediction(.lowConfidence)

    private init(_ otherLabel: AppLabel) {
        label = otherLabel.rawValue
        confidence = nil
    }

    var isModelLabel: Bool { confidence != nil }
    var isAppLabel: Bool { confidence == nil }
}


// MARK: - Pose (Fused)
/// Stores the landmarks and connections of a human body pose.
struct Pose {
    let landmarks: [Landmark]
    let connections: [Connection]
    let area: CGFloat

    /// FUSED: Creates a Pose from the "New" HumanBodyPoseObservation.
    // --- FIX 1 (continued): Changed parameter from `Observation` to the explicit type ---
    init?(_ observation: HumanBodyPoseObservation) {
        // --- FIX FOR RUNTIME CRASH ---
        // 1. Create landmarks (using a dictionary to prevent duplicates)
        let allGroups: [HumanBodyPoseObservation.JointsGroupName] = [.face, .torso, .leftArm, .rightArm, .leftLeg, .rightLeg]
        var landmarkDict: [JointName: Landmark] = [:] // Use a dictionary
        
        for groupName in allGroups {
            let jointsInGroup = observation.allJoints(in: groupName)
            for (jointName, joint) in jointsInGroup {
                // Pass both the name (key) and the joint (value)
                if let landmark = Landmark(name: jointName, joint: joint) {
                    landmarkDict[jointName] = landmark // Overwrites duplicates safely
                }
            }
        }
        // Convert the unique landmarks back to an array
        self.landmarks = Array(landmarkDict.values)
        
        guard !self.landmarks.isEmpty else { return nil }

        // 2. Calculate area
        self.area = Pose.areaEstimateOfLandmarks(self.landmarks)

        // 3. Build connections
        // We can now safely create the lookup dictionary
        let jointLocations = landmarkDict.mapValues { $0.location }
        
        var builtConnections = [Connection]()
        for jointPair in Pose.jointPairs {
            guard let one = jointLocations[jointPair.joint1],
                  let two = jointLocations[jointPair.joint2] else { continue }
            builtConnections.append(Connection(one, two))
        }
        self.connections = builtConnections
    }
    
    /// FUSED: Logic from "Old" Pose.swift
    static func areaEstimateOfLandmarks(_ landmarks: [Landmark]) -> CGFloat {
        let xCoordinates = landmarks.map { $0.location.x }
        let yCoordinates = landmarks.map { $0.location.y }
        guard let minX = xCoordinates.min(), let maxX = xCoordinates.max(),
              let minY = yCoordinates.min(), let maxY = yCoordinates.max() else {
            return 0.0
        }
        return (maxX - minX) * (maxY - minY)
    }

    /// FUSED: Joint pairs from "Old" Pose+Connection.swift
    static let jointPairs: [(joint1: JointName, joint2: JointName)] = [
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        (.leftShoulder, .neck), (.rightShoulder, .neck),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip)
    ]

    /// FUSED: From "Old" Pose+Empty.swift, but uses .float32 for YOUR model
    static let emptyPoseMultiArray = zeroedMultiArrayWithShape([1, 3, 18])
    private static func zeroedMultiArrayWithShape(_ shape: [Int]) -> MLMultiArray {
        guard let array = try? MLMultiArray(shape: shape as [NSNumber], dataType: .float32) else {
            fatalError("Creating a multiarray with \(shape) shouldn't fail.")
        }
        guard let pointer = try? UnsafeMutableBufferPointer<Float32>(array) else {
            fatalError("Unable to initialize multiarray with zeros.")
        }
        pointer.initialize(repeating: 0.0)
        return array
    }

    // MARK: - Landmark (Fused)
    struct Landmark {
        private static let threshold: Float = 0.2
        private static let radius: CGFloat = 8.0 // Adjusted radius
        
        let name: JointName
        let location: CGPoint // Normalized (0,0 bottom-left)

        /// FUSED: Initializes from "New" HumanBodyPoseObservation.Joint
        // --- FIX 1 & 2: Initializer now correctly accepts (JointName, Vision.Joint) ---
        init?(name: JointName, joint: Vision.Joint) {
            guard joint.confidence >= Landmark.threshold else { return nil }
            self.name = name
            // --- FINAL FIX: Convert NormalizedPoint to CGPoint ---
            self.location = CGPoint(x: joint.location.x, y: joint.location.y)
        }

        /// FUSED: Drawing logic from "Old" Pose+Landmark.swift
        /// Note: This now draws in a SwiftUI Canvas context.
        func drawToContext(_ context: GraphicsContext, applying transform: CGAffineTransform) {
            let origin = location.applying(transform)
            
            // Flip Y-coordinate for SwiftUI Canvas (top-left origin)
            let flippedOrigin = CGPoint(x: origin.x, y: transform.ty - origin.y)
            
            let diameter = Landmark.radius * 2
            let rectangle = CGRect(x: flippedOrigin.x - Landmark.radius,
                                   y: flippedOrigin.y - Landmark.radius,
                                   width: diameter,
                                   height: diameter)
            
            // Draw white circle with gray border
            context.fill(Path(ellipseIn: rectangle), with: .color(.white))
            context.stroke(Path(ellipseIn: rectangle), with: .color(.gray), lineWidth: 1)
        }
    }

    // MARK: - Connection (Fused)
    struct Connection: Equatable {
        private static let width: CGFloat = 6.0 // Adjusted width
        
        // --- FIX 3: Create a SwiftUI Gradient for the Canvas ---
        private static let swiftUIGradient = Gradient(colors: [
            .green, .yellow, .orange, .red, .purple, .blue
        ])

        private let point1: CGPoint
        private let point2: CGPoint
        
        init(_ one: CGPoint, _ two: CGPoint) { point1 = one; point2 = two }

        /// FUSED: Drawing logic from "Old" Pose+Connection.swift
        /// Note: This now draws in a SwiftUI Canvas context.
        func drawToContext(_ context: GraphicsContext, applying transform: CGAffineTransform) {
            let start = point1.applying(transform)
            let end = point2.applying(transform)
            
            // Flip Y-coordinates for SwiftUI Canvas (top-left origin)
            let flippedStart = CGPoint(x: start.x, y: transform.ty - start.y)
            let flippedEnd = CGPoint(x: end.x, y: transform.ty - end.y)

            var path = Path()
            path.move(to: flippedStart)
            path.addLine(to: flippedEnd)
            
            // Draw the gradient line
            // --- FIX 3 (continued): Use the correct .linearGradient initializer and call the static property ---
            context.stroke(path,
                           with: .linearGradient(Pose.Connection.swiftUIGradient,
                                                 startPoint: flippedStart,
                                                 endPoint: flippedEnd),
                           lineWidth: Connection.width)
        }
    }
}
