# frozen_string_literal: true

class SkillLoaderTool < SyntheticTool
  description "Search and load a skill relevant to the current task. Returns the skill content and lists any sub-documents (scripts, references) you can load with ReadDocumentTool."

  param :query, type: "string", desc: "What you need help with or want to do", required: true

  def execute(query:)
    skills = available_skills
    return "No skills available." if skills.empty?

    results = semantic_search(query, skills)
    return "No matching skills found." if results.empty?

    results.map { |skill| format_skill(skill) }.join("\n\n---\n\n")
  end

  private

  def available_skills
    @synthetic.synthetic_class&.skills&.top_level || Document.none
  end

  def semantic_search(query, skills)
    results = Document.semantic_search(query, limit: 3).where(id: skills.select(:id))
    return results if results.any?

    skills.search(query).limit(3)
  rescue => e
    Rails.logger.warn("Skill semantic search failed, falling back to text: #{e.message}")
    skills.search(query).limit(3)
  end

  def format_skill(skill)
    output = "# #{skill.title}\n\n#{skill.content}"

    if skill.children.any?
      output += "\n\n## Sub-documents\n"
      skill.children.each do |child|
        output += "- [#{child.id}] #{child.title} (#{child.category})\n"
      end
      output += "\nUse ReadDocumentTool to load any sub-document by its ID."
    end

    output
  end
end
