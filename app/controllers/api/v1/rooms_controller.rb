module Api
  module V1
    class RoomsController < ApiController
      before_action :require_admin, only: [:create]

      def index
        @rooms = Room.all
        render json: @rooms
      end

      def show
        @room = Room.find(params[:id])
        render json: @room
      end

      def create
        @room = Room.create!(room_params)
        render json: @room, status: :created
      end

      def availability
        @room = Room.find(params[:id])
        date = Date.parse(params[:date]) rescue Date.current
        
        # We find reservations for this room on this date
        # Assuming availability is a list of free slots or just a check.
        # Let's return the reservations for that day.
        @reservations = @room.reservations.active
                             .where('starts_at >= ? AND starts_at <= ?', date.beginning_of_day, date.end_of_day)
                             .order(:starts_at)
        
        render json: {
          room: @room,
          date: date,
          reservations: @reservations.map { |r| { starts_at: r.starts_at, ends_at: r.ends_at, title: r.title } }
        }
      end

      private

      def room_params
        params.require(:room).permit(:name, :capacity, :has_projector, :has_video_conference, :floor)
      end
    end
  end
end
