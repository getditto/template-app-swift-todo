//
//  EditScreen.swift
//  ToDo
//
//  Created by Maximilian Alexander on 8/27/21.
//

import Combine
import DittoSwift
import SwiftUI

class EditScreenViewModel: ObservableObject {
    @Published var canDelete: Bool = false
    @Published var body: String
    @Published var isCompleted: Bool = false
    @Published var userId: String

    private let _id: String?
    private let dittoSync = DittoManager.shared.ditto.sync
    private let dittoStore = DittoManager.shared.ditto.store

    var isNewToDo: Bool {
        _id == nil
    }
    
    init(toDo: ToDo?) {
        self._id = toDo?._id
        canDelete = toDo != nil
        body = toDo?.body ?? ""
        isCompleted = toDo?.isCompleted ?? false
        userId = toDo?.userId ?? ""
    }

    func save() async {        
        if let _id = _id { // updating existing ToDo
            let query = "UPDATE tasks SET isCompleted = \(isCompleted)"
            + ", userId = '\(userId)'"
            + " WHERE _id=='\(_id)'"
            
            do {
                try await dittoStore.execute(query: query)
            } catch {
                print("EditScreen.\(#function): ERROR updating task: \(error.localizedDescription)")
            }
        } else {  // creating a new ToDo            
            let toDo: [String : Any] = [
                "body": body,
                "userId": userId,
                "isCompleted": isCompleted,
                "isDeleted": false,
                "invitationIds": [String:Bool]()  
            ]
            
            let query = "INSERT INTO COLLECTION tasks (invitationIds MAP) DOCUMENTS (:newDoc)"
            do {
                try await dittoStore.execute(query: query, arguments: ["newDoc": toDo])
            } catch {
                print("EditScreen.\(#function): ERROR creating new task: \(error.localizedDescription)")
            }
        }
    }

    func delete() async {
        guard let _id = _id else { return }
        
        // first set isDeleted flag to avoid replicating immediately
        do {
            try await dittoStore.execute(query: "UPDATE tasks SET isDeleted = \(true) WHERE _id == '\(_id)'")
        } catch {
            print("EditScreen.\(#function): ERROR setting isDelete flag: \(error.localizedDescription)")
        }

        // then evict
        //
        // N.B.
        // This is a simple example of the DQL evict expression. A better eviction practice
        // would be to run a function on a regular time interval that evicts all documents where 
        // isDeleted == true, not recommended to exceed once per day.
        // See docs for best practices (link)
        do {
            try await dittoStore.execute(query: "EVICT FROM tasks WHERE _id == '\(_id)'")
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
        viewModel.isNewToDo ? "Create as user:" : "Edit user:"
    }

    init(toDo: ToDo?) {
        self._viewModel = StateObject(wrappedValue: EditScreenViewModel(toDo: toDo))
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Body", text: $viewModel.body)
                        .focused($bodyHasFocus)
                    Toggle("Is Completed", isOn: $viewModel.isCompleted)
                }
                if viewModel.canDelete {
                    Section {
                        Button(action: {
                            Task {
                                await viewModel.delete()
                                await MainActor.run {
                                    dismiss()
                                }
                            }
                        }, label: {
                            Text("Delete")
                                .foregroundColor(.red)
                        })
                    }
                }

                Picker(selection: $viewModel.userId, label: Text(pickerLabel).font(Font.body)) {
                    ForEach(ToDoApp.firstNameList, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Text("Super Admin").tag("")
                }
                .font(Font.title2)
                .pickerStyle(InlinePickerStyle())
            }
            .navigationTitle(viewModel.canDelete ? "Edit ToDo": "Create ToDo")
            .navigationBarItems(
                leading: Button(viewModel.canDelete ? "Save" : "Create") {
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
        EditScreen(toDo: ToDo(body: "Get Milk", isCompleted: true))
    }
}
