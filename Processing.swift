//
//  Processing.swift
//  WaccaRanker
//
//  Created by Kaito on 2021/11/24.
//

import Foundation

class Processing:NSObject{

    var db:SQLiteDB!
    let TOPLEVEL=14.2
    
    func createListener(){
        db=SQLiteDB.shared
        db.open(dbPath: "", copyFile: true, inMemory: false)
        //let result=db.execute(sql: "create table if not exists songlistall(songid int,title varchar(100),difficulty varchar(10),level float,highestrate float,realrate float,nextrate float,ranking varchar(10),group varchar(3));")
        let result=db.execute(sql: "create table if not exists songlistall(songid int,title varchar(100),difficulty varchar(10),level float,highestrate float,realrate float,nextrate float,ranking int,group0 varchar(3))")
        print(result)
    }

    func addListener(){
        let sql="insert into songlistall(songid,title,difficulty,level,highestrate,realrate,nextrate,ranking,group0) values(1,'xtreme','inferno',14.0,56.0,48.7,52.0,98,'old');"
        let result = db.execute(sql: sql)
        print(result)
    }

    func deleteListener(){
        let sql=""
        let result = db.execute(sql: sql)
        print(result)
    }

    func alterListener(rank:Int,title:String,dif:String){
        let sql="update songlistall set ranking = \(rank) where title= '\(title)' and difficulty= '\(dif)' "
        let result = db.execute(sql: sql)
        print(result)
    }

    func retrieveListener(rowname:String,param:Any,group:String)-> Array<Array<String>>{
        let sql="select * from songlistall where \(rowname) > \(param) and group0='\(group)'"
        let result = db.query(sql: sql)
        var resarray=Array<Array<String>>()
        if result.count>0{
            for querynode in result{
                let title=querynode["title"] as! String
                let difficulty=querynode["difficulty"] as! String
                resarray.append([title,difficulty])
            }
            return(resarray)
        }
        return([])
    }
    
    func getRate()->Double{
        var oldrate=0.0
        var newrate=0.0
        let result0=db.query(sql: "select sum(realrate) from (select * from songlistall where group0='old' order by realrate desc limit 35)")
        let result1=db.query(sql: "select sum(realrate) from (select * from songlistall where group0='new' order by realrate desc limit 15)")
        if !result0[0].isEmpty{
            oldrate=result0[0]["sum(realrate)"] as! Double
        }
        if !result1[0].isEmpty{
            newrate=result1[0]["sum(realrate)"] as! Double
        }
        return(oldrate+newrate)
    }

    func checkAllTable()->Array<Array<String>>{
        var resarray=Array<Array<String>>()
        let result=db.query(sql: "select * from songlistall where group0 <> 'ua'")
        for querynode in result{
            let title=querynode["title"] as! String
            let difficulty=querynode["difficulty"] as! String
            resarray.append([title,difficulty])
        
        }
        return(resarray)
    }
    
    func translatecoeff(score:Int)->Double{
        var coeff=0.0
        let dict:[Int:Double]=[99:4.0,98:3.75,97:3.5,96:3.25,95:3.0,94:2.75,93:2.5,92:2.5,91:2.0,90:2.0,89:1.5,88:1.5,87:1.5,86:1.5,85:1.5,84:1.0,83:1.0,82:1.0,81:1.0,80:1.0]
        if dict[score] != nil{
            coeff=dict[score]!
        }
        return(coeff)
    }
    
    func translaterank(score:Int)->String{
        var rank="D"
        let dict:[Int:String]=[99:"sss+",98:"sss",97:"ss",96:"ss",95:"ss",94:"s",93:"s",92:"s",91:"s",90:"s",89:"AAA",88:"AAA",87:"AAA",86:"AAA",85:"AAA",84:"AA",83:"AA",82:"AA",81:"AA",80:"AA"]
        if dict[score] != nil{
            rank=dict[score]!
        }
        return(rank)
    }
    
    
    func getlowestrank()->Array<Double>{
        var rankoldnew:Array<Double>=[]
        let oldrank=db.query(sql: "select realrate from songlistall where group0='old' order by realrate desc limit 1 offset 35")
        let newrank=db.query(sql: "select realrate from songlistall where group0='new' order by realrate desc limit 1 offset 15")
        rankoldnew.append(oldrank[0]["realrate"] as! Double)
        rankoldnew.append(newrank[0]["realrate"] as! Double)
        return(rankoldnew)
    }
    
    
    func findpropersonglevel(lowerrate:Double,targetrank:Int = 99)->Double{
        let coeff=translatecoeff(score: targetrank)
        let levelceil=floor(10*lowerrate/coeff)/10
        
        if levelceil>TOPLEVEL{
            return(TOPLEVEL)
        }
        return levelceil
    }
    
    
    func gettargetsonglist(targetrank:Int)->Array<Array<String>>{
        let lowestrate=getlowestrank()
        let coeffold=findpropersonglevel(lowerrate: lowestrate[0], targetrank: targetrank)
        let sql1="select * from songlistall where ranking < \(targetrank) and level >= \(coeffold) and group0 = 'old' order by level asc"
        let coeffnew=findpropersonglevel(lowerrate: lowestrate[1], targetrank: targetrank)
        let sql2="select * from songlistall where ranking < \(targetrank) and level >= \(coeffnew) and group0='new' order by level asc"
        
        let result1 = db.query(sql: sql1)
        let result2 = db.query(sql: sql2)
        var resarray:Array<Array<String>>=[]
        if result1.count>0{
            for querynode in result1{
                let title=querynode["title"] as! String
                let difficulty=querynode["difficulty"] as! String
                resarray.append([title,difficulty])
            }
        }
        if result2.count>0{
            for querynode in result2{
                let title=querynode["title"] as! String
                let difficulty=querynode["difficulty"] as! String
                resarray.append([title,difficulty])
            }
        }
        return(resarray)
        
    }
    
    func refreshrateforsongs(){//update realrate and nextrate refer to ranking
        let sql="update songlistall set realrate=level*(select coeff from coeff where coeff.score=songlistall.ranking)"
        _=db.execute(sql: sql)
        
        let sql2="update songlistall set nextrate=level*(select nextcoeff from coeff where coeff.score=songlistall.ranking)"
        _=db.execute(sql: sql2)
    }
    
    func getscorebytitlendifficulty(title:String,dif:String)->Int{
        let sql="select ranking from songlistall where title='\(title)' and difficulty='\(dif)'"
        let res=db.query(sql: sql)
        if res.count>0{
            let score=res[0]["ranking"] as! Int
            return(score)
        }
        return(0)
    }
    
    func updatesourcedata(withscores:Bool=false){
//        _=db.execute(sql: ".separator ','")
//        _=db.execute(sql: ".import waccarate.csv updatesongs")
        
        do{
            try importCSV()
        }catch {
            print(Error.self)
        }
        
        _=db.execute(sql: "update songlistall set level=(select level from updatesongs where updatesongs.songid=songlistall.songid) ,highestrate=(select highestrate from updatesongs where updatesongs.songid=songlistall.songid),group0=(select group0 from updatesongs where updatesongs.songid=songlistall.songid) ")
        if withscores{
            _=db.execute(sql: "update songlistall set ranking=(select ranking from updatesongs where updatesongs.songid=songlistall.songid)")
        }
        

        
        let sqlinsert="insert into songlistall select songid,title,difficulty,level,highestrate,realrate,nextrate,ranking,group0 from updatesongs where songid not in(select songid from songlistall)"
        _=db.execute(sql: sqlinsert)
        
        
        
        let sqldel="delete from songlistall where songid not in(select songid from updatesongs)"
        _=db.execute(sql: sqldel)
    }
    
    
    func importCSV() throws {
        print("getting update from csv")
        loadCSVfrombundle()
        let path0 = NSHomeDirectory() + "/Documents/waccarate.csv"
        print(path0)
        let importfile=try CSV.init(path:path0)
        let sqlclean="delete from updatesongs"
        _=db.execute(sql: sqlclean)
        var songid,ranking:Int
        var title,difficulty,group0:String
        var level,highestrate,realrate,nextrate:Double
        for i in 0...importfile.numberOfRows-1{
            songid=Int(importfile.rows[i]["songid"]!)!
            ranking=Int(importfile.rows[i]["ranking"]!)!
            title=importfile.rows[i]["title"]!
            difficulty=importfile.rows[i]["difficulty"]!
            group0=importfile.rows[i]["group0"]!
            level=Double(importfile.rows[i]["level"]!)!
            highestrate=Double(importfile.rows[i]["highestrate"]!)!
            realrate=Double(importfile.rows[i]["realrate"]!)!
            nextrate=Double(importfile.rows[i]["nextrate"]!)!
            let sqlupdate="insert into updatesongs (songid,title,difficulty ,level,highestrate,realrate,nextrate,ranking,group0) values (\(songid),\"\(title)\",\"\(difficulty)\",\(level),\(highestrate),\(realrate),\(nextrate),\(ranking),\"\(group0)\")"
            db.execute(sql: sqlupdate)
            
        }
        print("import succeeded")
        
    }
    
    
    func loadCSVfrombundle(){
        let path = Bundle.main.path(forResource: "waccarate.csv", ofType: nil)!
        let filePath = NSHomeDirectory() + "/Documents/waccarate.csv"
        if !FileManager.default.fileExists(atPath: filePath, isDirectory: .none) {
            try? FileManager.default .copyItem(atPath: path, toPath: filePath)
        } else {
        }
    }
    
    
}



class CSV {
    let newLine: String = "\n"

    let csvData: String
    let delimiter: String
    var headers: [String]
    var columns: [String: [String]]
    var rows: [[String: String]]
    var lines: [String]
    var numberOfColumns: Int
    var numberOfRows: Int

    public init(with: String, delimiter: String = ",") {
        csvData = with.replacingOccurrences(of: "\r", with: "", options: NSString.CompareOptions.literal, range: nil)
        self.delimiter = delimiter
        headers = [String]()
        columns = [String: [String]]()
        rows = [[String: String]]()
        lines = [String]()
        numberOfColumns = 0
        numberOfRows = 0

        read()

    }

    public convenience init(path: String, delimiter: String = ",", encoding: String.Encoding = .utf8) throws {
        
            let contents = try String(contentsOfFile: path, encoding: encoding)
            self.init(with: contents, delimiter: delimiter)


    }

    func read() {
        processLines(csvData)

        numberOfColumns = lines[0].components(separatedBy: delimiter).count//获取列数

        numberOfRows = lines.count - 1//获取行数

        headers = lines[0].components(separatedBy: delimiter)//第一行为表头

        setRows()

        setColumns()

    }

    //按行分割

    fileprivate func processLines(_ csv: String) {
        lines = csv.components(separatedBy: "\n")

        // Remove blank lines

        var i = 0

        for line in lines {
            if line.isEmpty {
                lines.remove(at: i)

                i -= 1

            }

            i += 1

        }

    }

//获取每一行的数据

    fileprivate func setRows() {
        var rows = [[String: String]]()

        for i in 1...numberOfRows {
            var row = [String: String]()

            let vals = lines[i].components(separatedBy: delimiter)

            var i = 0

            for header in headers {
                row[header] = vals[i]

                i+=1

            }

            rows.append(row)

        }

        self.rows = rows

    }

//每一列的数据获取

    fileprivate func setColumns() {
        var columns = [String: [String]]()

        for header in headers {
            var colValue = [String]()

            for row in rows {
                colValue.append(row[header]!)

            }

            columns[header] = colValue

        }

        self.columns = columns

    }

 

}
