require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before { sign_in admin }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns all users' do
      get :index
      expect(assigns(:users)).to include(admin, regular_user)
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            full_name: 'Test User',
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'user'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'redirects to users index' do
        post :create, params: valid_params
        expect(response).to redirect_to(admin_users_path)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          user: {
            full_name: '',
            email: 'invalid'
          }
        }
      end

      it 'does not create a user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'renders new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #toggle_role' do
    it 'toggles user role' do
      expect {
        patch :toggle_role, params: { id: regular_user.id }
        regular_user.reload
      }.to change { regular_user.role }.from('user').to('admin')
    end

    it 'prevents admin from changing own role' do
      patch :toggle_role, params: { id: admin.id }
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the user' do
      user_to_delete = create(:user)
      expect {
        delete :destroy, params: { id: user_to_delete.id }
      }.to change(User, :count).by(-1)
    end

    it 'prevents admin from deleting own account' do
      delete :destroy, params: { id: admin.id }
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end
end

