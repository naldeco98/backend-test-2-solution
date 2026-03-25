module Api
  module V1
    class ApiController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      def current_user
        @current_user ||= User.find_by(id: request.headers['X-User-Id'])
      end

      def require_admin
        render_error('Forbidden', :forbidden) unless current_user&.admin?
      end

      def render_error(message, status)
        render json: { error: message }, status: status
      end

      private

      def not_found
        render_error('Record not found', :not_found)
      end

      def unprocessable_entity(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
