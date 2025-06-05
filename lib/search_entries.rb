# frozen_string_literal: true

module SearchEntries
  TRANSLITERATIONS =
    I18n::Backend::Transliterator::HashTransliterator::DEFAULT_APPROXIMATIONS.reject { |_, v| v.length > 1 }

  MAX_VALUE_LENGTH = 100

  UUID_REGEXP = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  FIELD_SEARCH_QUERY_SQL = <<~SQL.squish
    tsvector @@ (quote_literal(coalesce((ts_lexize('english_stem', :keyword))[1], :keyword)) || ':*' || :weight)::tsquery
  SQL

  module_function

  def reindex_all
    Submitter.find_each { |submitter| index_submitter(submitter) }
    Submission.find_each { |submission| index_submission(submission) }
    Template.find_each { |template| index_template(template) }
  end

  def enqueue_reindex(records)
    return unless SearchEntry.table_exists?

    args = Array.wrap(records).map { |e| [{ 'record_type' => e.class.name, 'record_id' => e.id }] }

    ReindexSearchEntryJob.perform_bulk(args)
  end

  def reindex_record(record)
    case record
    when Submitter
      index_submitter(record)
    when Template
      index_template(record)
    when Submission
      index_submission(record)

      record.submitters.each do |submitter|
        index_submitter(submitter)
      end
    else
      raise ArgumentError, 'Invalid Record'
    end
  end

  def build_tsquery(keyword)
    if keyword.match?(/\d/) && !keyword.match?(/\p{L}/)
      number = keyword.gsub(/\D/, '')

      ["tsvector @@ ((quote_literal(?) || ':*')::tsquery || (quote_literal(?) || ':*')::tsquery || plainto_tsquery(?))",
       number, number.length > 1 ? number.delete_prefix('0') : number, keyword]
    elsif keyword.match?(/[^\p{L}\d&@._\-+]/) || keyword.match?(/\A['"].*['"]\z/)
      ['tsvector @@ plainto_tsquery(?)', TextUtils.transliterate(keyword.downcase)]
    else
      [
        "tsvector @@ (quote_literal(coalesce((ts_lexize('english_stem', :keyword))[1], :keyword)) || ':*')::tsquery",
        { keyword: TextUtils.transliterate(keyword.downcase).squish }
      ]
    end
  end

  def build_weights_tsquery(terms, weight)
    last_query = Arel.sql(<<~SQL.squish)
      (quote_literal(coalesce((ts_lexize('english_stem', :term#{terms.size - 1}))[1], :term#{terms.size - 1})) ||  ':*' || :weight)::tsquery
    SQL

    query = terms[..-2].reduce(last_query) do |acc, term|
      index = terms.index(term)

      arel = Arel.sql(<<~SQL.squish)
        (quote_literal(coalesce((ts_lexize('english_stem', :term#{index}))[1], :term#{index})) ||  ':' || :weight)::tsquery
      SQL

      Arel::Nodes::InfixOperation.new('&&', arel, acc)
    end

    ["tsvector @@ (#{query.to_sql})", terms.index_by.with_index { |_, index| :"term#{index}" }.merge(weight:)]
  end

  def index_submitter(submitter)
    return if submitter.email.blank? && submitter.phone.blank? && submitter.name.blank?

    sql = SearchEntry.sanitize_sql_array(
      [
        "SELECT setweight(to_tsvector(?), 'A') || setweight(to_tsvector(?), 'B') ||
                setweight(to_tsvector(?), 'C') || setweight(to_tsvector(?), 'D')".squish,
        [submitter.email.to_s, submitter.email.to_s.split('@').last].join(' ').downcase,
        [submitter.phone.to_s.gsub(/\D/, ''),
         submitter.phone.to_s.gsub(PhoneCodes::REGEXP, '').gsub(/\D/, '')].uniq.join(' '),
        TextUtils.transliterate(submitter.name.to_s.downcase),
        build_submitter_values_string(submitter)
      ]
    )

    entry = submitter.search_entry || submitter.build_search_entry

    entry.account_id = submitter.account_id
    entry.tsvector = SearchEntry.connection.select_value(sql)

    return if entry.tsvector.blank?

    entry.save!

    entry
  rescue ActiveRecord::RecordNotUnique
    submitter.reload

    retry
  end

  def build_submitter_values_string(submitter)
    values =
      submitter.values.values.flatten.filter_map do |v|
        next if !v.is_a?(String) || v.length > MAX_VALUE_LENGTH || UUID_REGEXP.match?(v)

        TextUtils.transliterate(v)
      end

    values.uniq.join(' ')
  end

  def index_template(template)
    sql = SearchEntry.sanitize_sql_array(
      ['SELECT to_tsvector(?)', TextUtils.transliterate(template.name.to_s.downcase)]
    )

    entry = template.search_entry || template.build_search_entry

    entry.account_id = template.account_id
    entry.tsvector = SearchEntry.connection.select_value(sql)

    return if entry.tsvector.blank?

    entry.save!

    entry
  rescue ActiveRecord::RecordNotUnique
    template.reload

    retry
  end

  def index_submission(submission)
    return if submission.name.blank?

    sql = SearchEntry.sanitize_sql_array(
      ['SELECT to_tsvector(?)', TextUtils.transliterate(submission.name.to_s.downcase)]
    )

    entry = submission.search_entry || submission.build_search_entry

    entry.account_id = submission.account_id
    entry.tsvector = SearchEntry.connection.select_value(sql)

    return if entry.tsvector.blank?

    entry.save!

    entry
  rescue ActiveRecord::RecordNotUnique
    submission.reload

    retry
  end
end
