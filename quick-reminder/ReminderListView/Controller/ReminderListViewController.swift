//
//  ReminderListViewController.swift
//  quick-reminder
//
//  Created by 垣本 桃弥 on 2023/09/06.
//

import UIKit

final class ReminderListViewController: UIViewController {
    
    private let reminderListView = ReminderListView()
    private let noReminderView = NoReminderView()
    
    private var reminderList: ReminderListProtocol!
    private let notificationHandler: NotificationHandlerProtocol!
    private let notificationDateCalculator: NotificationDateCalculator!
    private let dateProvider: DateProviderProtocol!
    private let oldReminderRemover: OldReminderRemoverProtocol!
    
    /// テーブルビューに表示する各リマインダーの通知時刻のフォーマッタ。
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "M/d HH:mm"
        return dateFormatter
    }()
    
    init(reminderList: ReminderListProtocol,
         notificationHandler: NotificationHandlerProtocol,
         notificationDateCalculator: NotificationDateCalculator,
         dateProvider: DateProviderProtocol,
         oldReminderRemover: OldReminderRemoverProtocol) {
        self.reminderList = reminderList
        self.notificationHandler = notificationHandler
        self.notificationDateCalculator = notificationDateCalculator
        self.dateProvider = dateProvider
        self.oldReminderRemover = oldReminderRemover
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "登録中のリマインダー"
        setupNavigationBar()
        
        reminderListView.reminderTableView.dataSource = self
        reminderListView.reminderTableView.delegate = self
        
        reminderList.notificationCenter.addObserver(
            forName: .didAddReminder,
            object: nil,
            queue: nil,
            using: { [unowned self] notification in
                self.reloadView()
                notificationHandler.registerNotification(
                    reminder: notification.userInfo!["reminder"] as! Reminder
                )
            }
        )
        reminderList.notificationCenter.addObserver(
            forName: .didDeleteReminder,
            object: nil,
            queue: nil,
            using: { [unowned self] notification in
                notificationHandler.removeNotification(
                    reminder: notification.userInfo!["reminder"] as! Reminder
                )
            }
        )
        reminderList.notificationCenter.addObserver(
            forName: .didUpdateReminder,
            object: nil,
            queue: nil,
            using: { [unowned self] notification in
                self.reloadView()
                notificationHandler.registerNotification(
                    reminder: notification.userInfo!["reminder"] as! Reminder
                )
            }
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        oldReminderRemover.removeOldReminders(in: &reminderList)
        reloadView()
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = {
            let barButton = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(addButtonTapped))
            barButton.accessibilityIdentifier = "Add Reminder Bar Button"
            return barButton
        }()
    }
    
    /// ナビゲーションバーの＋ボタンが押された時の処理。
    @objc func addButtonTapped() {
        let reminder = Reminder(date: notificationDateCalculator.calculate(from: dateProvider.now))
        try! reminderList.addReminder(reminder: reminder)
        pushToReminderEditVC(reminder: reminder)
    }
    
    /// viewを更新する。
    func reloadView() {
        if reminderList.isEmpty {
            view = noReminderView
        } else {
            view = reminderListView
            reminderListView.reminderTableView.reloadData()
        }
    }
    
    /// ReminderEditViewに画面遷移する。
    ///
    /// - parameter reminder: ReminderEditViewで編集を行うReminder。
    func pushToReminderEditVC(reminder: Reminder) {
        let vc = ReminderEditViewController(
            notificationDateCalculator: NotificationDateCalculator(dateProvider: DateProvider())
        )
        vc.setup(reminder: reminder)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension ReminderListViewController: ReminderEditDelegate {
    func didEditReminder(editedReminder reminder: Reminder) {
        try? reminderList.updateReminder(reminder: reminder)
    }
}

extension ReminderListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminderList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let reminder = reminderList.getReminder(index: indexPath.row)
        let title = reminder.title
        let dateText = dateFormatter.string(from: reminder.date)
        
        var content = cell.defaultContentConfiguration()
        content.text = title
        content.secondaryText = dateText
        cell.contentConfiguration = content
        cell.backgroundColor = reminder.date <= dateProvider.now ? R.color.inactiveReminderCellBackground() : R.color.activeReminderCellBackground()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        pushToReminderEditVC(reminder: reminderList.getReminder(index: indexPath.row))
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "") { [unowned self] (action, reminderListView, completionHandler) in
            self.reminderList.deleteReminder(index: indexPath.row)
            if reminderList.isEmpty {
                self.reloadView()
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
}
