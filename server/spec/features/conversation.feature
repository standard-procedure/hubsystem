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
    
  Scenario: Returning to an existing conversation
    
  Scenario: Ending a conversation