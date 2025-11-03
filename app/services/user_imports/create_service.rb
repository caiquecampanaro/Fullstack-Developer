require 'stringio'
require 'roo'

module UserImports
  class CreateService
    def initialize(user_import)
      @user_import = user_import
    end

    def call
      parse_spreadsheet
    rescue StandardError => e
      handle_error(e)
    end

    private

    attr_reader :user_import

    def parse_spreadsheet
      file = user_import.spreadsheet_file.download
      spreadsheet = Roo::Spreadsheet.open(StringIO.new(file), extension: file_extension)

      header_row = spreadsheet.row(1)
      validate_header(header_row)

      total_rows = spreadsheet.last_row - 1
      user_import.update(total_rows: total_rows, status: :processing)

      process_rows(spreadsheet, header_row, total_rows)
    end

    def file_extension
      case user_import.spreadsheet_file.blob.content_type
      when 'text/csv'
        :csv
      when 'application/vnd.ms-excel'
        :xls
      when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        :xlsx
      else
        :xlsx
      end
    end

    def validate_header(header_row)
      required_columns = ['full_name', 'email']
      missing_columns = required_columns - header_row.map(&:to_s).map(&:downcase)

      return if missing_columns.empty?

      raise ArgumentError, "Missing required columns: #{missing_columns.join(', ')}"
    end

    def process_rows(spreadsheet, header_row, total_rows)
      success_count = 0
      error_count = 0
      error_messages = []

      (2..spreadsheet.last_row).each do |row_num|
        row = spreadsheet.row(row_num)
        next if row.all?(&:blank?)

        user_data = build_user_data(row, header_row)
        create_user(user_data, row_num, error_messages) ? success_count += 1 : error_count += 1

        user_import.update(
          processed_rows: row_num - 1,
          success_count: success_count,
          error_count: error_count,
          error_messages: error_messages
        )

        broadcast_progress(row_num - 1, total_rows)
      end

      user_import.update(status: :completed)
      broadcast_completion
    rescue StandardError => e
      user_import.update(status: :failed)
      raise e
    end

    def build_user_data(row, header_row)
      data = {}
      header_row.each_with_index do |header, index|
        key = header.to_s.downcase.strip
        value = row[index]&.to_s&.strip

        case key
        when 'full_name', 'full name', 'name'
          data[:full_name] = value
        when 'email', 'e-mail'
          data[:email] = value
        when 'role', 'user_role'
          data[:role] = value&.downcase == 'admin' ? :admin : :user
        when 'avatar_url', 'avatar', 'avatar url'
          data[:avatar_url] = value
        end
      end

      data[:role] ||= :user
      data
    end

    def create_user(user_data, row_num, error_messages)
      user = User.new(user_data)
      user.password = Devise.friendly_token[0, 20] if user.password.blank?

      if user.save
        true
      else
        error_messages << "Row #{row_num}: #{user.errors.full_messages.join(', ')}"
        false
      end
    rescue StandardError => e
      error_messages << "Row #{row_num}: #{e.message}"
      false
    end

    def broadcast_progress(processed, total)
      ActionCable.server.broadcast(
        "import_progress_#{user_import.id}",
        {
          type: 'progress',
          processed_rows: processed,
          total_rows: total,
          progress: ((processed.to_f / total) * 100).round(2)
        }
      )
    end

    def broadcast_completion
      ActionCable.server.broadcast(
        "import_progress_#{user_import.id}",
        {
          type: 'completed',
          status: user_import.status,
          success_count: user_import.success_count,
          error_count: user_import.error_count
        }
      )
    end

    def handle_error(error)
      user_import.update(
        status: :failed,
        error_messages: user_import.error_messages + [error.message]
      )
      broadcast_error(error)
    end

    def broadcast_error(error)
      ActionCable.server.broadcast(
        "import_progress_#{user_import.id}",
        {
          type: 'error',
          message: error.message
        }
      )
    end
  end
end

