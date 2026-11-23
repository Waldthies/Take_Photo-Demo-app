//
//  ContentView.swift
//  Take_Photo
//
//  Created by Thies Josten on 16.11.26.
//

import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    @StateObject var cameraManager = CameraManager()
    var body: some View {
        if let img = image {
            Image(uiImage: img)
                .task {
                    cameraManager.stopSession()
                }
        } else{
            Button {
                Task {
                    do {
                        image = try await cameraManager.capturePhoto()
                    } catch {
                        print("Capture failed: \(error)")
                    }

                }
            }
            label: {
                Text("Take Photo")
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .padding()
            .task{
                if await cameraManager.configureSession() {
                    cameraManager.startSession()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
