//
// Copyright © 2021 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct VMWizardView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var data: UTMData
    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var statusText = "Android-x86 listo para instalar"
    @State private var errorMessage: String?
    
    private let downloadURL = URL(string: "https://drive.usercontent.google.com/download?export=download&confirm=t&id=1G0zWPwv_AgRcmtEsxbJNMrbkNMSEbrYh")!

    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "candybarphone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                
                Text("Android-x86 Auto-Installer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if isDownloading {
                    ProgressView(value: downloadProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal, 40)
                    
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Button(action: {
                        startAndroidInstall()
                    }) {
                        Text("Descargar e Instalar Android")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .navigationBarTitle("Instalador", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isDownloading)
                }
            }
            .alert(item: Binding<AlertItem?>(
                get: { errorMessage.map { AlertItem(message: $0) } },
                set: { _ in errorMessage = nil }
            )) { item in
                Alert(title: Text("Aviso"), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func startAndroidInstall() {
        isDownloading = true
        statusText = "Descargando paquete de Android (espera un momento)..."
        
        let session = URLSession(configuration: .default)
        let task = session.downloadTask(with: downloadURL) { localURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.errorMessage = "Error de red: \(error.localizedDescription)"
                    self.statusText = "Error al descargar"
                }
                return
            }
            
            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.errorMessage = "No se recibió el archivo."
                }
                return
            }
            
            DispatchQueue.main.async {
                self.statusText = "Creando máquina virtual en UTM..."
                self.createAndroidVM(from: localURL)
            }
        }
        task.resume()
    }
    
    private func createAndroidVM(from zipURL: URL) {
        data.busyWorkAsync {
            let config = UTMQemuConfiguration()
            config.information.name = "Android 9.0 (x86)"
            config.system.architecture = .x86_64
            config.system.memorySize = 2048
            config.system.cpuCount = 2
            
            _ = try await data.create(config: config)
            
            await MainActor.run {
                self.isDownloading = false
                self.statusText = "¡Instalación completada!"
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

fileprivate struct AlertItem: Identifiable {
    var id: String { message }
    let message: String
}