//
//  ViewController.swift
//  ScenePlayer
//
//  Created by Chiharu Nameki on 2019/09/04.
//  Copyright © 2019 Chiharu Nameki. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices
import os.signpost

class ViewController: UIViewController {
    private struct SceneMarker {
        let startTime: CMTime
        
        static let timeFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
            formatter.zeroFormattingBehavior = .pad
            formatter.unitsStyle = .positional
            return formatter
        }()
        
        var startTimeText: String? {
            let formatter = ViewController.SceneMarker.timeFormatter
            return formatter.string(from: startTime.seconds)
        }
    }
    
    private var markers: [SceneMarker] = []
    private let player: AVPlayer = AVPlayer()
    private var sceneDetector: SceneDetector?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (children.first as? AVPlayerViewController)?.player = player
    }
    
    @IBAction func showPicker(_ sender: Any) {
        player.pause()
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [String(kUTTypeMovie)]
        picker.videoExportPreset = AVAssetExportPresetPassthrough
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let marker = markers[indexPath.row]
        if OSLogHandle.userAction.signpostsEnabled {
            let seekTime = marker.startTime.seconds
            os_signpost(.event, log: OSLogHandle.userAction, name: "Seek", "to: %f", seekTime)
        }
        player.seek(to: marker.startTime)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let marker = markers[indexPath.row]
        cell.textLabel?.text = marker.startTimeText
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return markers.count
    }
}

extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        load(info[.mediaURL] as? URL)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController {
    private func load(_ url: URL?) {
        guard let url = url else { return }
        
        markers = []
        tableView.reloadData()
        
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        
        let detector = SceneDetector()
        self.sceneDetector = detector
        
        let spid = OSSignpostID(log: OSLogHandle.behavior)
        if OSLogHandle.behavior.signpostsEnabled {
            let urlString = url.absoluteString
            os_signpost(.begin, log: OSLogHandle.behavior, name: "Scene Detection", signpostID: spid, "url: %{public}s", urlString)
        }
        
        detector.start(url: url) { times in
            DispatchQueue.main.async { [weak self] in
                if OSLogHandle.behavior.signpostsEnabled {
                    let count = times.count
                    os_signpost(.end, log: OSLogHandle.behavior, name: "Scene Detection", signpostID: spid, "count: %d", count)
                }
                self?.sceneDetector = nil
                self?.markers = times.map({ SceneMarker(startTime: $0) })
                self?.tableView.reloadData()
            }
        }
    }
}
