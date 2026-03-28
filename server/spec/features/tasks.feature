Feature: Tasks

  Scenario: Viewing tasks assigned to me
    Given I have logged in as Alice
    And there are tasks assigned to me
    When I view my tasks
    Then I should see tasks assigned to me
    And completed tasks should not be shown

  Scenario: Viewing tasks I have created
    Given I have logged in as Alice
    And I have created some tasks
    When I view my tasks
    And I switch to the created tab
    Then I should see tasks I have created

  Scenario: Creating a task
    Given I have logged in as Alice
    When I view my tasks
    And I create a new task called "Deploy to production"
    Then I should see the task "Deploy to production"

  Scenario: Creating a subtask
    Given I have logged in as Alice
    And there is a task called "Release v2"
    When I view that task
    And I add a subtask called "Run tests"
    Then the task should have a subtask called "Run tests"

  Scenario: Creating a reminder
    Given I have logged in as Alice
    When I view my tasks
    And I create a new task called "Check on deployment" with a due date
    Then I should see the task "Check on deployment" with its due date

  Scenario: Creating a repeating task
    Given I have logged in as Alice
    When I view my tasks
    And I create a repeating task called "Daily standup" with schedule "0 9 * * *"
    Then I should see the task "Daily standup" marked as repeating

  Scenario: Assigning a task
    Given I have logged in as Alice
    And there is an unassigned task called "Review PR"
    When I view that task
    And I assign the task to Bob
    Then the task should be assigned to Bob

  Scenario: Completing a task
    Given I have logged in as Alice
    And there are tasks assigned to me
    When I view my tasks
    And I view the first assigned task
    And I complete the task
    Then the task should be marked as completed

  Scenario: Cancelling a task
    Given I have logged in as Alice
    And there are tasks assigned to me
    When I view my tasks
    And I view the first assigned task
    And I cancel the task
    Then the task should be marked as cancelled

  Scenario: Viewing task summary on dashboard
    Given I have logged in as Alice
    And there are tasks assigned to me
    Then I should see a task summary on the dashboard
