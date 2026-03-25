# Development Process

## Development Principles

This project follows strict test-driven development with dual web/API feature parity.

### Outside-In TDD with Dual Web/API Steps

Feature Parity - all features must work via **both** web UI and API:

```
spec/features/
  ├── participants.feature            # Gherkin feature spec
  └── steps/
      ├── participants_steps.rb       # Common steps
      ├── web/
      │   └── participants_steps.rb   # Web UI steps (Playwright)
      └── api/
          └── participants_steps.rb   # API steps (request specs)
```

**Example feature:**
```gherkin
Feature: Administrator creates a participant
  Scenario: Successfully
    Given I am logged in as an admin
    When I create a participant named "Alice"
    Then I should see "Alice" in the participants list
```

```ruby
# steps/participant_steps.rb 
module ParticipantSteps 

end

# steps/web/participant_steps.rb 
module ParticipantSteps 
  step "I create a participant named :name" do |name|
    click_on "Add participant"
    fill_in "Name", with: "Alice"
    click_on "Add"
  end
  step "I should see :name in the participants list" do |name|
    expect(page).to have_text(CGI.html_escape(name))
  end 
end

# steps/api/participant_steps.rb
module ParticipantSteps 
  step "I create a participant named :name" do |name|
    post api_participants_path, params: {participant: {name: "Alice"} }, headers: {"Authorization" => "Bearer #{@token}" }
    expect(response),to eq 201 
  end
  step "I should see :name in the participants list" do |name|
    get api_participants_path, headers: {"Authorization" => "Bearer #{@token}" }
    expect(response).to eq 200 
    data = JSON.parse(response.body)
    participant = data.find { |d| d["name"] == name }
    expect(participant).not_to be_nil 
  end 
end
```
`spec/turnip_helper.rb` dynamically loads modules containing the steps, based on the `TEST_INTERFACE` environment variable.  
Every feature **must** have a common steps module, even if it is empty.
If a step is not relevant to the API (for example, navigation) then an empty step is used.

## Development Workflow

Some steps will be performed by humans, others by coding agents, others by collaboration between the two.

1. Understand the requirement and the user journeys (happy path, blank slate, alternative options, error handling)
2. Write or amend the feature specifications with scenarios for each user journey
3. Plan the implementation, starting with the user/client's perspective and working inwards
4. Implement the code: for each step, write a failing test, make it pass, lint and refactor
5. Run the full test suite and fix any regressions
6. Commit the changes
7. Perform a code review and fix issues:
  * Do the specifications and tests actually meet the original request?
  * Are there security/authorisation/data-leak risks?
  * Is there duplication which can be consolidated?
  * Is there scope for simplification or code removal?
8. Commit and push

```bash
# 1. Write feature spec (both web + API scenarios)
# spec/features/my_feature.feature

# 2. Write step definitions
# spec/features/steps/my_steps.rb # shared steps - always required to load the module into the test suite
# spec/features/steps/web/my_steps.rb # web specific steps extending the feature module
# spec/features/steps/api/my_steps.rb # API specific steps extending the feature module

# 3. Run specs (RED)
bundle exec rspec spec/features/my_feature.feature

# 4. Implement (controller, model, view component)

# 5. Run until green
bundle exec rspec

# 6. Lint
bundle exec standardrb --fix

# 7. Code Review 
# Use the superpowers:requesting-code-review skill to review the changes made

# 7. Update OpenAPI
OPENAPI=1 bundle exec rspec spec/requests/
```
