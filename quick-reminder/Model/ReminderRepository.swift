//
//  ReminderRepository.swift
//  quick-reminder
//
//  Created by 垣本 桃弥 on 2023/09/08.
//

import RealmSwift

protocol ReminderRepositoryDelegate {
    func addReminder(_ reminder: Reminder)
    func updateReminder(_ reminder: Reminder)
    func deleteReminder(_ reminder: Reminder)
    func getAllReminders() -> [Reminder]
    func getReminder(withID id: String) -> Reminder?
}

final class ReminderRepository: ReminderRepositoryDelegate {
    private let realm: Realm

    init() {
        realm = try! Realm()
    }

    func addReminder(_ reminder: Reminder) {
        let reminderDTO = ReminderDTO(from: reminder)
        try? realm.write {
            realm.add(reminderDTO)
        }
    }

    func updateReminder(_ reminder: Reminder) {
        let reminderDTO = ReminderDTO(from: reminder)
        try? realm.write {
            realm.add(reminderDTO, update: .modified)
        }
    }

    func deleteReminder(_ reminder: Reminder) {
        let id = reminder.id
        let reminderDTO = realm.object(ofType: ReminderDTO.self, forPrimaryKey: id)!
        try? realm.write {
            realm.delete(reminderDTO)
        }
    }

    func getAllReminders() -> [Reminder] {
        let reminderDTOs = Array(realm.objects(ReminderDTO.self))
        return reminderDTOs.map { $0.convertToReminder() }
    }

    func getReminder(withID id: String) -> Reminder? {
        let reminderDTO = realm.object(ofType: ReminderDTO.self, forPrimaryKey: id)
        return reminderDTO?.convertToReminder()
    }
    
}
