//
//  TaskManager.swift
//  Pods
//
//  Created by Michel Gutner on 15/01/25.
//

import Foundation

class TaskManager {
  static let shared = TaskManager()
  private var tasks: [String: Task<Void, Never>] = [:]
  private let queue = DispatchQueue(label: "com.taskmanager.queue", attributes: .concurrent)
  
  private init() {}
  
  func addTask(id: String, task: Task<Void, Never>) {
    queue.async(flags: .barrier) {
      self.tasks[id]?.cancel()
      self.tasks[id] = task
    }
  }
  
  func cancelTask(id: String) {
    queue.async(flags: .barrier) {
      self.tasks[id]?.cancel()
      self.tasks.removeValue(forKey: id)
    }
  }
  
  func cancelAllTasks() {
    appConfig.log("taskManager cancelAllTasks")
    queue.async(flags: .barrier) {
      self.tasks.values.forEach { $0.cancel() }
      self.tasks.removeAll()
    }
  }
}
