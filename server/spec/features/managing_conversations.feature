Feature: Managing conversations

  Scenario: Starting a new conversation

    Given I am logged in
    When I start a new conversation
    And I search for a user
    And I select a user to talk to
    And I fill in the subject and message
    And I send the conversation
    Then I should see the new conversation with my message

  Scenario: Sending a message in a conversation

    Given I am logged in
    And I have an active conversation
    When I view the conversation
    And I send a message
    Then I should see my message in the conversation

  Scenario: Closing a conversation

    Given I am logged in
    And I have an active conversation
    When I view the conversation
    And I close the conversation
    Then the conversation should be archived
