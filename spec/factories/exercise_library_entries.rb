FactoryBot.define do
  factory :exercise_library_entry do
    name { "Weighted Pull-ups" }
    category { "strength" }
    tags { [ "pull", "strength" ] }
    youtube_video_id { "abc123" }
    video_title { "How to do weighted pull-ups" }
    channel_name { "Crux Coach" }
    description { "A quick primer on strict weighted pull-ups." }
    duration_estimate { "6 min" }
  end
end
