Feature: Viewing my messages
  
  Scenario: Viewing my unread messages 
    
    Given I have had a number of conversations over a period of time
    When I log in
    Then I should see a count of my unread messages on the dashboard 
    When I go to the messages tab
    Then I should only see my unread messages
    When I select one of the unread messages
    Then I should see the conversation containing the message
    
  Scenario: Searching for a message 

    Given I have had a number of conversations over a period of time
    When I log in
    And I go to the messages tab
    And I search for part of a previous message
    Then I should see the conversations and matching messages
    When I select one of the matching messages
    Then I should see the conversation containing the message

  Scenario: Searching for a conversation with a user

    Given I have had a number of conversations over a period of time
    When I log in
    And I go to the messages tab
    And I search for the name of a user
    Then I should see the conversations I have had with that user
    When I select one of the conversations
    Then I should see the conversation and its messages

  Scenario: Viewing active conversations
    
    Given I have had a number of conversations over a period of time
    When I log in
    And I go to the messages tab
    And I view my conversations
    When I select one of the conversations
    Then I should see the conversation and its messages
        
  Scenario: Viewing archived conversations

    Given I have had a number of conversations over a period of time
    When I log in
    And I go to the messages tab
    And I view my archived conversations
    When I select one of the conversations
    Then I should see the conversation and its messages
    