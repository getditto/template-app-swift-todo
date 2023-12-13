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

    private let taskId: String?
    private let dittoSync = DittoManager.shared.ditto.sync
    private let dittoStore = DittoManager.shared.ditto.store

    init(task: TaskModel?) {
        self.taskId = task?._id
        isExistingTask = task != nil
        body = task?.body ?? ""
        isCompleted = task?.isCompleted ?? false
        userId = task?.userId ?? ""
    }

    func save() async {        
        if let _ = taskId { // updating existing Task
            
            // First update field values from form
            // (We do not allow changing body text on existing task)
            let query = "UPDATE tasks SET isCompleted = :isCompleted"
            + ", userId = :userId"
            + " WHERE _id == :_id"            
            
            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: ["isCompleted": isCompleted, "userId": userId, "_id": taskId]
                )
            } catch {
                print("EditScreen.\(#function): ERROR updating task: \(error.localizedDescription)")
            }
            
            // Then evict this task if requested                
            if evictRequested {
                await evict()
                return
            }

        } else {  // creating a new task           
            let task: [String : Any] = [
                "body": body,
                "userId": userId,
                "isCompleted": isCompleted,
                "isSafeForEviction": false,
                "invitationIds": [String:Bool]()  
            ]
            
            let query = "INSERT INTO COLLECTION tasks (invitationIds MAP) DOCUMENTS (:newTask)"
            do {
                try await dittoStore.execute(query: query, arguments: ["newTask": task])
            } catch {
                print("EditScreen.\(#function): ERROR creating new task: \(error.localizedDescription)")
            }
        }
    }

    func evict() async {
        guard let _ = taskId else { return }
        
        // Set the task isSafeForEviction flag = true. This will cause this task to no longer be
        // included in the subscription query results. This means the store observer query result
        // will not include this task when the local database updates.
        do {
            try await dittoStore.execute(
                query: "UPDATE tasks SET isSafeForEviction = :isSafeForEviction WHERE _id == :_id",
                arguments: ["isSafeForEviction": true, "_id": taskId]
            )
        } catch {
            print("EditScreen.\(#function): ERROR setting isSafeForEviction flag: \(error.localizedDescription)")
        }

        // Then evict...
        //
        // N.B.
        // This is a simple example of the DQL evict expression. A better eviction practice
        // would be to run a function on a regular time interval that evicts all documents where 
        // isSafeForEviction == true, not recommended to exceed once per day.
        // See docs for best practices (link)
        do {
            try await dittoStore.execute(
                query: "EVICT FROM tasks WHERE _id == :_id",
                arguments: ["_id": taskId]
            )
        } catch {
            print("EditScreen.\(#function): ERROR evicting task: \(error.localizedDescription)")
        }
    }
}

struct EditScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditScreenViewModel
    @FocusState var bodyHasFocus : Bool
        
    var pickerLabel: String {
        viewModel.isExistingTask ? "Edit user:" : "Create as user:"
    }

    init(task: TaskModel?) {
        self._viewModel = StateObject(wrappedValue: EditScreenViewModel(task: task))
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
        EditScreen(task: TaskModel(body: "Get Milk", isCompleted: true))
    }
}
