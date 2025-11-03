class UserImportJob < ApplicationJob
  queue_as :default

  def perform(user_import_id)
    user_import = UserImport.find(user_import_id)
    service = UserImports::CreateService.new(user_import)
    service.call
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("UserImport #{user_import_id} not found")
  rescue StandardError => e
    Rails.logger.error("Error processing UserImport #{user_import_id}: #{e.message}")
    user_import&.update(status: :failed)
  end
end

