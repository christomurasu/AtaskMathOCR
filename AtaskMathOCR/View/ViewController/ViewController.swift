//
//  ViewController.swift
//  AtaskMathOCR
//
//  Created by Christopher Pratama on 13/05/23.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var pickingNoteLabel: UILabel!
    @IBOutlet weak var problemTableView: UITableView!
    var fileSaveType: FileSaveType = .file
    var pickingFileType: PickingFileType = .gallery
    var imagePicker = UIImagePickerController()
    let viewModel = ViewControllerViewModel()
    var mathProblems: [MathProblemModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mathProblems = viewModel.getExisting(saveTofile: fileSaveType)
        problemTableView.reloadData()
        self.view.backgroundColor = .red
    }
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pick Picture", style: .done, target: self, action: #selector(rightButtonTapped))
        problemTableView.dataSource = self
        problemTableView.delegate = self
        problemTableView.register(UINib(nibName: "ProblemTableViewCell", bundle: nil), forCellReuseIdentifier: "problemCell")
    }
    
    @objc func rightButtonTapped() {
        if pickingFileType == .camera {
            checkForCameraAccess()
        } else if pickingFileType == .gallery {
            triggerGallery()
        }
    }

    @IBAction func switchTapped(_ sender: UISwitch) {
        var text = ""
        if sender.isOn {
            pickingFileType = .gallery
            text = "picking from gallery"
            self.view.backgroundColor = .red
        } else if !sender.isOn {
            pickingFileType = .camera
            text = "taking picture from camera"
            self.view.backgroundColor = .green
        }
        pickingNoteLabel.text = "You are now \(text)"
    }
    
    @IBAction func pickSwitchTapped(_ sender: UISwitch) {
        var text = ""
        if sender.isOn {
            fileSaveType = .file
            text = "File"
        } else if !sender.isOn {
            fileSaveType = .db
            text = "Database"
        }
        
        mathProblems = viewModel.getExisting(saveTofile: fileSaveType)
        problemTableView.reloadData()
        notesLabel.text = "You are now saving in \(text) Storage"
    }
    
    func triggerCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func triggerGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")
            
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    private func checkForCameraAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            self.triggerCamera()
        } else {
            requestCameraAuth()
        }
    }
    
    private func requestCameraAuth() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] response in
            DispatchQueue.main.async {
                if response {
                    self?.checkForCameraAccess()
                } else {
                    let alert = UIAlertController(title: "Camera", message: "Camera access is absolutely necessary to use this app", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in }))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        if let image = info[.editedImage] as? UIImage {
            self.getResult(image: image)
            return
        } else if let image = info[.originalImage] as? UIImage {
            self.getResult(image: image)
        } else {
            print("Other source")
        }
    }
    
    private func getResult(image: UIImage) {
        let problems = self.viewModel.getResult(saveToFile: fileSaveType, image: image)
        self.mathProblems = problems
        problemTableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mathProblems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = problemTableView.dequeueReusableCell(withIdentifier: "problemCell") as? ProblemTableViewCell else { return UITableViewCell() }
        cell.setupView(mathProblem: mathProblems[indexPath.row])
        return cell
    }
}
