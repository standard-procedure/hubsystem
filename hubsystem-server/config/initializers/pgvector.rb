require "pgvector"

# Custom ActiveRecord type for pgvector embeddings.
# The native :vector name conflicts with ActiveRecord's internal OID::Vector type.
# We register as :embedding_vector to avoid the clash.
class EmbeddingVectorType < ActiveRecord::Type::Value
  def cast(value)
    return nil if value.nil?
    case value
    when Array then value
    when String then Pgvector::Vector.from_text(value).to_a
    else value
    end
  end

  def serialize(value)
    return nil if value.nil?
    arr = Array(value)
    return nil if arr.empty?
    "[#{arr.map(&:to_f).join(',')}]"
  end

  def deserialize(value)
    return nil if value.nil?
    return value if value.is_a?(Array)
    Pgvector::Vector.from_text(value).to_a
  rescue StandardError
    nil
  end
end

ActiveRecord::Type.register(:embedding_vector, EmbeddingVectorType)
