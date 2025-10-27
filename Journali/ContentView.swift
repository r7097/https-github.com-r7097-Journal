//
//  ContentView.swift
//  Journali
//
//  Created by Raghad Alamoudi on 04/05/1447 AH.
//

import SwiftUI

struct ContentView: View {
    @State private var startApp = false

    var body: some View {
        NavigationStack {
            if startApp {
                MainPage()
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.2),
                            Color.black
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image("url")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .shadow(color: .pink.opacity(0.4), radius: 10, x: 0, y: 5)

                        Text("Journali")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your thoughts, your story")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            startApp = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}


#Preview {
    ContentView()
}
