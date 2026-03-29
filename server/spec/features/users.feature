Feature: Users
  Scenario: Viewing users
    Given I have logged in as Alice
    When I view the users page
    Then I should see a list of users
    And each user should show their status

  Scenario: Searching for a user
    Given I have logged in as Alice
    When I view the users page
    And I search for "Bishop"
    Then I should see Bishop in the results
    And I should not see Bob in the results

  Scenario: Viewing a user profile
    Given I have logged in as Alice
    When I view Bishop's profile
    Then I should see Bishop's details
    And I should see Bishop is a Synthetic

  Scenario: Adding a private note
    Given I have logged in as Alice
    When I view Bishop's profile
    And I add a private note "Helpful for code review"
    Then I should see my note on Bishop's profile

  Scenario: Starting a conversation from a user profile
    Given I have logged in as Alice
    When I view Bob's profile
    And I start a conversation with subject "Quick question"
    Then a conversation request should be sent to Bob
