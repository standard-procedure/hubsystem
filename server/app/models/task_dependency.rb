# frozen_string_literal: true

class TaskDependency < ApplicationRecord
  belongs_to :task
  belongs_to :dependency, class_name: "Task"

  validates :dependency_id, uniqueness: {scope: :task_id}
end
