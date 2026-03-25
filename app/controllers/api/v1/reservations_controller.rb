module Api
  module V1
    class ReservationsController < ApiController
      def index
        @reservations = Reservation.active.order(starts_at: :desc)
        render json: @reservations
      end

      def show
        @reservation = Reservation.find(params[:id])
        render json: @reservation
      end

      def create
        # Use transaction to handle BR7 gracefully - although save! in model already does this.
        @reservation = Reservation.create!(reservation_params)
        render json: @reservation, status: :created
      end

      def cancel
        @reservation = Reservation.find(params[:id])
        @reservation.update!(cancelled_at: Time.current)
        render json: @reservation
      end

      private

      def reservation_params
        params.require(:reservation).permit(:room_id, :user_id, :title, :starts_at, :ends_at, :recurring, :recurring_until)
      end
    end
  end
end
