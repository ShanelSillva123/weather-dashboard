//
//  VisitedPlacesView.swift
//  CWKTemplate24
//
//  Created by girish lukka on 23/10/2024.
//

import SwiftUI

struct VisitedPlacesView: View {
/*
    Set up the @Environment(\.modelContext) for SwiftData's Model Context
    Use @Query to fetch data from SwiftData models
*/

    
    var body: some View {
        VStack{
            Text("Image shows the information to be presented in this view")
            Spacer()
            Image("places")
                .resizable()

            Spacer()
        }
        .frame(height: 600)
    }
}

#Preview {
    VisitedPlacesView()
}
