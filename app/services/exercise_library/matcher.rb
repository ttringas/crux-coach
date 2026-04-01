module ExerciseLibrary
  class Matcher
    STOPWORDS = %w[and the a an of for with to in on at drill drills exercise exercises training workout].freeze
    THRESHOLD = 0.5

    EntryIndex = Struct.new(:entry, :normalized_name, :tokens, :normalized_full, keyword_init: true)

    def initialize(entries: ExerciseLibraryEntry.all)
      @entries = entries.map do |entry|
        normalized_name = normalize(entry.name)
        normalized_full = normalize([ entry.searchable_text, entry.name ].compact.join(" "))
        tokens = tokenize(normalized_full)
        EntryIndex.new(entry: entry, normalized_name: normalized_name, tokens: tokens, normalized_full: normalized_full)
      end
    end

    def match(name)
      normalized_query = normalize(name)
      return nil if normalized_query.blank?

      query_tokens = tokenize(normalized_query)
      return nil if query_tokens.empty?

      exact = @entries.find { |indexed| indexed.normalized_name == normalized_query }
      return exact.entry if exact

      best = nil
      best_score = 0.0

      @entries.each do |indexed|
        score = similarity_score(query_tokens, normalized_query, indexed)
        next if score <= best_score

        best_score = score
        best = indexed.entry
      end

      best_score >= THRESHOLD ? best : nil
    end

    def match_exercises(exercises)
      matches = {}
      Array(exercises).each_with_index do |exercise, index|
        name = exercise["name"] || exercise["title"]
        match = match(name)
        matches[index] = match if match
      end
      matches
    end

    private

    def similarity_score(query_tokens, normalized_query, indexed)
      return 0.0 if indexed.tokens.empty?

      overlap = (query_tokens & indexed.tokens).length
      base = overlap.to_f / query_tokens.length

      if indexed.normalized_full.include?(normalized_query) || normalized_query.include?(indexed.normalized_name)
        base += 0.15
      end

      [ base, 1.0 ].min
    end

    def normalize(text)
      text.to_s.downcase
          .gsub("&", " and ")
          .gsub(/[^a-z0-9\s]/, " ")
          .split
          .reject { |token| STOPWORDS.include?(token) }
          .join(" ")
    end

    def tokenize(text)
      text.to_s.split.uniq
    end
  end
end
