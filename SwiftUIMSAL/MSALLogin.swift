import Foundation
import MSAL
import SwiftUI
import UIKit
import Combine

struct MSALScreenView_UI: UIViewControllerRepresentable {
    @Binding var userName: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> some MSALScreenViewController {
        let controller = MSALScreenViewController()
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        print(#function)
    }
    
    class Coordinator: NSObject, MSALScreenViewConrtollerDelegate {
        
        var parent: MSALScreenView_UI
        
        init(_ msalScreenView: MSALScreenView_UI) {
            parent = msalScreenView
        }
        
        func updateUserName(userName: String) {
            DispatchQueue.main.async {
                print("delegate called")
                print(userName)
                self.parent.userName = userName
            }
        }
    }
}

protocol MSALScreenViewConrtollerDelegate: AnyObject {
    func updateUserName(userName: String)
}

class MSALScreenViewController: UIViewController {
    let kClientID = "b311b447-9f23-457f-be60-ce4f40552bb2"
    let kRedirectUri = "msauth.com.microsoft.identitysample2.MSALiOS://auth"
    let kAuthority = "https://login.microsoftonline.com/organizations"
    let kGraphEndpoint = "https://graph.microsoft.com/"
    let kScopes = ["user.read"]
    
    weak var delegate: MSALScreenViewConrtollerDelegate? = nil
    var applicationContext: MSALPublicClientApplication? = nil
    var webViewParameters: MSALWebviewParameters? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try self.initMSAL()
        } catch (let err) {
            print("init error: \(err.localizedDescription)")
        }
        
        
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(loadMSALScreen), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func loadMSALScreen() {
        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParameters else { return }
        
        let interactiveParameters = MSALInteractiveTokenParameters(scopes: ["user.read"], webviewParameters: webViewParameters)
        
        applicationContext.acquireToken(with: interactiveParameters) { (result, error) in
            guard let result = result else {
                print("error \(error?.localizedDescription)")
                return
            }
            if let account = result.account.username {
                print("logging \(account)")
                self.delegate?.updateUserName(userName: account)
                print("logging \(result.account.description)")
            }
        }
    }
    
    func initMSAL() throws {
        guard let authorityURL = URL(string: kAuthority) else {
            print("Unable to create authority URL")
            return
        }
        
        let authority = try MSALAADAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(
            clientId: kClientID,
            redirectUri: kRedirectUri,
            authority: authority
        )
        self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
        self.initWebViewParams()
    }
    
    func initWebViewParams() {
        self.webViewParameters = MSALWebviewParameters(authPresentationViewController: self)
    }
    
    func loadCurrentAccount(completion: @escaping (MSALAccount?) -> Void) {
        
        guard let applicationContext = self.applicationContext else { return }
        
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
        
        applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in
            
            if let error = error {
                print("Couldn't query current account with error: \(error)")
                return
            }
            
            if let currentAccount = currentAccount {
                print("Found a signed in account \(String(describing: currentAccount.username)). Updating data for that account...")
                
                completion(currentAccount)
                return
            }
            
            completion(nil)
        })
    }
    
    func acquireTokenInteractively() {
        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParameters else { return }

        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        
        applicationContext.acquireToken(with: parameters) { (result, error) in
            
            if let error = error {
                
                print("Could not acquire token: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else {
                
                print("Could not acquire token: No result returned")
                return
            }
            
//            self.accessToken = result.accessToken
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount!) {
        guard let applicationContext = self.applicationContext else { return }
        
        let parameters = MSALSilentTokenParameters(scopes: self.kScopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            
            if let error = error {
                print("Could not acquire token silently: \(error.localizedDescription)")
                return
            }
            
            guard let result = result else {
                print("Could not acquire token: No result returned")
                return
            }
            
            print("Refreshed Access token is \(result.accessToken)")
        }
    }
}
