//
//  ChangeHistoryEntry.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Foundation

struct ChangeHistoryEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var taskId: UUID
    var editedBy: UUID
    var editedByName: String? // For display
    var editedAt: Date
    var fieldChanged: String
    var oldValue: String
    var newValue: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case editedBy = "edited_by"
        case editedByName = "edited_by_name"
        case editedAt = "edited_at"
        case fieldChanged = "field_changed"
        case oldValue = "old_value"
        case newValue = "new_value"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        editedBy: UUID,
        editedByName: String? = nil,
        editedAt: Date = Date(),
        fieldChanged: String,
        oldValue: String,
        newValue: String
    ) {
        self.id = id
        self.taskId = taskId
        self.editedBy = editedBy
        self.editedByName = editedByName
        self.editedAt = editedAt
        self.fieldChanged = fieldChanged
        self.oldValue = oldValue
        self.newValue = newValue
    }
    
    // MARK: - Formatted Display
    
    var formattedChange: String {
        "\(fieldChanged): \(oldValue) → \(newValue)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: editedAt)
    }
}
