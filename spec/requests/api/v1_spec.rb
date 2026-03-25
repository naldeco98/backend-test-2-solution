require 'rails_helper'

RSpec.describe 'API V1 Endpoints', type: :request do
  let!(:admin) { create(:user, is_admin: true) }
  let!(:user) { create(:user, is_admin: false, max_capacity_allowed: 10) }
  let!(:room) { create(:room, capacity: 5) }
  let(:headers) { { 'X-User-Id' => admin.id.to_s, 'Content-Type' => 'application/json' } }
  let(:future_monday) { Time.zone.parse('2026-03-30 10:00:00') }

  describe 'Rooms API' do
    it 'lists rooms' do
      get '/api/v1/rooms'
      expect(response).to have_http_status(:ok)
    end

    it 'creates a room (admin only)' do
      post '/api/v1/rooms', params: { room: { name: 'Conference A', capacity: 20 } }.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'forbids room creation for non-admins' do
      post '/api/v1/rooms', params: { room: { name: 'Restricted' } }.to_json, headers: { 'X-User-Id' => user.id.to_s }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'Reservations API' do
    it 'creates a reservation' do
      post '/api/v1/reservations', params: { 
        reservation: { 
          room_id: room.id, user_id: user.id, 
          starts_at: future_monday, ends_at: future_monday + 1.hour 
        } 
      }.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end

    it 'fails creation if BR validation fails (e.g. overlap)' do
      create(:reservation, room: room, user: user, starts_at: future_monday, ends_at: future_monday + 1.hour)
      
      # Try to create overlapping
      post '/api/v1/reservations', params: { 
        reservation: { 
          room_id: room.id, user_id: admin.id, 
          starts_at: future_monday + 30.minutes, ends_at: future_monday + 90.minutes 
        } 
      }.to_json, headers: headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to include('Room is already booked for this time')
    end

    it 'cancels a reservation (BR6)' do
      res = create(:reservation, room: room, user: user, starts_at: future_monday + 2.hours, ends_at: future_monday + 3.hours)
      patch "/api/v1/reservations/#{res.id}/cancel", headers: headers
      expect(response).to have_http_status(:ok)
      expect(res.reload.cancelled_at).to be_present
    end

    it 'fails cancellation if too late (BR6)' do
      too_late = Time.current + 30.minutes
      res = create(:reservation, room: room, user: user, starts_at: too_late, ends_at: too_late + 1.hour)
      patch "/api/v1/reservations/#{res.id}/cancel", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
