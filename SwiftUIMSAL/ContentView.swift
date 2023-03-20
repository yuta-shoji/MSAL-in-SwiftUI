import SwiftUI
import MSAL

struct ContentView: View {
    @State var userName: String = ""
    
    init() {
        print("content view init")
    }

    var body: some View {
        VStack {
            Spacer()
            Text("👋 \(userName)")
                .font(.largeTitle)
                .padding()
            Button("Login with MSAL") {
//                msalModel.loadMSALScreen()
            }
            MSALScreenView_UI(userName: $userName)
                .frame(width: 250, height: 250, alignment: .center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
