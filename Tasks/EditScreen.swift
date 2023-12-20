//
//  EditScreen.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/27/21.
//

import Combine
import DittoSwift
import SwiftUI

class EditScreenViewModel: ObservableObject {
    @Published var taskBodyText: String
    @Published var isExistingTask: Bool = false
    @Published var evictRequested = false
    @Published var task: TaskModel
    private var _taskToEdit: TaskModel?

    init(task: TaskModel?) {
        self._taskToEdit = task
        self.task = task ?? TaskModel.new()
        self.taskBodyText = task?.body ?? ""
        isExistingTask = task != nil        
    }

    func save(listVM: TasksListScreenViewModel) {
        if isExistingTask {
            task.isSafeForEviction = evictRequested
            listVM.saveEditedTask(task)
        } else {
            task.body = taskBodyText
            listVM.saveNewTask(task)
        }
    }
}

struct EditScreen: View {
    @EnvironmentObject var listVM: TasksListScreenViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditScreenViewModel
    @FocusState var bodyHasFocus : Bool
    
    var pickerLabel: String {
        viewModel.isExistingTask ? "Edit user:" : "Create as user:"
    }

    init(task: TaskModel?) {
        self._viewModel = StateObject(
            wrappedValue: EditScreenViewModel(task: task)
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    // disallow editing body text on existing task
                    TextField("Body", text: $viewModel.taskBodyText) 
                        .focused($bodyHasFocus)
                        .disabled(viewModel.isExistingTask)
                        .opacity(viewModel.isExistingTask ? 0.5 : 1.0)

                    Toggle("Is Completed", isOn: $viewModel.task.isCompleted)
                }
                
                if viewModel.isExistingTask {
                    Section {
                        HStack {
                            Button(action: {
                                viewModel.evictRequested.toggle()
                            }, label: {
                                Text("Evict Task")
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.evictRequested ? .white : .red)
                            })
                            
                            Spacer()
                            
                            if viewModel.evictRequested {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(viewModel.evictRequested ? Color.red : nil)
                }

                Picker(selection: $viewModel.task.userId, label: Text(pickerLabel).font(Font.body)) {
                    ForEach(TasksApp.firstNameList, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Text("Super Admin").tag("")
                }
                .font(Font.title2)
                .pickerStyle(InlinePickerStyle())
            }
            .navigationTitle(viewModel.isExistingTask ? "Edit Task": "Create Task")
            .navigationBarItems(
                leading: Button(viewModel.isExistingTask ? "Save" : "Create") {
                    viewModel.save(listVM: listVM)
                    dismiss()
                }, 
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

struct EditScreen_Previews: PreviewProvider {
    static var previews: some View {
        EditScreen(
            task: TaskModel(body: "Get Milk", isCompleted: true)
        )
    }
}
