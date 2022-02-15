//
//  ViewController.swift
//  taskapp
//
//  Created by 山本梨野 on 2022/02/12.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    // Realmインスタンスを取得する
    let realm = try! Realm()

    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    //searchbarのための箱
    let myRefreshControl = UIRefreshControl()
    var items = [Task]()
    var currentItems = [Task]()
    

    var category :String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //データベースのリスト数=taskArrayの要素数を返す
        //データの数=セルの数を返すメソッド
        return currentItems.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //再利用可能なセルを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //taskArrayから該当するデータを取り出してセルに設定
        // Cellに値を設定する
        let task = currentItems[indexPath.row]
        cell.textLabel?.text = task.title
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController

        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()

            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }

            inputViewController.task = task
        }
    }
    
    //各セルを選択したときに実行されるメソッド
    //UITableViewDelegateプロトコルのメソッドで、セルをタップした時にタスク入力画面に遷移させる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //UITableViewDelegateプロトコルのメソッドで、セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return.delete
    }
    
    //searchbar
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    }
    //  検索バーに入力があったら呼ばれる
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            currentItems = items
            tableView.reloadData()
            return
        } else {
        currentItems = items.filter({ item -> Bool in
            item.category.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
        }
    }
    
    
    //deleteボタンが押されたときに呼ばれるメソッド
    //UITableViewDataSourceプロトコルのメソッドで、Deleteボタンが押されたときにローカル通知をキャンセルし、データベースからタスクを削除する
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    
        if editingStyle == .delete {
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]

            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                    }
            
                }
            }
            }
    
    
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

}

