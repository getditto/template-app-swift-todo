//
//  TasksListScreen.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/26/21.
//

import Combine
import DittoSwift
import SwiftUI

struct QueryExpr {
    var query: String
    var args: [String: Any?]
    init(_ query: String = "", _ args: [String:Any?] = [:]) {
        self.query = query
        self.args = args
    }
}

@MainActor
class TasksListScreenViewModel: ObservableObject {
    @Published var tasks = [TaskModel]()
    @Published var isPresentingEditScreen: Bool = false
    @Published var isPresentingUsersScreen: Bool = false
    @Published var userId: String = ""
    private(set) var taskToEdit: TaskModel?    
    
    private let dittoSync = DittoManager.shared.ditto.sync
    private let dittoStore = DittoManager.shared.ditto.store    
    private var subscription: DittoSyncSubscription?
    private var storeObserver: DittoStoreObserver?
    
    public static var randomFakeFirstName: String {
        return TasksApp.firstNameList.randomElement()!
    }
    
    init() {
        try? updateSubscription()
        try? updateStoreObserver()
    }
    
    var baseQuery: QueryExpr {
        var expr = QueryExpr()
        expr.query = """
            SELECT * FROM COLLECTION tasks (invitationIds MAP) 
            WHERE NOT isSafeForEviction
            """
        if !userId.isEmpty {
            expr.query += " AND userId == :userId"
            expr.args = ["userId": userId]
        } 
        return expr
    }
    
    public func updateSubscription() throws {        
        do {
            // If subscription changes, it must be cancelled before resetting
            // (Note: base subscription query does not change in this sample app) 
            if let sub = subscription {
                sub.cancel()
                subscription = nil
            }
            
            subscription = try dittoSync.registerSubscription(
                query: baseQuery.query, arguments: baseQuery.args
            )
        } catch {
            print("TaskListScreenVM.\(#function) - ERROR registering subscription: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateStoreObserver() throws {
        do {
            // the store observer query expression changes to filter tasks based on selected usesrId
            if let observer = storeObserver {
                observer.cancel()
                storeObserver = nil
            }
            
            storeObserver = try dittoStore.registerObserver(
                query: baseQuery.query,
                arguments: baseQuery.args) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.tasks = result.items.compactMap { 
                        TaskModel($0.cborData())
                    }
                }
        } catch {
            print("TaskListScreenVM.\(#function) - ERROR registering observer: \(error.localizedDescription)")
            throw error
        }
    }

    func toggleComplete(task: TaskModel) {        
        Task {
            let isComplete = !task.isCompleted
            let query = """
            UPDATE COLLECTION tasks (invitationIds MAP)
            SET isCompleted = :isCompleted 
            WHERE _id == :_id
            """
            
            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: ["isCompleted": isComplete, "_id": task._id]
                )
            } catch {
                print("TaskListScreenVM.\(#function) - ERROR toggling task: \(error.localizedDescription)")
            }
        }
    }
    
    func clickedInvite(task: TaskModel)  {
        Task {
            let invitedUser = TasksListScreenViewModel.randomFakeFirstName
            let query = """
            UPDATE COLLECTION tasks (invitationIds MAP)
            SET invitationIds -> ( \(invitedUser) = :invitedUserId )
            WHERE _id == :_id
            """
            
            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: ["invitedUserId": true, "_id": task._id]
                )
            } catch {
                print("TaskListScreenVM.\(#function): ERROR toggling task: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func saveEditedTask(_ task: TaskModel) {
        Task {
            let query = """
            UPDATE tasks SET 
                userId = :userId,
                isCompleted = :completed,
                isSafeForEviction = :safeToEvict
            WHERE _id == :_id
            """
            
            do {
                try await dittoStore.execute(
                    query: query,
                    arguments: [                    
                        "userId": task.userId, 
                        "completed": task.isCompleted,
                        "safeToEvict": task.isSafeForEviction,
                        "_id": task._id
                    ]
                )
            } catch {
                print("TaskListScreenVM.\(#function) - ERROR updating task: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func saveNewTask(_ task: TaskModel) {
        Task {
            let newTask = task.value            
            let query = "INSERT INTO COLLECTION tasks (invitationIds MAP) DOCUMENTS (:newTask)"
            
            do {
                try await dittoStore.execute(query: query, arguments: ["newTask": newTask])
            } catch {
                print("EditScreenVM.\(#function) - ERROR creating new task: \(error.localizedDescription)")
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
            .animation(.default, value: viewModel.tasks)
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
                EditScreen(task: viewModel.taskToEdit)
                    .environmentObject(viewModel)
            })
            .sheet(isPresented: $viewModel.isPresentingUsersScreen, content: {
                NameScreen(userId: $viewModel.userId).onDisappear {
                    try? viewModel.updateStoreObserver()
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
