
import AVFoundation
import CoreAudio
import CoreMediaIO
import CoreVideo

class DeviceManager {
    private var logger = Logger(current: DeviceManager.self)
    private var cameraDeviceDiscoverySession: DeviceDiscoverySessionProtocol
    var allCameras = [String: CameraDevice]()
    private var audioDeviceDiscoverySession: DeviceDiscoverySessionProtocol
    var allMics = [String: MicrophoneDevice]()
    private var viewModel: DeviceViewModel

    /// NOTE: uses the DeviceDiscoveryProtocol to be able to use in testing.
    init(viewModel: DeviceViewModel, audioDeviceDiscoverySession: DeviceDiscoverySessionProtocol = AudioDeviceDiscoverySession(),
         cameraDeviceDiscoverySession: DeviceDiscoverySessionProtocol = CameraDeviceDiscoverySession())
    {
        self.audioDeviceDiscoverySession = audioDeviceDiscoverySession
        self.cameraDeviceDiscoverySession = cameraDeviceDiscoverySession
        self.viewModel = viewModel
    }

    func getCameraData() -> [DeviceInfo] {
        return viewModel.cameraInfos
    }

    func getMicrophoneData() -> [DeviceInfo] {
        return viewModel.microhphoneInfos
    }

    func getAudioInputDevices() {

        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if !granted {
                return
            }
        }
        var tempMics = [String: MicrophoneDevice]()
        let devices = audioDeviceDiscoverySession.discoverDevices()
        for device in devices {
            logger.debug("\(device.localizedName) in devices")
            var mediaDevice: MicrophoneDevice

            if allMics.contains(where: { $0.key == device.localizedName }) {
                mediaDevice = allMics[device.localizedName]!
                mediaDevice.captureDevice = device

                allMics[mediaDevice.captureDevice.localizedName] = nil
            } else {
                mediaDevice = MicrophoneDevice(device: device, deviceType: "Microphone")
            }
            mediaDevice.getConnectionID()
            mediaDevice.checkInUse()
            tempMics[mediaDevice.captureDevice.localizedName] = mediaDevice

            for device in allMics.values {
                device.checkInUse()
                allMics[device.captureDevice.localizedName] = nil
                tempMics[device.captureDevice.localizedName] = device
            }
            allMics = tempMics
            viewModel.updateMicrophoneInfos(with: allMics)

            // TODO: could be callback / "closure" instead, have to research
            viewModel.updateRecievedMicrophoneConfigs(config: true)

        }
    }

    func getVideoInputDevices() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                return
            }
        }
        var tempCameras = [String: CameraDevice]()
        let devices = cameraDeviceDiscoverySession.discoverDevices()
        for device in devices {
            var mediaDevice: CameraDevice
            if allCameras.contains(where: { $0.key == device.localizedName }) {
                mediaDevice = allCameras[device.localizedName]!
                mediaDevice.captureDevice = device

                allCameras[mediaDevice.captureDevice.localizedName] = nil
            } else {
                mediaDevice = CameraDevice(device: device, deviceType: "Camera")
            }
            mediaDevice.getConnectionID()
            mediaDevice.checkInUse()
            tempCameras[mediaDevice.captureDevice.localizedName] = mediaDevice

            for device in allCameras.values {
                device.checkInUse()
                allCameras[device.captureDevice.localizedName] = nil
                tempCameras[device.captureDevice.localizedName] = device
            }
            allCameras = tempCameras
            viewModel.updateCameraInfos(with: allCameras)
            viewModel.updateRecievedCameraConfigs(config: true)
        }
    }
}

struct DeviceInfo: Codable {
    let name: String
    let inUse: Bool
    let connected: Bool
}

class DeviceViewModel: ObservableObject {
    private var logger = Logger(current: DeviceViewModel.self)

    @Published var cameraInfos: [DeviceInfo] = []
    @Published var microhphoneInfos: [DeviceInfo] = []
    @Published var receivedMicrophoneConfigs: Bool = false
    @Published var receivedCameraConfigs: Bool = false

    init() {}


    func updateRecievedMicrophoneConfigs(config: Bool) {
        DispatchQueue.main.async {
            self.receivedMicrophoneConfigs = config
        }
    }

    func updateRecievedCameraConfigs(config: Bool) {
        DispatchQueue.main.async {
            self.receivedCameraConfigs = config
        }
    }

    func updateCameraInfos(with cameras: [String: CameraDevice]) {
        logger.debug("Updating cameras")
        DispatchQueue.main.async {
            self.cameraInfos = cameras.map { _, camera in
                DeviceInfo(name: camera.captureDevice.localizedName, inUse: camera.inUse ?? false, connected: camera.lastConnection)
            }
            .sorted { $0.name < $1.name }
        }
    }

    func updateMicrophoneInfos(with microphones: [String: MicrophoneDevice]) {
        logger.debug("Updating cameras")
        DispatchQueue.main.async {
            self.microhphoneInfos = microphones.map { _, microphone in
                DeviceInfo(name: microphone.captureDevice.localizedName, inUse: microphone.inUse ?? false, connected: microphone.lastConnection)
            }
            .sorted { $0.name < $1.name }
        }
    }
}
