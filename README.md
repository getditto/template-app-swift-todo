# template-app-SwiftUI-todo

## Setup  
1. Clone this repo to a location on your machine, and open in Xcode    
2. Navigate to the project Signing & Capabilities tab and modify the Team and Bundle Identifier 
settings to your Apple developer account credentials to provision building to your device       
3. In Terminal, run `cp .env.template .env` in the project root directory    
4. Edit `.env` and copy your Ditto AppID and token from the [Ditto Portal](https://portal.ditto.live/) 
as in the following example:    
```
DITTO_APP_ID=a01b2c34-5d6e-7fgh-ijkl-8mno9p0q12r3
DITTO_PLAYGROUND_TOKEN=a01b2c34-5d6e-7fgh-ijkl-8mno9p0q12r3
```
5. Clean (**Command + Shift + K**), then build (**Command + B**). This will generate `Env.swift` in
the project directory  

## Features  
- Select "New Task" from the plus menu to create a simple task  
- Select "Users" from the plus menu to view tasks for a given user, or view all tasks as 
"Super Adnim", the default user    
- In list view, click the body of a task row to open it in Edit view  
- In list view, click task row "plus" icon to add (random) user invitations  
- Toggle task completion status in Edit view, or by clicking the row icon in the list view    
- Evict task in the Edit view  
