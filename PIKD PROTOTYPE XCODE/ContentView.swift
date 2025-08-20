//
//  ContentView.swift
//  PIKD PROTOTYPE XCODE
//
//  Created by Leo Nguyen on 8/6/25.
//

//CHANGE EVERYTHING TO UIKIT BRUH

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .edgesIgnoringSafeArea(.all) // make it fullscreen
    }
}

#Preview {
    ContentView()
}
