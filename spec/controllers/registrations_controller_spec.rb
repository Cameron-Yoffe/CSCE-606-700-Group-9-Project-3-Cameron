require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  describe '#destroy' do
    before do
      # Add route for this test only
      @routes = ActionDispatch::Routing::RouteSet.new
      @routes.draw do
        delete 'registrations/destroy' => 'registrations#destroy'
        root to: 'pages#home'
      end
      @controller.instance_variable_set(:@_routes, @routes)
    end

    it 'clears the session' do
      session[:user_id] = 123
      delete :destroy
      expect(session[:user_id]).to be_nil
    end

    it 'redirects to root path' do
      delete :destroy
      expect(response).to redirect_to('/')
    end

    it 'sets logout flash notice' do
      delete :destroy
      expect(flash[:notice]).to eq("You have been logged out.")
    end
  end
end
