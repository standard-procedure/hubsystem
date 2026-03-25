# Architecture

## Users

[Users](app/model/user.rb) access the system and use inheritance to represent [humans](app/models/user/human.rb) and [synthetics](app/models/user/synthetic.rb) (controlled by LLMs).

### Humans

They can log in using [OmniAuth](config/initializers/omniauth.rb).

### Synthetics

Every synthetic uses a specific [LLM model](config/llm_models.yml), a personality and an emotional state.  
 