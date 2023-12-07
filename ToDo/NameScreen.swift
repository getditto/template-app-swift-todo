//
//  NameScreen.swift
//  ToDo
//
//  Created by Rae McKelvey on 11/23/22.
//

import SwiftUI

struct NameScreen: View {
    @ObservedObject var viewModel: TasksListScreenViewModel
     
    var body: some View {
        VStack {
            Image(systemName: "arrow.down")
                .foregroundStyle(.gray)
                .font(.system(size: 24))
                .opacity(0.5)
            Form {
                Picker(selection: $viewModel.userId, label: Text("Choose user").font(Font.body)) {
                    ForEach(ToDoApp.firstNameList, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Text("Super Admin").tag("")
                }
                .font(Font.title2)
                .pickerStyle(InlinePickerStyle())
            }
        }
    }
}
