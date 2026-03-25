module Api
  module V1
    class UsersController < ApiController
      def index
        @users = User.all
        render json: @users
      end

      def show
        @user = User.find(params[:id])
        render json: @user
      end

      def create
        @user = User.create!(user_params)
        render json: @user, status: :created
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :department, :max_capacity_allowed, :is_admin)
      end
    end
  end
end
