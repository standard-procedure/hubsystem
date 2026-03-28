Feature: Conversation
  
  Scenario: Starting a conversation
    Given I have logged in as Alice 
    When I ask Bob to start a conversation
    And Bob accepts the request
    And I send Bob a message
    Then Bob should receive my message
    When Bob replies to the message
    Then I should receive Bob's message
    
  Scenario: Rejecting a conversation request
    Given I have logged in as Alice 
    And I have some existing conversations
    And Bob has sent me a conversation request
    When I view my messages
    Then I should see my existing conversations
    And any conversations with unread messages should be highlighted in amber
    And I should see the conversation request from Bob highlighted in red
    When I view the conversation request
    And I reject the request 
    Then Bob should receive my rejection 
    And the conversation should be closed

  Scenario: Rejecting a conversation request from the dashboard
    Given I have logged in as Alice 
    And I have some existing conversations
    And Bob has sent me a conversation request
    When I view the dashboard
    Then conversations with unread messages should be represented by an amber cell
    And my conversation request from Bob should be represented by a red cell
    When I view the conversation request
    And I reject the request 
    Then Bob should receive my rejection 
    And the conversation should be closed

  Scenario: Returning to an existing conversation
    Given I have logged in as Alice 
    And I have some existing conversations
    And I have an existing conversation with Bob
    When I view my messages
    Then I should see my existing conversations
    And my conversations with unread messages should be highlighted in amber
    When I click on the conversation with Bob
    Then I should see the previous messages between Bob and me
    When I send Bob a message
    Then Bob should receive my message
    When Bob replies to the message
    Then I should receive Bob's message
    
  Scenario: Returning to an existing conversation from the dashboard
    Given I have logged in as Alice 
    And I have some existing conversations
    And I have an existing conversation with Bob
    When I view the dashboard 
    Then I should see my existing conversations in a status matrix
    And conversations with unread messages should be represented by an amber cell
    When I click on the conversation with Bob
    Then I should see the previous messages between Bob and me
    When I send Bob a message
    Then Bob should receive my message
    When Bob replies to the message
    Then I should receive Bob's message
    
  Scenario: Ending a conversation
    Given I have logged in as Alice 
    And I have some existing conversations
    And I have an existing conversation with Bob
    When I view my messages
    Then I should see my existing conversations
    And my conversations with unread messages should be highlighted in amber
    When I click on the conversation with Bob
    Then I should see the previous messages between Bob and me
    When I close the conversation 
    Then the conversation should be closed 
    When I view my messages
    Then I should not see the conversation with Bob 
    When I view my archived messages
    Then I should see the conversation with Bob 
    When I view my dashboard 
    Then the conversation with Bob should be represented by a greyed out cell
    When I return to my dashboard a day later 
    Then the conversation with Bob should not be visible in the conversation matrix
