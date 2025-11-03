require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_length_of(:full_name).is_at_least(2).is_at_most(100) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'associations' do
    it { is_expected.to have_many(:user_imports).dependent(:destroy) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, admin: 1) }
  end

  describe '#admin?' do
    context 'when user is admin' do
      let(:user) { create(:user, :admin) }

      it 'returns true' do
        expect(user.admin?).to be true
      end
    end

    context 'when user is not admin' do
      let(:user) { create(:user) }

      it 'returns false' do
        expect(user.admin?).to be false
      end
    end
  end

  describe '#display_avatar' do
    context 'when user has attached avatar' do
      let(:user) { create(:user) }

      before do
        user.avatar_image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'test.png')),
          filename: 'test.png',
          content_type: 'image/png'
        )
      end

      it 'returns attached image' do
        expect(user.display_avatar).to eq(user.avatar_image)
      end
    end

    context 'when user has avatar_url' do
      let(:user) { create(:user, :with_avatar_url) }

      it 'returns avatar_url' do
        expect(user.display_avatar).to eq(user.avatar_url)
      end
    end

    context 'when user has no avatar' do
      let(:user) { create(:user) }

      it 'returns default placeholder' do
        expect(user.display_avatar).to eq('https://via.placeholder.com/150')
      end
    end
  end
end

