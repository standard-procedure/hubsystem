# frozen_string_literal: true

module ErrorHandlers
  extend ActiveSupport::Concern

  module Api
    extend ActiveSupport::Concern

    included do
      rescue_from StandardError, with: :exception unless Rails.env.local?
      rescue_from ActiveRecord::RecordInvalid, with: :invalid_data
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ArgumentError, with: :bad_request
    end

    private def invalid_data(error)
      render json: {error: "invalid_data", errors: error.record.errors.full_messages}, status: :unprocessable_content
    end

    private def not_found
      render json: {error: "not_found"}, status: :not_found
    end

    private def bad_request(error)
      render json: {error: "bad_request", message: error.message}, status: :bad_request
    end

    private def exception(error)
      Rails.logger.error("#{error.class}: #{error.message}\n#{error.backtrace&.first(10)&.join("\n")}")
      render json: {error: error.class.name, message: error.message}, status: :internal_server_error
    end
  end

  module Web
    extend ActiveSupport::Concern

    included do
      rescue_from StandardError, with: :exception unless Rails.env.local?
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
    end

    private def not_found
      redirect_to root_path, alert: "Not found"
    end

    private def exception(error)
      Rails.logger.error("#{error.class}: #{error.message}\n#{error.backtrace&.first(10)&.join("\n")}")
      redirect_to root_path, alert: "An unexpected error occurred"
    end
  end
end
