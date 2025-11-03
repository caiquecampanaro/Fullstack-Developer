require 'rails_helper'

RSpec.describe UserImport, type: :model do
  describe 'validations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:spreadsheet_file) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processing: 1, completed: 2, failed: 3) }
  end

  describe '#progress_percentage' do
    context 'when total_rows is zero' do
      let(:import) { create(:user_import, total_rows: 0) }

      it 'returns 0' do
        expect(import.progress_percentage).to eq(0)
      end
    end

    context 'when processed_rows is less than total_rows' do
      let(:import) { create(:user_import, total_rows: 10, processed_rows: 5) }

      it 'returns correct percentage' do
        expect(import.progress_percentage).to eq(50.0)
      end
    end
  end

  describe '#finished?' do
    context 'when status is completed' do
      let(:import) { create(:user_import, :completed) }

      it 'returns true' do
        expect(import.finished?).to be true
      end
    end

    context 'when status is failed' do
      let(:import) { create(:user_import, :failed) }

      it 'returns true' do
        expect(import.finished?).to be true
      end
    end

    context 'when status is processing' do
      let(:import) { create(:user_import, :processing) }

      it 'returns false' do
        expect(import.finished?).to be false
      end
    end
  end
end

