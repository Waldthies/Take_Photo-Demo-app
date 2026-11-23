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
        // Ultimately the switch between showing the taken photo, or the button that captures the photo.
        if let img = image {
            Image(uiImage: img)
                .task {
                    // Since we don't need the session once we've taken the photo, we stop it after
                    cameraManager.stopSession()
                }
        } else {
            Button {
                Task {
                    do {
                        // This should never fail, since there is not a lot that can go wrong with setting up the session
                        image = try await cameraManager.capturePhoto()
                    } catch {
                        print("Capture failed: \(error)")
                    }

                }
            }
            //Just a simple styling for the Button
            label: {
                Text("Take Photo")
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .padding()
            /* We the Button view starts i.E. on app start, we first configureSession, and wait
             until that is finished, so we can startSession, which leaves us ready to take the picture.
             */
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
