
//
//  Setup.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

import SwiftUI
import Vision
import AVFoundation
import Observation
import CoreML

// MARK: - 1. Re-usable Models
struct BodyConnection_1: Identifiable {
    let id = UUID()
    let from: HumanBodyPoseObservation.JointName
    let to: HumanBodyPoseObservation.JointName
}

// MARK: - 2. Pose Estimation View Model

@Observable
class PoseEstimationViewModel_1: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var detectedBodyParts: [HumanBodyPoseObservation.JointName: CGPoint] = [:]
    var bodyConnections: [BodyConnection_1] = []
    
    // ----- CORE ML PROPERTIES -----
    private var actionClassifier: PoseClassifer30fps?
    private var poseWindow: [MLMultiArray] = []
    private let actionWindowSize = 90
    
    // ----- PUBLISHED RESULTS -----
    var messiConfidence: Double = 0.0
    var noPoseConfidence: Double = 0.0
    
    var lastSampleBuffer: CMSampleBuffer?
    
    override init() {
        super.init()
        setupBodyConnections()
    }
    
    /// Resets the pose window and confidence scores.
    func reset() {
            self.detectedBodyParts = [:]
            self.poseWindow = []
            self.messiConfidence = 0.0
            self.noPoseConfidence = 0.0
        }
    
    func loadModelAsync() async throws {
        do {
            let config = MLModelConfiguration()
            self.actionClassifier = try await PoseClassifer30fps.load(configuration: config)
            print("✅ Model loaded successfully")
        } catch {
            print("❌ Error loading Core ML model: \(error.localizedDescription)")
            throw error
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        self.lastSampleBuffer = sampleBuffer
        
        // Get the orientation from the connection's rotation angle
        let orientation = connection.videoRotationAngle.toCGImagePropertyOrientation()
        
        Task {
            // Pass the correct orientation to processFrame
            if let detectedPoints = await processFrame(sampleBuffer, orientation: orientation) {
                DispatchQueue.main.async {
                    self.detectedBodyParts = detectedPoints
                }
            } else {
                DispatchQueue.main.async {
                    self.detectedBodyParts = [:]
                }
            }
        }
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) async -> [HumanBodyPoseObservation.JointName: CGPoint]? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let request = DetectHumanBodyPoseRequest()
        do {
            // Use the passed-in orientation
            let results = try await request.perform(on: imageBuffer, orientation: orientation)
            
            if let observation = results.first {

                guard let keypoints = createKeypointsArray(from: observation) else {
                    return extractPoints(from: observation)
                }
                
                self.poseWindow.append(keypoints)
                if self.poseWindow.count > self.actionWindowSize {
                    self.poseWindow.removeFirst()
                }
                
                if self.poseWindow.count == self.actionWindowSize {
                    if let modelInput = createMultiArrayFromWindow(self.poseWindow) {
                        
                        if let prediction = try? await self.actionClassifier?.prediction(input: .init(poses: modelInput)) {
                            let messiValue = prediction.labelProbabilities["Messi"] ?? 0.0
                            let noPoseValue = prediction.labelProbabilities["No pose"] ?? 0.0
                            
                            DispatchQueue.main.async {
                                self.messiConfidence = messiValue
                                self.noPoseConfidence = noPoseValue
                            }
                        }
                    }
                }
                return extractPoints(from: observation)
            }
        } catch {
            print("❌ Error processing frame: \(error.localizedDescription)")
        }
        return nil
    }

    private func createMultiArrayFromWindow(_ window: [MLMultiArray]) -> MLMultiArray? {
        guard window.count == actionWindowSize else {
            print("⚠️ Window size mismatch: \(window.count) vs expected \(actionWindowSize)")
            return nil
        }
        
        let combinedArray = MLMultiArray(concatenating: window, axis: 0, dataType: .float32)
        return combinedArray
    }
    
    private func setupBodyConnections() {
            bodyConnections = [
                .init(from: .nose, to: .neck), .init(from: .neck, to: .rightShoulder),
                .init(from: .neck, to: .leftShoulder), .init(from: .rightShoulder, to: .rightHip),
                .init(from: .leftShoulder, to: .leftHip), .init(from: .rightHip, to: .leftHip),
                .init(from: .rightShoulder, to: .rightElbow), .init(from: .rightElbow, to: .rightWrist),
                .init(from: .leftShoulder, to: .leftElbow), .init(from: .leftElbow, to: .leftWrist),
                .init(from: .rightHip, to: .rightKnee), .init(from: .rightKnee, to: .rightAnkle),
                .init(from: .leftHip, to: .leftKnee), .init(from: .leftKnee, to: .leftAnkle)
            ]
        }
    
    private func createKeypointsArray(from observation: HumanBodyPoseObservation) -> MLMultiArray? {
        guard let array = try? MLMultiArray(shape: [1, 3, 18], dataType: .float32) else {
            return nil
        }
        
        let jointNames: [HumanBodyPoseObservation.JointName] = [
            .nose, .neck,
            .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist,
            .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle,
            .rightEye, .leftEye,
            .rightEar, .leftEar
        ]
        
        let allGroups: [HumanBodyPoseObservation.JointsGroupName] = [.face, .torso, .leftArm, .rightArm, .leftLeg, .rightLeg]
        var jointsDict: [HumanBodyPoseObservation.JointName: Vision.Joint] = [:]
        
        for groupName in allGroups {
            let jointsInGroup = observation.allJoints(in: groupName)
            for (name, joint) in jointsInGroup {
                jointsDict[name] = joint
            }
        }
        
        for (i, jointName) in jointNames.enumerated() {
            if let joint = jointsDict[jointName] {
                array[[0, 0, i] as [NSNumber]] = NSNumber(value: joint.location.x)
                array[[0, 1, i] as [NSNumber]] = NSNumber(value: joint.location.y)
                array[[0, 2, i] as [NSNumber]] = NSNumber(value: joint.confidence)
            } else {
                array[[0, 0, i] as [NSNumber]] = 0
                array[[0, 1, i] as [NSNumber]] = 0
                array[[0, 2, i] as [NSNumber]] = 0
            }
        }
        
        return array
    }
    
    private func extractPoints(from observation: HumanBodyPoseObservation) -> [HumanBodyPoseObservation.JointName: CGPoint] {
        var detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint] = [:]
        let humanJoints: [HumanBodyPoseObservation.JointsGroupName] = [.face, .torso, .leftArm, .rightArm, .leftLeg, .rightLeg]
        
        for groupName in humanJoints {
            let jointsInGroup = observation.allJoints(in: groupName)
            for (jointName, joint) in jointsInGroup {
                if joint.confidence > 0.5 {
                    // Coordinates from Vision are normalized [0,1] and flipped
                    let point = joint.location.verticallyFlipped().cgPoint
                    detectedPoints[jointName] = point
                }
            }
        }
        return detectedPoints
    }
}

// MARK: - 3. Extensions
extension CGFloat {
    /// Maps a videoRotationAngle (0, 90, 180, 270) to a CGImagePropertyOrientation.
    func toCGImagePropertyOrientation() -> CGImagePropertyOrientation {
        switch self {
        case 0:
            return .up
        case 90:
            return .right
        case 180:
            return .down
        case 270:
            return .left
        default:
            return .up
        }
    }
}
