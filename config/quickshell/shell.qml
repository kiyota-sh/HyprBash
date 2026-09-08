import Quickshell     // For PanelWindow
import Quickshell.Io  // For Process
import QtQuick        // For Text

PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 50

  Text {
    // Give the text an ID we can refer to elsewhere in the file
    id: clock
    anchors.centerIn: parent
    
    // Create a parocess management object
    Process {
      // The command it will run, every argument is its own string
      command: ["date"]
      
      // Run the command immediately
      running: true

      // Process the stdout stream using a StdioCollector
      // Use StdioCollector to retrieve the text the process sends to stdout
      stdout: StdioCollector {
        // Listen for the streamFinished signal, which is sent
        // when the process closes stdout or exits
        onStreamFinished: clock.text = this.text
      }
    }
  }
}
