//
//  ContentView.swift
//  WaccaRanker
//
//  Created by Kaito on 2021/11/24.
//

import SwiftUI


let db=Processing.init()
let targetrank:Int=99

struct ContentView: View {
    
    @State var targetrank:String="98"
    @State var ranking:Int=98
    @State var title:String="nil"
    @State var difficulty:String="nil"
    @State var showAlert=false
    @State var setrank:String="0"
    @State var songlist:Array<Song>=[]

    var body: some View {
        let _ = db.createListener()
        let _ = db.updatesourcedata()
        let _ = db.refreshrateforsongs()
        let rate=db.getRate()
        
        VStack{
            
            HStack{
                Text("Your Rate:\(Int(rate))").overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.gray,lineWidth: 1)).background(Color.green).cornerRadius(8).onLongPressGesture {
                    db.updatesourcedata(withscores: true)
                    db.refreshrateforsongs()
                    songlist=generatesonglist(targetrank: Int(targetrank)!)
                }
                Button(action: {
                        songlist=showallsongs()
                }, label: {
                    Text("EditAll")
                }).background(Color.red).overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.gray,lineWidth: 1)).cornerRadius(8)
                Button(action: {
                        db.refreshrateforsongs()
                    songlist=generatesonglist(targetrank: Int(targetrank)!)
                }, label: {
                    Text("Refresh")
                }).background(Color.yellow).overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.gray,lineWidth: 1)).cornerRadius(8)
            }
            HStack{
                Text("TargetRank:")
                TextField("TargetRank:",
                          text: $targetrank,
                          onCommit:{
                            songlist=generatesonglist(targetrank: Int(targetrank)!)
                          }
                )
            }.textFieldStyle(RoundedBorderTextFieldStyle()).background(Color.gray).cornerRadius(8)
            Text("You can get rate up by achieving Targetrank for songs below:").bold().italic()
            List(songlist,id:\.self){songp in SongBlock(song: songp).onLongPressGesture {
                self.showAlert=true
                self.title=songp.title
                self.difficulty=songp.difficulty
                let getrank=db.getscorebytitlendifficulty(title: self.title, dif: self.difficulty)
                self.setrank=String(getrank)
            }
            }.textFieldAlert(isShowing: $showAlert, title: self.title, difficulty: self.difficulty,score: $setrank)
            .listStyle(GroupedListStyle())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Song:Identifiable,Hashable{
    var id = UUID()
    var title:String
    var difficulty:String
}

struct SongBlock:View{
    var song:Song
    var body: some View{
        Text("\(song.title) as \(song.difficulty)")
    }
}


func showallsongs()->Array<Song>{
//    let p=listgenerate(rowname: "songid", param: 0)
//    return(p)
    var i = 0
    let songdata=db.checkAllTable()
    var songlist=Array<Song>()
    while i<songdata.count {
        let p=Song(title: songdata[i][0], difficulty: songdata[i][1])
        songlist.append(p)
        i=i+1
    }
    return(songlist)
}


func generatesonglist(targetrank:Int=98)->Array<Song>{
    var i = 0
    let songdata=db.gettargetsonglist(targetrank: targetrank)
    var songlist=Array<Song>()
    while i<songdata.count {
        let p=Song(title: songdata[i][0], difficulty: songdata[i][1])
        songlist.append(p)
        i=i+1
    }

    return(songlist)
}

func updaterank(rank:Int,title:String,dif:String){
    db.alterListener(rank: rank, title: title, dif: dif)
}

struct TextFieldAlert<Presenting>: View where Presenting: View {

    @Binding var isShowing: Bool
    @Binding var score:String
    let presenting: Presenting
    var title: String
    var difficulty:String
    
    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack {
                self.presenting
                    .disabled(isShowing)
                VStack {
                    HStack{
                        Text(self.title)
                        TextField("score", text: self.$score)
                    }
                    Button(action: {
                            withAnimation {
                                self.isShowing.toggle()
                                updaterank(rank: Int(score)!, title: self.title, dif: self.difficulty)
                            }
                    }) {
                        Text("Commit").foregroundColor(Color.black)
                    }
                    
                }
                .background(Color.blue)
                .padding()
                .frame(
                    width: deviceSize.size.width*0.7,
                    height: deviceSize.size.height
                )
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }

}
extension View {

    func textFieldAlert(isShowing: Binding<Bool>,
                        title: String,
                        difficulty:String,
                        score:Binding<String>) -> some View {
        TextFieldAlert(isShowing: isShowing,
                       score:score,
                       presenting: self,
                       title: title,
                       difficulty:difficulty)
    }

}
