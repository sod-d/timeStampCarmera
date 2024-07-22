//
//  ViewController.swift
//  timeStamp
//
//  Created by 유라클 on 2024/05/21.
//

import UIKit
import AVFoundation //카메라 기능을 사용하기 위해 프레임워크 import
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var captureSession: AVCaptureSession! //카메라 세션 관리 객체
    var videoPreviewLayer: AVCaptureVideoPreviewLayer! //카메라 미리보기를 화면에 보여주기 위한 객체
    var photoOutput: AVCapturePhotoOutput! //화면을 캡처하기 위한 객체
    @IBOutlet var captureBtn: UIButton!
    @IBOutlet var gallaryBtn: UIButton!
    @IBOutlet weak var previewView: UIView! //카메라 미리보기를 위한 뷰
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gallaryBtn.frame.size = CGSize(width: 100, height: 100)
        gallaryBtn.imageView?.contentMode = .scaleAspectFit
        captureBtn.frame.size = CGSize(width: 2000, height: 2000)
        captureBtn.imageView?.contentMode = .scaleAspectFit

        
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
        
        //갤러리 버튼에 최근 사진 표시
        fetchLatestPhoto()
        
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        let photoSettings = AVCapturePhotoSettings() //기본 사진 설정 생성
        photoOutput.capturePhoto(with: photoSettings, delegate: self) //사진을 캡처하고 델리게이트 설정
    }
    
    
    @IBAction func openGallery(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController,  animated: true,  completion: nil)
        
        if #available(iOS 14, *) {
                switch PHPhotoLibrary.authorizationStatus(for: .readWrite){
                case .limited:
                    fetchLatestPhoto()
                case .authorized:
                    fetchLatestPhoto()
                case .notDetermined:
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                        if status == .limited {
                            self?.fetchLatestPhoto()
                        }
                        else if status == .authorized {
                            self?.fetchLatestPhoto()
                        }
                        else {
                            showPermissionAlert()
                        }
                    }
                case .restricted, .denied:
                    showPermissionAlert()
                default:
                    break;
            }
        }
        else {
            switch PHPhotoLibrary.authorizationStatus() {
                case .authorized:
                fetchLatestPhoto()
                case .notDetermined:
                    PHPhotoLibrary.requestAuthorization({ [weak self] status in
                        if status == .authorized {
                            self?.fetchLatestPhoto()
                        }
                        else {
                            showPermissionAlert()
                        }
                    })
                case .restricted, .denied:
                    showPermissionAlert()
                default:
                    break
                }
        }
    }
    
    //갤러리 버튼에 최근 사진 표시
    func fetchLatestPhoto(){
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 1
                
                let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                if let asset = fetchResult.firstObject {
                    let imageManager = PHImageManager.default()
                    let targetSize = CGSize(width: 100, height: 100)
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .highQualityFormat
                    options.isSynchronous = true
                    
                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, _) in
                        if let image = image {
                            DispatchQueue.main.async {
                                self.gallaryBtn.setImage(image, for: .normal)
                                self.gallaryBtn.imageView?.contentMode = .scaleAspectFill
                                self.gallaryBtn.imageEdgeInsets = .zero
                            }
                        }
                    }
                }
            }
        }
    }
    
    // UIImagePickerControllerDelegate 메서드
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // 선택된 이미지를 처리할 수 있는 코드 추가
            // 예: 선택된 이미지를 이미지 뷰에 표시하거나 다른 작업 수행
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

    func showPermissionAlert() {
//    PHPhotoLibrary.requestAuthorization() 결과 콜백이 main tread로부터 호출되지 않기 때문에 UI 처리를 위해 main Thread내에서 팝업을 띄우도록 함
    DispatchQueue.main.async {
        let alert = UIAlertController(title: nil, message: "사진 접근 권한이 없습니다. 설정으로 이동하여 권한 설정을 해주세요.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
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

