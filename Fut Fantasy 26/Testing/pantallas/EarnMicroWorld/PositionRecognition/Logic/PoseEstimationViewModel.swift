//
//  PoseEstimationViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 08/11/25.
//


import SwiftUI
import Vision
import AVFoundation
import Observation
import CoreML

@Observable
class PoseEstimationViewModel: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Published Properties for UI
    
    /// The final prediction sent to the UI (e.g., "Messi", "No Person")
    var prediction: ActionPrediction = .startingPrediction
    
    /// The single, largest pose detected in the frame.
    var detectedPose: Pose?
    
    /// The last frame buffer (for capturing the final image)
    var lastSampleBuffer: CMSampleBuffer?

    // MARK: - Core ML & Vision Properties
    
    // --- ✅ FIX: REMOVED the class property ---
    // private let humanBodyPoseRequest = DetectHumanBodyPoseRequest()
    
    /// YOUR "New" Core ML model
    private var actionClassifier: PoseClassifer30fps?
    
    // FUSED: Windowing logic from your "Old" VideoProcessingChain.swift
    private var poseWindow: [MLMultiArray] = []
    private let predictionWindowSize = 90  // Your "New" value
    private let windowStride = 10          // From "Old" logic
    
    // --- FIX 2: Add flag to prevent concurrent processing ---
    private var isProcessing = false
    
    // MARK: - Public API
    
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
    
    func resetPrediction() {
        self.prediction = .startingPrediction
        self.poseWindow = []
        self.detectedPose = nil
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // --- FIX 2: Check if we are already processing a frame ---
        guard !isProcessing else { return }
        
        // Store for final image capture
        self.lastSampleBuffer = sampleBuffer
        
        // --- DEPRECATION FIX & BACK CAMERA FIX ---
        // Get the rotation angle from the connection and convert it to
        // the orientation Vision needs. This fixes the hard-coded orientation.
        let angle = connection.videoRotationAngle // This is a CGFloat
        
        // --- FIX 3: Convert CGFloat to Double before calling extension ---
        let orientation = Double(angle).toImageOrientation()
        
        // Run the async processing
        Task {
            // --- FIX 2: Set flag to true ---
            isProcessing = true
            // Ensure flag is reset when this task completes
            defer { isProcessing = false }
            
            // Pass the correct orientation to the processor
            await processFrame(sampleBuffer, orientation: orientation)
        }
    }
    
    // MARK: - Fused Processing Logic
    
    // --- DEPRECATION FIX & BACK CAMERA FIX ---
    // Update signature to accept the correct orientation
    private func processFrame(_ sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) async {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // --- ✅ FIX: Create a new request for EVERY frame ---
        let humanBodyPoseRequest = DetectHumanBodyPoseRequest()
        
        do {
            // --- CORE FIX: Use YOUR async request.perform() method ---
            // 1. Perform the request directly, as you intended.
            let results = try await humanBodyPoseRequest.perform(on: imageBuffer, orientation: orientation)
            
            // 2. Check for results
            guard !results.isEmpty else {
                // No results, clear the pose
                await MainActor.run {
                    self.detectedPose = nil
                    self.prediction = .noPersonPrediction
                }
                return
            }
            
            // 3. FUSED: Find largest pose (from "Old" logic)
            let poseObservationPairs = results.compactMap { obs in
                Pose(obs).map { pose in (pose, obs) }
            }
            let largestPair = poseObservationPairs.max(by: { $0.0.area < $1.0.area })
            
            let multiArray: MLMultiArray?
            
            if let largestObs = largestPair?.1 {
                // 4. FUSED: Use YOUR "tick" on the LARGEST pose's observation
                multiArray = createKeypointsArray(from: largestObs)
            } else {
                // No pose found
                multiArray = Pose.emptyPoseMultiArray
            }
            
            // 5. FUSED: Update windowing (from "Old" logic)
            poseWindow.append(multiArray ?? Pose.emptyPoseMultiArray)
            
            if poseWindow.count > predictionWindowSize {
                poseWindow.removeFirst(windowStride)
            }
            
            // 6. FUSED: Make prediction (from "Old" logic)
            if poseWindow.count == predictionWindowSize {
                
                // We use your "New" concatenation logic
                let combinedArray = MLMultiArray(concatenating: poseWindow, axis: 0, dataType: .float32)
                
                if let classifier = self.actionClassifier,
                   let prediction = try? await classifier.prediction(input: .init(poses: combinedArray)) {
                    
                    // Get probabilities
                    let messiValue = prediction.labelProbabilities["Messi"] ?? 0.0
                    let noPoseValue = prediction.labelProbabilities["No pose"] ?? 0.0
                    
                    let newPrediction: ActionPrediction
                    
                    // FUSED: Use ActionPrediction logic
                    if messiValue > 0.8 && messiValue > noPoseValue {
                        newPrediction = ActionPrediction(label: "Messi", confidence: messiValue)
                    } else if noPoseValue > 0.8 {
                        newPrediction = .noPersonPrediction
                    } else {
                        // Find the highest probability label if neither is dominant
                        if let highest = prediction.labelProbabilities.max(by: { $0.value < $1.value }) {
                            if highest.value > 0.6 { // Minimum confidence
                                newPrediction = ActionPrediction(label: highest.key, confidence: highest.value)
                            } else {
                                newPrediction = .lowConfidencePrediction
                            }
                        } else {
                            newPrediction = .lowConfidencePrediction
                        }
                    }
                    
                    await MainActor.run {
                        self.prediction = newPrediction
                    }
                }
            }
            
            // 7. FUSED: Update UI
            await MainActor.run {
                self.detectedPose = largestPair?.0
            }
            
        } catch {
            print("❌ Error processing frame: \(error.localizedDescription)")
            await MainActor.run {
                self.detectedPose = nil
                self.prediction = .noPersonPrediction
            }
        }
    }

    // MARK: - YOUR "TICK" (createKeypointsArray)
    
    // This is your exact function, critical for your model.
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
        
        // --- FINAL FIX: Changed type from `HumanBodyPoseObservation.Joint` to `Vision.Joint` ---
        var jointsDict: [HumanBodyPoseObservation.JointName: Vision.Joint] = [:]
        
        for groupName in allGroups {
            let jointsInGroup = observation.allJoints(in: groupName)
            for (name, joint) in jointsInGroup {
                jointsDict[name] = joint
            }
        }
        
        for (i, jointName) in jointNames.enumerated() {
            if let joint = jointsDict[jointName] {
                // Use normalized coordinates (0,0 bottom-left) for the model
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
}


// --- DEPRECATION FIX & BACK CAMERA FIX ---
// Add this extension to convert the rotation angle (Double)
// into the CGImagePropertyOrientation that Vision needs.
extension Double {
    func toImageOrientation() -> CGImagePropertyOrientation {
        switch self {
        case 0.0:
            return .up
        case 90.0:
            return .right
        case 180.0:
            return .down
        case 270.0:
            return .left
        default:
            return .up // Default
        }
    }
}
