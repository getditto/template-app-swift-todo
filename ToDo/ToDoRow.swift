//
//  ToDoRow.swift
//  ToDo
//
//  Created by Maximilian Alexander on 8/27/21.
//

import SwiftUI

struct ToDoRow: View {
    let toDo: ToDo

    var onToggle: ((_ toDo: ToDo) -> Void)?
    var onClickBody: ((_ toDo: ToDo) -> Void)?
    var onClickInvite: ((_ toDo: ToDo) -> Void)?

    var body: some View {
        HStack {
            Image(systemName: toDo.isCompleted ? "circle.fill": "circle")
                .renderingMode(.template)
                .foregroundColor(.accentColor)
                .onTapGesture {
                    onToggle?(toDo)
                }
            if toDo.isCompleted {
                Text(toDo.body)
                    .strikethrough()
                    .onTapGesture {
                        onClickBody?(toDo)
                    }

            } else {
                Text(toDo.body)
                    .onTapGesture {
                        onClickBody?(toDo)
                    }
            }
            Spacer()
            Text(toDo.invitationIds.keys.reduce("", { x, y in
                x + y + ", "
            })).foregroundColor(Color.gray)
            
            Text("+").onTapGesture {
                onClickInvite?(toDo)
            }
        }
    }
}

struct ToDoRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ToDoRow(toDo: ToDo(body: "Get Milk", isCompleted: true, invitationIds: ["Susan": true, "John": true]))
            ToDoRow(toDo: ToDo(body: "Do Homework"))
            ToDoRow(toDo: ToDo(body: "Take out trash", isCompleted: true))
        }
    }
}
