//
//  ViewController.swift
//  timeStamp
//
//  Created by 유라클 on 2024/05/21.
//

import UIKit
import AVFoundation //카메라 기능을 사용하기 위해 프레임워크 import

class ViewController: UIViewController {
    var captureSession: AVCaptureSession! //카메라 세션 관리 객체
    var videoPreviewLayer: AVCaptureVideoPreviewLayer! //카메라 미리보기를 화면에 보여주기 위한 객체
    var photoOutput: AVCapturePhotoOutput! //화면을 캡처하기 위한 객체
    @IBOutlet var captureBtn: UIButton!
    @IBOutlet weak var previewView: UIView! //카메라 미리보기를 위한 뷰

    override func viewDidLoad() {
        super.viewDidLoad()

        // Capture session 설정
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo //세션의 프리셋을 사진 촬영으로 설정
        
        captureBtn.setImage(UIImage(named: "radio"), for: .normal)
        captureBtn.sizeToFit()
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Back camera is not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera) //후면 카메라를 입력으로 설정
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput() //사진 출력 객체 생성
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput) //세션에 출력을 추가
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession) //비디오 미리보기 레이어 생성
            videoPreviewLayer.videoGravity = .resizeAspectFill //비율을 fill로 맞춤
            videoPreviewLayer.frame = previewView.layer.bounds  //미리보기 레이어의 크기 설정
            previewView.layer.addSublayer(videoPreviewLayer)    //미리보기 레이러를 뷰에 추가
            
            captureSession.startRunning()   //캡처 세션 시작
            
        } catch {
            print("Error setting up the camera: \(error)")
        }
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        let photoSettings = AVCapturePhotoSettings() //기본 사진 설정 생성
        photoOutput.capturePhoto(with: photoSettings, delegate: self) //사진을 캡처하고 델리게이트 설정
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return } //사진 데이터를 가져옴
        guard let capturedImage = UIImage(data: imageData) else { return } //데이터를 이미지로 변환

        // 현재 시간 가져오기
        let currentTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일\nHH:mm"
        let timestamp = formatter.string(from: currentTime)
        
        // 타임스탬프 추가
        let imageWithTimestamp = addTimestampToImage(image: capturedImage, timestamp: timestamp) //타임스탬프를 이미지에 추가
        
        // 갤러리에 저장
        UIImageWriteToSavedPhotosAlbum(imageWithTimestamp, nil, nil, nil)
    }
    
    func addTimestampToImage(image: UIImage, timestamp: String) -> UIImage {
        let textColor = UIColor.white
        let textFont = UIFont.systemFont(ofSize: 150)

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
        ]
        
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let textSize = timestamp.size(withAttributes: textFontAttributes)
        let textRect = CGRect(x: image.size.width/6.5, y: image.size.height/1.2, width: textSize.width, height: textSize.height)
        
        timestamp.draw(in: textRect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

