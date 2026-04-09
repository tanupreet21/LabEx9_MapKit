//
//  ContentView.swift
//  LabEx9_MapKit
//
//  Created by Tanupreet Kaur on 2026-04-08.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var vm = MapViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Ontario Triangle Map")
                .font(.headline)
                .padding(.top, 10)
            
            MapViewRepresentable(viewModel: vm)
                .edgesIgnoringSafeArea(.all)
            
            HStack {
                Button("Show Route"){
                    vm.showRouteGuidance()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Clear") {
                    vm.clearAll()
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
