require 'rails_helper'

RSpec.describe RegistrationsController, type: :request do
  describe 'GET /sign_up' do
    it 'renders the sign-up form' do
      get sign_up_path
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end

    it 'assigns a new user' do
      get sign_up_path
      expect(assigns(:user)).to be_a_new(User)
    end

    it 'redirects to dashboard if already logged in' do
      user = create(:user)
      post sign_up_path, params: {
        user: {
          email: 'logged_in@example.com',
          username: 'loggedin123',
          password: 'LoggedIn123',
          password_confirmation: 'LoggedIn123'
        }
      }
      # At this point, a user should be logged in
      get sign_up_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'POST /sign_up' do
    let(:valid_attributes) do
      {
        email: 'newuser@example.com',
        username: 'newuser123',
        first_name: 'John',
        last_name: 'Doe',
        password: 'StrongPass123',
        password_confirmation: 'StrongPass123'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post sign_up_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'creates user with correct attributes' do
        post sign_up_path, params: { user: valid_attributes }
        user = User.last
        expect(user.email).to eq('newuser@example.com')
        expect(user.username).to eq('newuser123')
        expect(user.first_name).to eq('John')
        expect(user.last_name).to eq('Doe')
      end

      it 'logs in the user' do
        post sign_up_path, params: { user: valid_attributes }
        expect(session[:user_id]).to eq(User.last.id)
      end

      it 'redirects to dashboard' do
        post sign_up_path, params: { user: valid_attributes }
        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets success flash notice' do
        post sign_up_path, params: { user: valid_attributes }
        follow_redirect!
        expect(flash[:notice]).to include("Account created successfully")
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user with invalid email' do
        attrs = valid_attributes.merge(email: 'invalid-email')
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'does not create a user with duplicate email' do
        create(:user, email: 'existing@example.com')
        attrs = valid_attributes.merge(email: 'existing@example.com')
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'does not create a user with duplicate username' do
        create(:user, username: 'existinguser')
        attrs = valid_attributes.merge(username: 'existinguser')
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'does not create a user with weak password' do
        attrs = valid_attributes.merge(password: 'weak', password_confirmation: 'weak')
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'does not create a user with mismatched passwords' do
        attrs = valid_attributes.merge(password_confirmation: 'DifferentPass123')
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'does not create a user without password confirmation' do
        attrs = valid_attributes.merge(password_confirmation: '')
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'renders the form with errors' do
        attrs = valid_attributes.merge(email: 'invalid-email')
        post sign_up_path, params: { user: attrs }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
        expect(assigns(:user).errors).to be_present
      end

      it 'displays error messages' do
        attrs = valid_attributes.merge(email: 'invalid-email')
        post sign_up_path, params: { user: attrs }
        expect(response.body).to include('error')
      end
    end

    context 'password strength validation' do
      it 'rejects password without uppercase' do
        attrs = valid_attributes.merge(
          password: 'lowercase123',
          password_confirmation: 'lowercase123'
        )
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'rejects password without lowercase' do
        attrs = valid_attributes.merge(
          password: 'UPPERCASE123',
          password_confirmation: 'UPPERCASE123'
        )
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'rejects password without numbers' do
        attrs = valid_attributes.merge(
          password: 'NoNumbers!',
          password_confirmation: 'NoNumbers!'
        )
        expect {
          post sign_up_path, params: { user: attrs }
        }.not_to change(User, :count)
      end

      it 'accepts strong password with all requirements' do
        expect {
          post sign_up_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end
    end
  end
end
