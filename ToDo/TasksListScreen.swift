//
//  TasksListScreen.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/26/21.
//

import Combine
import DittoSwift
import SwiftUI

@MainActor
class TasksListScreenViewModel: ObservableObject {
    @Published var tasks = [ToDo]()
    @Published var isPresentingEditScreen: Bool = false
    @Published var isPresentingUsersScreen: Bool = false
    @Published var userId: String = ""
    
    private(set) var taskToEdit: ToDo? = nil
    private var cancellables = Set<AnyCancellable>()

    private let dittoSync = DittoManager.shared.ditto.sync
    private let dittoStore = DittoManager.shared.ditto.store    
    private var subscription: DittoSyncSubscription?
    private var storeObserver: DittoStoreObserver?

    init() {
        try? updateQuery()
    }
    
    public func updateQuery() throws {
        print("\(#function) CALLED")
        let query = userId.isEmpty ?
        "SELECT * FROM COLLECTION tasks (invitationIds MAP) WHERE NOT isDeleted"
        : "SELECT * FROM COLLECTION tasks (invitationIds MAP) WHERE NOT isDeleted AND userId == '\(userId)'"

        do {
            if let sub = subscription {
                sub.cancel()
                subscription = nil
            }
            subscription = try dittoSync.registerSubscription(query: query)
        } catch {
            print("ERROR registering subscription: \(error.localizedDescription)")
            throw error
        }
        
        do {
            if let observer = storeObserver {
                observer.cancel()
                storeObserver = nil
            }

            storeObserver = try dittoStore.registerObserver(query: subscription!.queryString) { [weak self] result in
                guard let self = self else { return }
                print("registerObserver result in\n"
                      + "--> count: \(result.items.count))\n"
                      + "--> userId: \"\(userId)\"\n"
                      + "--> query: \(query))"
                )                
                tasks = result.items.compactMap { 
                    JSONDecoder.objectFromJSON($0.jsonString())
                }
            }
        } catch {
            print("ERROR registering observer: \(error.localizedDescription)")
            throw error
        }
    }    
    
    public static func randomFakeFirstName() -> String {
        return ToDoApp.firstNameList.randomElement()!
    }
    
    func toggle(toDo: ToDo) {
        let isComplete = !toDo.isCompleted
        let query = "UPDATE COLLECTION tasks (invitationIds MAP)"
        + "SET isCompleted = \(isComplete) WHERE _id == '\(toDo._id)'"
        
        Task {
            do {
                try await dittoStore.execute(query: query)
            } catch {
                print("toggle task failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    func clickedInvite(toDo: ToDo)  {
        let invitedUser = TasksListScreenViewModel.randomFakeFirstName()
        let query = "UPDATE COLLECTION tasks (invitationIds MAP)"
        + " SET invitationIds -> ( \(invitedUser) = true )"
        + " WHERE _id == '\(toDo._id)'"
        
        Task {
            do {
                try await dittoStore.execute(query: query)
            } catch {
                print("task invite failed with error: \(error.localizedDescription)")
            }
        }
    }

    func clickedBody(toDo: ToDo) {
        taskToEdit = toDo
        isPresentingEditScreen = true
    }

    func clickedNewTask() {
        taskToEdit = nil
        isPresentingEditScreen = true
    }
    
    func clickedUsers() {
        taskToEdit = nil
        isPresentingUsersScreen = true
    }
}

struct TasksListScreen: View {
    @StateObject var viewModel = TasksListScreenViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tasks) { toDo in
                    ToDoRow(toDo: toDo,
                        onToggle: { toDo in viewModel.toggle(toDo: toDo) },
                        onClickBody: { toDo in viewModel.clickedBody(toDo: toDo) },
                        onClickInvite: { toDo in viewModel.clickedInvite(toDo: toDo)}
                    )
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {                    
                    Menu {
                        Button("New Task") {
                            viewModel.clickedNewTask()
                        }
                        Button("Users") {
                            viewModel.clickedUsers()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingEditScreen, content: {
                EditScreen(toDo: viewModel.taskToEdit).onDisappear {
                    try? viewModel.updateQuery()
                }
            })
            .sheet(isPresented: $viewModel.isPresentingUsersScreen, content: {
                NameScreen(viewModel: viewModel).onDisappear {
                    try? viewModel.updateQuery()
                }
            })
        }
    }
}

struct TasksListScreen_Previews: PreviewProvider {
    static var previews: some View {
        TasksListScreen()
    }
}
