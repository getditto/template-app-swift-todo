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
    @Published var body: String
    @Published var isCompleted: Bool = false
    @Published var userId: String
    @Published var isExistingTask: Bool = false
    @Published var evictRequested = false
    @Binding var evictTask: Bool
    
    private let task: TaskModel?
    private let dittoSync = DittoManager.shared.ditto.sync
    private let dittoStore = DittoManager.shared.ditto.store

    init(task: TaskModel?, shouldEvict: Binding<Bool>) {
        self.task = task
        self._evictTask = shouldEvict
        self.body = task?.body ?? ""
        isExistingTask = task != nil        
        isCompleted = task?.isCompleted ?? false
        userId = task?.userId ?? ""
    }

    func save() async {
        
        if let task = task { // updating existing Task
            
            // 1. update field values from form
            // (We do not allow changing body text on existing task)
            let query = "UPDATE tasks SET isCompleted = :isComplete"
            + ", userId = :userId"
            + " WHERE _id == :_id"

            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: ["isComplete": isCompleted, "userId": userId, "_id": task.id]
                )
                
                if evictRequested {
                    // 2. set isSafeForEviction flag on local db document
                    try await dittoStore.execute(
                        query: "UPDATE tasks SET isSafeForEviction = :isSafeForEviction WHERE _id == :_id",
                        arguments: ["isSafeForEviction": true, "_id": task.id]
                    )
                
                    // 3. set ListScreenViewModel flag to evict after view dismissal
                    await MainActor.run {
                        evictTask = true
                    }
                }
            } catch {
                print("EditScreenVM.\(#function) - ERROR updating task: \(error.localizedDescription)")
            }
        } else {  // create new task           
            let newTask: [String : Any] = [
                "body": body,
                "userId": userId,
                "isCompleted": isCompleted,
                "isSafeForEviction": false  
            ]

            let query = "INSERT INTO COLLECTION tasks DOCUMENTS (:newTask)"
            do {
                try await dittoStore.execute(query: query, arguments: ["newTask": newTask])
            } catch {
                print("EditScreenVM.\(#function) - ERROR creating new task: \(error.localizedDescription)")
            }
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

    init(task: TaskModel?, shouldEvict: Binding<Bool>) {
        self._viewModel = StateObject(
            wrappedValue: EditScreenViewModel(task: task, shouldEvict: shouldEvict)
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    // disallow editing body text on existing task
                    TextField("Body", text: $viewModel.body) 
                        .focused($bodyHasFocus)
                        .disabled(viewModel.isExistingTask)
                        .opacity(viewModel.isExistingTask ? 0.5 : 1.0)

                    Toggle("Is Completed", isOn: $viewModel.isCompleted)
                }
                
                if viewModel.isExistingTask {
                    Section {
                        HStack {
                            Button(action: {
                                Task {                                    
                                    viewModel.evictRequested.toggle()
                                }
                            }, label: {
                                Text("Evict")
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

                Picker(selection: $viewModel.userId, label: Text(pickerLabel).font(Font.body)) {
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
                    Task {
                        await viewModel.save()
                        await MainActor.run {
                            dismiss()
                        }
                    }
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
            task: TaskModel(body: "Get Milk", isCompleted: true),
            shouldEvict: .constant(false)
        )
    }
}
