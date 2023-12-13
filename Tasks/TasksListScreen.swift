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
    @Published var tasks = [TaskModel]()
    @Published var isPresentingEditScreen: Bool = false
    @Published var isPresentingUsersScreen: Bool = false
    @Published var userId: String = ""
    
    private(set) var taskToEdit: TaskModel? = nil
    
    private let dittoSync = DittoManager.shared.ditto.sync
    private let dittoStore = DittoManager.shared.ditto.store    
    private var subscription: DittoSyncSubscription?
    private var storeObserver: DittoStoreObserver?
    
    init() {
        try? updateQuery()        
    }
    
    public func updateQuery() throws {        
        let query = userId.isEmpty ?
        "SELECT * FROM COLLECTION tasks (invitationIds MAP) WHERE NOT isSafeForEviction"
        : "SELECT * FROM COLLECTION tasks (invitationIds MAP) WHERE NOT isSafeForEviction AND userId == :userId"

        do {
            // Existing subscription must be cancelled before resetting
            if let sub = subscription {
                sub.cancel()
                subscription = nil
            }
            subscription = try dittoSync.registerSubscription(
                query: query, arguments: ["userId": userId]
            )
        } catch {
            print("ERROR registering subscription: \(error.localizedDescription)")
            throw error
        }
        
        do {
            if let observer = storeObserver {
                observer.cancel()
                storeObserver = nil
            }

            storeObserver = try dittoStore.registerObserver(
                query: subscription!.queryString,
                arguments: subscription!.queryArguments
            ) { [weak self] result in
                guard let self = self else { return }
                Task {
                    await MainActor.run {
                        self.tasks = result.items.compactMap { 
//                            TaskModel($0.value) // alternative
                            TaskModel.withJson($0.jsonString())
                        }
                    }
                }
            }
        } catch {
            print("ERROR registering observer: \(error.localizedDescription)")
            throw error
        }
    }    
    
    public static func randomFakeFirstName() -> String {
        return TasksApp.firstNameList.randomElement()!
    }
    
    func toggleComplete(task: TaskModel) {        
        Task {
            let isComplete = !task.isCompleted
            let query = "UPDATE COLLECTION tasks (invitationIds MAP)"
            + "SET isCompleted = :isCompleted WHERE _id == :_id"

            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: ["isCompleted": isComplete, "_id": task._id]
                )
            } catch {
                print("toggle task failed with error: \(error.localizedDescription)")
            }
        }
    }

    func clickedInvite(task: TaskModel)  {
        let invitedUser = TasksListScreenViewModel.randomFakeFirstName()
        let query = "UPDATE COLLECTION tasks (invitationIds MAP)"
        + " SET invitationIds -> ( \(invitedUser) = true )"
        + " WHERE _id == :_id"
        
        Task {
            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: ["invitedUser": invitedUser, "_id": task._id]
                )
            } catch {
                print("task invite failed with error: \(error.localizedDescription)")
            }
        }
    }

    func clickedBody(task: TaskModel) {
        taskToEdit = task
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
                ForEach(viewModel.tasks) { task in
                    TaskRow(task: task,
                        onToggle: { task in viewModel.toggleComplete(task: task) },
                        onClickBody: { task in viewModel.clickedBody(task: task) },
                        onClickInvite: { task in viewModel.clickedInvite(task: task)}
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
                EditScreen(task: viewModel.taskToEdit).onDisappear {
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
