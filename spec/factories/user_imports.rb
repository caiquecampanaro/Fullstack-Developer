FactoryBot.define do
  factory :user_import do
    association :user, factory: :user, strategy: :create
    status { :pending }
    total_rows { 0 }
    processed_rows { 0 }
    success_count { 0 }
    error_count { 0 }
    error_messages { [] }

    trait :processing do
      status { :processing }
      total_rows { 10 }
      processed_rows { 5 }
    end

    trait :completed do
      status { :completed }
      total_rows { 10 }
      processed_rows { 10 }
      success_count { 10 }
      error_count { 0 }
    end

    trait :failed do
      status { :failed }
      error_messages { ['Import failed'] }
    end
  end
end

