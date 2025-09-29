import Foundation
import CryptoKit

// MARK: - SSL Certificate Delegate (for self-signed certificates)

class SelfSignedCertificateDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("SSL Challenge received: \(challenge.protectionSpace.authenticationMethod)")
        print("Host: \(challenge.protectionSpace.host)")
        print("Server trust: \(String(describing: challenge.protectionSpace.serverTrust))")
        
        // Always accept any certificate - equivalent to curl -k --insecure
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // If no server trust, still try to proceed
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Task-level SSL Challenge received: \(challenge.protectionSpace.authenticationMethod)")
        print("Host: \(challenge.protectionSpace.host)")
        print("Server trust: \(String(describing: challenge.protectionSpace.serverTrust))")
        
        // Always accept any certificate - equivalent to curl -k --insecure
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print("HTTP Redirect: \(response.statusCode) -> \(request.url?.absoluteString ?? "unknown")")
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("URLSession task completed with error: \(error)")
            print("Error localizedDescription: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("URLError code: \(urlError.code)")
                print("URLError userInfo: \(urlError.userInfo)")
                
                // Additional debugging for SSL errors
                if urlError.code == .secureConnectionFailed {
                    print("Secure connection failed - this is the SSL/TLS issue")
                    if let underlyingError = urlError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        print("Underlying error: \(underlyingError)")
                    }
                }
            }
        } else {
            print("URLSession task completed successfully")
        }
    }
}

class WiFiRelayService: ObservableObject {
    @Published var availableNetworks: [WiFiRelayNetwork] = []
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://10.0.0.213"
    private let session: URLSession
    private var cookies: [HTTPCookie] = []
    
    init() {
        // Create a custom session with cookie storage and aggressive SSL bypass
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        
        // Additional settings to ignore SSL/TLS issues
        config.tlsMinimumSupportedProtocolVersion = .TLSv10
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        // Timeout settings  
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        // Force delegate to handle SSL validation
        config.urlCredentialStorage = nil
        
        // Additional headers for compatibility
        config.httpAdditionalHeaders = [
            "User-Agent": "PhotoboothApp/1.0",
            "Accept": "*/*",
            "Connection": "close"
        ]
        
        // Create session with custom delegate that bypasses ALL SSL validation
        self.session = URLSession(configuration: config, delegate: SelfSignedCertificateDelegate(), delegateQueue: nil)
        
        print("WiFiRelayService initialized with aggressive SSL certificate bypass")
    }
    
    // MARK: - Authentication
    
    func login(username: String = "admin", password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Skip connectivity test and go straight to authentication
        print("Attempting direct authentication to \(baseURL)")
        
        // Generate MD5 hash of password (as per API documentation)
        let hashedPassword = md5Hash(password)
        
        guard let url = URL(string: "\(baseURL)/login/Auth") else {
            throw WiFiRelayError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        
        let formData = "username=\(username)&password=\(hashedPassword)"
        request.httpBody = formData.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WiFiRelayError.serverError
            }
            
            print("Login response status: \(httpResponse.statusCode)")
            print("Login response headers: \(httpResponse.allHeaderFields)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Login response body: \(responseString)")
            }
            
            // Check status code first
            guard httpResponse.statusCode == 200 else {
                print("Login failed with status code: \(httpResponse.statusCode)")
                throw WiFiRelayError.authenticationFailed
            }
            
            // Extract cookies from response headers
            let headerFields = httpResponse.allHeaderFields.compactMap { (key, value) -> (String, String)? in
                guard let stringKey = key as? String, let stringValue = value as? String else { return nil }
                return (stringKey, stringValue)
            }
            let headerDict = Dictionary(uniqueKeysWithValues: headerFields)
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerDict, for: url)
            
            print("Received \(cookies.count) cookies from login")
            for cookie in cookies {
                print("Cookie: \(cookie.name)=\(cookie.value)")
            }
            
            // For Tenda devices, successful authentication usually returns cookies or specific response content
            // Check for cookies OR check response content for success indicators
            var loginSuccessful = false
            
            if !cookies.isEmpty {
                self.cookies = cookies
                
                // Store cookies in session for automatic handling
                for cookie in cookies {
                    session.configuration.httpCookieStorage?.setCookie(cookie)
                }
                loginSuccessful = true
                print("Login successful: received cookies")
            } else if let responseString = String(data: data, encoding: .utf8) {
                // For Tenda devices, successful authentication typically returns the main HTML page
                // Check for success indicators in response
                if responseString.contains("Tenda Wi-Fi") || responseString.contains("index.html") || responseString.contains("success") || responseString.contains("ok") || responseString.isEmpty {
                    // HTML page with "Tenda Wi-Fi" indicates successful authentication
                    loginSuccessful = true
                    print("Login successful: received HTML page indicating authentication success")
                } else {
                    print("Login failed: response does not indicate success")
                }
            }
            
            if loginSuccessful {
                isAuthenticated = true
            } else {
                print("Login failed: No success indicators found")
                throw WiFiRelayError.authenticationFailed
            }
            
        } catch {
            isAuthenticated = false
            print("Login error: \(error)")
            if error is WiFiRelayError {
                throw error
            } else {
                throw WiFiRelayError.authenticationFailed
            }
        }
    }
    
    // MARK: - Network Scanning
    
    func scanNetworks() async throws {
        guard isAuthenticated else {
            throw WiFiRelayError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/goform/getwifiRelayAgain?modules=wifiScan") else {
            throw WiFiRelayError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        
        // Add cookies to request manually and via session
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        if !cookieHeader.isEmpty {
            request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        
        print("Scanning networks with URL: \(url)")
        print("Using cookies: \(cookieHeader)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WiFiRelayError.serverError
            }
            
            print("Scan response status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Scan response body: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw WiFiRelayError.serverError
            }
            
            // Parse the response to extract network information
            let networks = try parseNetworkResponse(data)
            
            await MainActor.run {
                self.availableNetworks = networks
                print("Found \(networks.count) networks")
            }
            
        } catch {
            print("Network scan error: \(error)")
            throw WiFiRelayError.networkScanFailed
        }
    }
    
    // MARK: - Network Selection
    
    func selectNetwork(ssid: String, password: String, mac: String, is5GHz: Bool = false) async throws {
        guard isAuthenticated else {
            throw WiFiRelayError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/goform/setwifiRelayAgain") else {
            throw WiFiRelayError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        
        // Add cookies to request
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
        
        // Build form data based on frequency band
        let formData = buildFormData(ssid: ssid, password: password, mac: mac, is5GHz: is5GHz)
        request.httpBody = formData.data(using: .utf8)
        
        print("Network selection request:")
        print("URL: \(url)")
        print("Form data: \(formData)")
        print("Cookies: \(cookieHeader)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Network selection failed: Invalid response")
                throw WiFiRelayError.networkSelectionFailed
            }
            
            print("Network selection response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Network selection response body: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                print("Network selection failed with status: \(httpResponse.statusCode)")
                throw WiFiRelayError.networkSelectionFailed
            }
            
            print("Network selection successful")
            
        } catch {
            print("Network selection error: \(error)")
            throw WiFiRelayError.networkSelectionFailed
        }
    }
    
    // MARK: - Helper Methods
    
    private func testConnectivity() async throws {
        // Test basic HTTP connectivity first (no SSL)
        guard let httpURL = URL(string: "http://re.tenda.cn") else {
            throw WiFiRelayError.invalidURL
        }
        
        print("Testing HTTP connectivity to \(httpURL)")
        
        var request = URLRequest(url: httpURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP connectivity test: Status \(httpResponse.statusCode)")
            }
        } catch {
            print("HTTP connectivity test failed: \(error)")
            
            // Try HTTPS with our SSL bypass
            guard let httpsURL = URL(string: "\(baseURL)") else {
                throw WiFiRelayError.invalidURL
            }
            
            print("Testing HTTPS connectivity to \(httpsURL)")
            
            var httpsRequest = URLRequest(url: httpsURL)
            httpsRequest.httpMethod = "GET"
            httpsRequest.timeoutInterval = 10
            
            do {
                let (_, httpsResponse) = try await session.data(for: httpsRequest)
                if let httpResponse = httpsResponse as? HTTPURLResponse {
                    print("HTTPS connectivity test: Status \(httpResponse.statusCode)")
                }
            } catch {
                print("HTTPS connectivity test also failed: \(error)")
                throw WiFiRelayError.networkError
            }
        }
    }
    
    private func md5Hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func buildFormData(ssid: String, password: String, mac: String, is5GHz: Bool) -> String {
        if is5GHz {
            return "wifiRelaySSID=&wifiRelaySecurityMode=WPA2/AES&wifiRelayPwd=&wifiRelayMAC=\(mac)&wifiRelayChannel=4&wifiScanEncode=UTF-8&wifiRelaySSID_5G=\(ssid)&wifiRelaySecurityMode_5G=WPA2/AES&wifiRelayPwd_5G=\(password)&wifiRelayMAC_5G=\(mac)&wifiRelayChannel_5G=157&wifiScanEncode_5G=UTF-8&wifiRelayChkHz=24g+5g&module1=setwifiRelay"
        } else {
            return "wifiRelaySSID=\(ssid)&wifiRelaySecurityMode=WPA2/AES&wifiRelayPwd=\(password)&wifiRelayMAC=\(mac)&wifiRelayChannel=4&wifiScanEncode=UTF-8&wifiRelaySSID_5G=&wifiRelaySecurityMode_5G=WPA2/AES&wifiRelayPwd_5G=&wifiRelayMAC_5G=&wifiRelayChannel_5G=157&wifiScanEncode_5G=UTF-8&wifiRelayChkHz=24g+5g&module1=setwifiRelay"
        }
    }
    
    private func parseNetworkResponse(_ data: Data) throws -> [WiFiRelayNetwork] {
        // Parse the response from Tenda relay device
        // The actual format may vary, but typically it's either JSON or a custom format
        
        // Try to parse as JSON first
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return parseJSONNetworkResponse(jsonObject)
            }
        } catch {
            // If JSON parsing fails, try parsing as string/custom format
        }
        
        // Try parsing as string format
        if let responseString = String(data: data, encoding: .utf8) {
            return parseStringNetworkResponse(responseString)
        }
        
        // If all parsing fails, return mock data for development
        return createMockNetworks()
    }
    
    private func parseJSONNetworkResponse(_ json: [String: Any]) -> [WiFiRelayNetwork] {
        var networks: [WiFiRelayNetwork] = []
        var seenSSIDs: Set<String> = []
        
        // Common JSON structures for WiFi networks
        if let wifiList = json["wifiList"] as? [[String: Any]] {
            for networkInfo in wifiList {
                if let network = parseNetworkFromJSON(networkInfo) {
                    // Only add if we haven't seen this SSID before
                    if !seenSSIDs.contains(network.ssid) {
                        networks.append(network)
                        seenSSIDs.insert(network.ssid)
                    } else {
                        // If we've seen this SSID, keep the one with stronger signal
                        if let existingIndex = networks.firstIndex(where: { $0.ssid == network.ssid }) {
                            if network.signalStrength > networks[existingIndex].signalStrength {
                                networks[existingIndex] = network
                            }
                        }
                    }
                }
            }
        } else if let scan2g = json["wifiScan"] as? [[String: Any]] {
            for networkInfo in scan2g {
                if let network = parseNetworkFromJSON(networkInfo) {
                    // Only add if we haven't seen this SSID before
                    if !seenSSIDs.contains(network.ssid) {
                        networks.append(network)
                        seenSSIDs.insert(network.ssid)
                    } else {
                        // If we've seen this SSID, keep the one with stronger signal
                        if let existingIndex = networks.firstIndex(where: { $0.ssid == network.ssid }) {
                            if network.signalStrength > networks[existingIndex].signalStrength {
                                networks[existingIndex] = network
                            }
                        }
                    }
                }
            }
        }
        
        // Sort by signal strength (strongest first)
        return networks.sorted { $0.signalStrength > $1.signalStrength }
    }
    
    private func parseNetworkFromJSON(_ json: [String: Any]) -> WiFiRelayNetwork? {
        // Handle both generic format and Tenda-specific format
        let ssid = json["wifiScanSSID"] as? String ?? json["ssid"] as? String ?? ""
        guard !ssid.isEmpty else { return nil }
        
        let mac = json["wifiScanMAC"] as? String ?? json["mac"] as? String ?? json["bssid"] as? String ?? ""
        
        // Parse channel - could be string or int
        var channel = 1
        if let channelStr = json["wifiScanChannel"] as? String {
            channel = Int(channelStr) ?? 1
        } else if let channelInt = json["wifiScanChannel"] as? Int {
            channel = channelInt
        } else if let channelInt = json["channel"] as? Int {
            channel = channelInt
        }
        
        // Parse signal strength - format is "-33%" so extract the number
        var signalStrength = -70
        if let signalStr = json["wifiScanSignalStrength"] as? String {
            let numericPart = signalStr.replacingOccurrences(of: "%", with: "")
            signalStrength = Int(numericPart) ?? -70
        } else if let signalInt = json["signal"] as? Int ?? json["rssi"] as? Int {
            signalStrength = signalInt
        }
        
        let securityMode = json["wifiScanSecurityMode"] as? String ?? json["security"] as? String ?? json["enc"] as? String ?? "WPA2"
        let frequency = json["wifiScanChkHz"] as? String ?? json["frequency"] as? String ?? json["freq"] as? String ?? "2.4GHz"
        let is5GHz = frequency.contains("5G") || frequency.contains("5")
        
        return WiFiRelayNetwork(
            ssid: ssid,
            mac: mac,
            channel: channel,
            signalStrength: signalStrength,
            securityMode: securityMode,
            is5GHz: is5GHz
        )
    }
    
    private func parseStringNetworkResponse(_ response: String) -> [WiFiRelayNetwork] {
        var networks: [WiFiRelayNetwork] = []
        
        // Parse line-by-line format or comma-separated format
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: ",")
            if components.count >= 4 {
                let ssid = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let mac = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let signalStr = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let security = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !ssid.isEmpty {
                    let signalStrength = Int(signalStr) ?? -70
                    let is5GHz = ssid.contains("5G") || ssid.contains("_5G")
                    
                    let network = WiFiRelayNetwork(
                        ssid: ssid,
                        mac: mac,
                        channel: is5GHz ? 157 : 6,
                        signalStrength: signalStrength,
                        securityMode: security,
                        is5GHz: is5GHz
                    )
                    networks.append(network)
                }
            }
        }
        
        return networks
    }
    
    private func createMockNetworks() -> [WiFiRelayNetwork] {
        // Mock data for development and testing
        return [
            WiFiRelayNetwork(
                ssid: "HomeNetwork",
                mac: "aa:bb:cc:dd:ee:ff",
                channel: 6,
                signalStrength: -45,
                securityMode: "WPA2",
                is5GHz: false
            ),
            WiFiRelayNetwork(
                ssid: "HomeNetwork_5G",
                mac: "aa:bb:cc:dd:ee:f0",
                channel: 157,
                signalStrength: -55,
                securityMode: "WPA2",
                is5GHz: true
            ),
            WiFiRelayNetwork(
                ssid: "OfficeWiFi",
                mac: "11:22:33:44:55:66",
                channel: 11,
                signalStrength: -65,
                securityMode: "WPA2",
                is5GHz: false
            ),
            WiFiRelayNetwork(
                ssid: "GuestNetwork",
                mac: "99:88:77:66:55:44",
                channel: 1,
                signalStrength: -80,
                securityMode: "Open",
                is5GHz: false
            )
        ]
    }
    
    // MARK: - Convenience Methods
    
    func selectNetwork2_4GHz(ssid: String, password: String, mac: String) async throws {
        try await selectNetwork(ssid: ssid, password: password, mac: mac, is5GHz: false)
    }
    
    func selectNetwork5GHz(ssid: String, password: String, mac: String) async throws {
        try await selectNetwork(ssid: ssid, password: password, mac: mac, is5GHz: true)
    }
}

// MARK: - Models

struct WiFiRelayNetwork: Identifiable, Hashable {
    let id = UUID()
    let ssid: String
    let mac: String
    let channel: Int
    let signalStrength: Int
    let securityMode: String
    let is5GHz: Bool
    
    var displayName: String {
        return ssid
    }
    
    var frequencyDescription: String {
        return is5GHz ? "5 GHz" : "2.4 GHz"
    }
}

// MARK: - Error Types

enum WiFiRelayError: Error, LocalizedError {
    case invalidURL
    case notAuthenticated
    case authenticationFailed
    case networkScanFailed
    case networkSelectionFailed
    case serverError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .notAuthenticated:
            return "Not authenticated. Please login first."
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .networkScanFailed:
            return "Failed to scan for networks"
        case .networkSelectionFailed:
            return "Failed to select network"
        case .serverError:
            return "Server error occurred"
        case .networkError:
            return "Network connection error"
        }
    }
}
