
import SwiftUI
import Vision
import AVFoundation
import Observation
import CoreML

// MARK: - Body Connection Model
struct BodyConnection: Identifiable {
    let id = UUID()
    let from: HumanBodyPoseObservation.JointName
    let to: HumanBodyPoseObservation.JointName
}

// MARK: - Pose Estimation View Model
@Observable
class PoseEstimationViewModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var detectedBodyParts: [HumanBodyPoseObservation.JointName: CGPoint] = [:]
    var bodyConnections: [BodyConnection] = []
    
    // Core ML properties
    private var actionClassifier: PoseClassifer30fps?
    private var poseWindow: [MLMultiArray] = []
    private let actionWindowSize = 90
    
    // Published results
    var messiConfidence: Double = 0.0
    var noPoseConfidence: Double = 0.0
    var lastSampleBuffer: CMSampleBuffer?
    
    override init() {
        super.init()
        setupBodyConnections()
    }
    
    func reset() {
        self.detectedBodyParts = [:]
        self.poseWindow = []
        self.messiConfidence = 0.0
        self.noPoseConfidence = 0.0
        self.lastSampleBuffer = nil
    }
    
    func loadModelAsync() async throws {
        do {
            let config = MLModelConfiguration()
            self.actionClassifier = try await PoseClassifer30fps.load(configuration: config)
            print("✅ Core ML model loaded successfully")
        } catch {
            print("❌ Error loading Core ML model: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.lastSampleBuffer = sampleBuffer
        
        Task {
            if let detectedPoints = await processFrame(sampleBuffer) {
                await MainActor.run {
                    self.detectedBodyParts = detectedPoints
                }
            } else {
                await MainActor.run {
                    self.detectedBodyParts = [:]
                }
            }
        }
    }
    
    // MARK: - Frame Processing
    func processFrame(_ sampleBuffer: CMSampleBuffer) async -> [HumanBodyPoseObservation.JointName: CGPoint]? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let request = DetectHumanBodyPoseRequest()
        do {
            let results = try await request.perform(on: imageBuffer, orientation: .up)
            if let observation = results.first {
                
                // Create keypoints for ML model
                guard let keypoints = createKeypointsArray(from: observation) else {
                    return extractPoints(from: observation)
                }
                
                self.poseWindow.append(keypoints)
                if self.poseWindow.count > self.actionWindowSize {
                    self.poseWindow.removeFirst()
                }
                
                // Run prediction when window is full
                if self.poseWindow.count == self.actionWindowSize {
                    if let modelInput = createMultiArrayFromWindow(self.poseWindow) {
                        if let prediction = try? await self.actionClassifier?.prediction(input: .init(poses: modelInput)) {
                            let messiValue = prediction.labelProbabilities["Messi"] ?? 0.0
                            let noPoseValue = prediction.labelProbabilities["No pose"] ?? 0.0
                            
                            await MainActor.run {
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
    
    // MARK: - ML Array Creation
    private func createMultiArrayFromWindow(_ window: [MLMultiArray]) -> MLMultiArray? {
        guard window.count == actionWindowSize else {
            print("⚠️ Window size mismatch: \(window.count) vs expected \(actionWindowSize)")
            return nil
        }
        
        let combinedArray = MLMultiArray(concatenating: window, axis: 0, dataType: .float32)
        return combinedArray
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
    
    // MARK: - Body Connections Setup
    private func setupBodyConnections() {
        bodyConnections = [
            .init(from: .nose, to: .neck),
            .init(from: .neck, to: .rightShoulder),
            .init(from: .neck, to: .leftShoulder),
            .init(from: .rightShoulder, to: .rightHip),
            .init(from: .leftShoulder, to: .leftHip),
            .init(from: .rightHip, to: .leftHip),
            .init(from: .rightShoulder, to: .rightElbow),
            .init(from: .rightElbow, to: .rightWrist),
            .init(from: .leftShoulder, to: .leftElbow),
            .init(from: .leftElbow, to: .leftWrist),
            .init(from: .rightHip, to: .rightKnee),
            .init(from: .rightKnee, to: .rightAnkle),
            .init(from: .leftHip, to: .leftKnee),
            .init(from: .leftKnee, to: .leftAnkle)
        ]
    }
    
    // MARK: - Extract Points
    private func extractPoints(from observation: HumanBodyPoseObservation) -> [HumanBodyPoseObservation.JointName: CGPoint] {
        var detectedPoints: [HumanBodyPoseObservation.JointName: CGPoint] = [:]
        let humanJoints: [HumanBodyPoseObservation.JointsGroupName] = [.face, .torso, .leftArm, .rightArm, .leftLeg, .rightLeg]
        
        for groupName in humanJoints {
            let jointsInGroup = observation.allJoints(in: groupName)
            for (jointName, joint) in jointsInGroup {
                if joint.confidence > 0.5 {
                    let point = joint.location.verticallyFlipped().cgPoint
                    detectedPoints[jointName] = point
                }
            }
        }
        return detectedPoints
    }
}
