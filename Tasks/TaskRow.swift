//
//  TaskRow.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/27/21.
//

import SwiftUI

struct TaskRow: View {
    let task: TaskModel
    var onToggle: ((_ task: TaskModel) -> Void)?
    var onClickBody: ((_ task: TaskModel) -> Void)?

    var body: some View {
        HStack {
            Button {
                onToggle?(task)
            } label: {
                Image(systemName: task.isCompleted ? "circle.fill": "circle")
                    .renderingMode(.template)
                    .foregroundColor(.accentColor)
                    .frame(minWidth: 32)
            }
            .buttonStyle(.plain)
            Divider()

            Button {
                onClickBody?(task)
            } label: {
                Text(task.body)
                    .strikethrough(task.isCompleted)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct TaskRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TaskRow(task: TaskModel(body: "Get Milk", isCompleted: true))
            TaskRow(task: TaskModel(body: "Do Homework"))
            TaskRow(task: TaskModel(body: "Take out trash", isCompleted: true))
        }
    }
}
