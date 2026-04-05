Gem::Specification.new do |spec|
  spec.name = "hub_system"
  spec.version = "0.1.0"
  spec.authors = ["Rahoul Baruah"]
  spec.summary = "Shared core for HubSystem applications"

  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile"]
  end

  spec.add_dependency "rails", "~> 8.1"
  spec.add_dependency "literal", "~> 1.9"
  spec.add_dependency "standard_procedure_has_attributes"
end
