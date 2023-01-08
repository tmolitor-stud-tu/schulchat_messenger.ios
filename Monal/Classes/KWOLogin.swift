//
//  KWOLogin.swift
//  Monal
//
//  Created by CC on 22.04.22.
//  Copyright © 2022 Monal.im. All rights reserved.
//

import SwiftUI
import monalxmpp

struct KWOLogin: View {
    static private let credFaultyPattern = "^.+@.+\\..{2,}$"
    
    var delegate: SheetDismisserProtocol
    
    @State private var showAlert = false
    @State private var showQRCodeScanner = false

    // login related
    @State private var currentTimeout : DispatchTime? = nil
    @State private var errorObserverEnabled = false
    @State private var newAccountNo: NSNumber? = nil
    @State private var loginComplete = false
    
    @State private var alertPrompt = AlertPrompt(dismissLabel: Text("Close"))
    @ObservedObject private var overlay = LoadingOverlayState()

#if BETA_BUILD
    let appLogoId = "KWOBetaAppLogo"
#else
    let appLogoId = "AppLogo"
#endif
    
    private func showTimeoutAlert() {
        hideLoadingOverlay(overlay)
        alertPrompt.title = Text("Zeitüberschreitung")
        alertPrompt.message = Text("Der Account konnte nicht verbunden werden, bitte prüfe, ob du den richtigen QR-Code gescannt hast und mit dem Internet verbunden bist.")
        showAlert = true
    }

    private func showSuccessAlert() {
        hideLoadingOverlay(overlay)
        alertPrompt.title = Text("Erfolg!")
        alertPrompt.message = Text("Der KWO Messenger ist nun bereit zur Nutzung.")
        showAlert = true
    }

    private func showLoginErrorAlert(errorMessage: String) {
        hideLoadingOverlay(overlay)
        alertPrompt.title = Text("Error")
        alertPrompt.message = Text("Der Account konnte nicht verbunden werden, bitte prüfe, ob du den richtigen QR-Code gescannt hast und mit dem Internet verbunden bist.\n\nTechnische Fehlermeldung: \(String(describing:errorMessage))")
        showAlert = true
    }
    
    private func showQRErrorAlert() {
        hideLoadingOverlay(overlay)
        alertPrompt.title = Text("QR-Code ungültig!")
        alertPrompt.message = Text("Der QR-Code konnte nicht gelesen werden, versuche es noch einmal.")
        showAlert = true
    }

    private func startLoginTimeout() {
        let newTimeout = DispatchTime.now() + 30.0;
        self.currentTimeout = newTimeout
        DispatchQueue.main.asyncAfter(deadline: newTimeout) {
            if(newTimeout == self.currentTimeout) {
                if(self.newAccountNo != nil) {
                    MLXMPPManager.sharedInstance().removeAccount(forAccountNo: self.newAccountNo!)
                    self.newAccountNo = nil
                }
                self.currentTimeout = nil
                showTimeoutAlert()
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack () {
                    Image(decorative: appLogoId)
                        .resizable()
                        .frame(width: CGFloat(120), height: CGFloat(120), alignment: .center)
                        .cornerRadius(16.0)
                        .padding()
                    
                    VStack(alignment: .leading)  {
                        Text("Willkommen beim Kurswahl Online Messenger")
                            .bold()
                        Spacer()
                            .frame(height: 8)
                        Text("...basierend auf freien und offenen Standards (XMPP)")
                    }
                    .padding()
                    .padding(.leading, -16.0)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))

                Form {
                    Text("Zum Einrichten der App einfach der Anleitung auf der Kurswahl Online Seite folgen und mit dem folgenden Button den QR-Code scannen.")
                        .padding()
                    
                    // Just sets the credential in jid and password variables and shows them in the input fields
                    // so user can control what they scanned and if o.k. login via the "Login" button.
                    Button(action: {
                        showQRCodeScanner = true
                    }) {
                        Image(systemName: "qrcode")
                            .frame(maxHeight: .infinity)
                            .padding(9.0)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(10.0)
                    .sheet(isPresented: $showQRCodeScanner) {
                        Text("QR-Code Scanner").font(.largeTitle.weight(.bold))
                        // Get existing credentials from QR and put values in jid and password
                        MLQRCodeScanner(
                            handleLogin: { jid, password in
                                if !jid.isEmpty && !password.isEmpty && jid.range(of: KWOLogin.credFaultyPattern, options:.regularExpression) != nil {
                                    startLoginTimeout()
                                    showLoadingOverlay(overlay, headline:NSLocalizedString("Login läuft", comment: ""))
                                    self.errorObserverEnabled = true
                                    self.newAccountNo = MLXMPPManager.sharedInstance().login(jid, password: password)
                                    if(self.newAccountNo == nil) {
                                        currentTimeout = nil // <- disable timeout on error
                                        errorObserverEnabled = false
                                        showLoginErrorAlert(errorMessage:NSLocalizedString("Account für diese Schule konfiguriert!", comment: ""))
                                        self.newAccountNo = nil
                                    }
                                } else {
                                    showQRErrorAlert()
                                }
                                self.showQRCodeScanner = false
                            }, handleClose: {
                                self.showQRCodeScanner = false
                            }
                        )
                    }
                    
                    if(DataLayer.sharedInstance().enabledAccountCnts() == 0) {
                        Button(action: {
                            self.delegate.dismiss()
                        }){
                            Text("Account später einrichten")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 10.0)
                                .padding(.bottom, 9.0)
                                .foregroundColor(Color(UIColor.systemGray))
                        }
                    }
                }
                .frame(minHeight: 310)
                .textFieldStyle(.roundedBorder)
                .onAppear {UITableView.appearance().tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 30))}
            }
        }
        .addLoadingOverlay(overlay)
        .navigationBarTitle(Text("Willkommen"))
        .onDisappear {UITableView.appearance().tableHeaderView = nil}       //why that??
        .alert(isPresented: $showAlert) {
            Alert(title: alertPrompt.title, message: alertPrompt.message, dismissButton: .default(alertPrompt.dismissLabel, action: {
                if(self.loginComplete == true) {
                    self.delegate.dismiss()
                }
            }))
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("kXMPPError")).receive(on: RunLoop.main)) { notification in
            if(self.errorObserverEnabled == false) {
                return
            }
            if let xmppAccount = notification.object as? xmpp, let newAccountNo : NSNumber = self.newAccountNo, let errorMessage = notification.userInfo?["message"] as? String {
                if(xmppAccount.accountNo.intValue == newAccountNo.intValue) {
                    DispatchQueue.main.async {
                        currentTimeout = nil // <- disable timeout on error
                        errorObserverEnabled = false
                        showLoginErrorAlert(errorMessage: errorMessage)
                        MLXMPPManager.sharedInstance().removeAccount(forAccountNo: newAccountNo)
                        self.newAccountNo = nil
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("kMLResourceBoundNotice")).receive(on: RunLoop.main)) { notification in
            if let xmppAccount = notification.object as? xmpp, let newAccountNo : NSNumber = self.newAccountNo {
                if(xmppAccount.accountNo.intValue == newAccountNo.intValue) {
                    DispatchQueue.main.async {
                        currentTimeout = nil // <- disable timeout on successful connection
                        self.errorObserverEnabled = false
                        showLoadingOverlay(overlay, headline:NSLocalizedString("Lade Kontaktliste", comment: ""))
                    }
                }
            }
        }
#if DISABLE_OMEMO
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("kMonalFinishedCatchup")).receive(on: RunLoop.main)) { notification in
            if let xmppAccount = notification.object as? xmpp, let newAccountNo : NSNumber = self.newAccountNo {
                if(xmppAccount.accountNo.intValue == newAccountNo.intValue) {
                    DispatchQueue.main.async {
                        showSuccessAlert()
                        self.loginComplete = true
                    }
                }
            }
        }
#else
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("kMonalUpdateBundleFetchStatus")).receive(on: RunLoop.main)) { notification in
            if let notificationAccountNo = notification.userInfo?["accountNo"] as? NSNumber, let completed = notification.userInfo?["completed"] as? NSNumber, let all = notification.userInfo?["all"] as? NSNumber, let newAccountNo : NSNumber = self.newAccountNo {
                if(notificationAccountNo.intValue == newAccountNo.intValue) {
                    DispatchQueue.main.async {
                        showLoadingOverlay(
                            overlay, 
                            headline:NSLocalizedString("Lade OMEMO bundles", comment: ""),
                            description:String(format: NSLocalizedString("Lade OMEMO bundles: %@ / %@", comment: ""), completed, all)
                        )
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("kMonalFinishedOmemoBundleFetch")).receive(on: RunLoop.main)) { notification in
            if let notificationAccountNo = notification.userInfo?["accountNo"] as? NSNumber, let newAccountNo : NSNumber = self.newAccountNo {
                if(notificationAccountNo.intValue == newAccountNo.intValue) {
                    DispatchQueue.main.async {
                        showSuccessAlert()
                        self.loginComplete = true
                    }
                }
            }
        }
#endif
    }
}

struct KWOLogin_Previews: PreviewProvider {
    static var delegate = SheetDismisserProtocol()
    static var previews: some View {
        KWOLogin(delegate:delegate)
    }
}
