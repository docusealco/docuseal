# frozen_string_literal: true

module SearchEntries
  MAX_VALUE_LENGTH = 100

  UUID_REGEXP = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

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

  def build_tsquery(keyword, with_or_vector: false)
    keyword = keyword.delete("\0")

    if keyword.match?(/\d/) && !keyword.match?(/\p{L}/)
      number = keyword.gsub(/\D/, '')

      sql =
        if number.length <= 2
          <<~SQL.squish
            ngram @@ (quote_literal(?)::tsquery || quote_literal(?)::tsquery) OR tsvector @@ plainto_tsquery(?)
          SQL
        else
          <<~SQL.squish
            tsvector @@ ((quote_literal(?) || ':*')::tsquery || (quote_literal(?) || ':*')::tsquery || plainto_tsquery(?))
          SQL
        end

      [sql, number, number.length > 1 ? number.delete_prefix('0') : number, keyword]
    elsif keyword.match?(/[^\p{L}\d&@._\-+]/) || keyword.match?(/\A['"].*['"]\z/)
      ['tsvector @@ plainto_tsquery(?)', TextUtils.transliterate(keyword.downcase)]
    else
      keyword = TextUtils.transliterate(keyword.downcase).squish

      sql =
        if keyword.length <= 2
          arel = Arel.sql('ngram @@ quote_literal(:keyword)::tsquery')

          arel = Arel::Nodes::Or.new([arel, Arel.sql('tsvector @@ plainto_tsquery(:keyword)')]).to_sql if with_or_vector

          arel
        else
          "tsvector @@ (quote_literal(coalesce((ts_lexize('english_stem', :keyword))[1], :keyword)) || ':*')::tsquery"
        end

      [sql, { keyword: }]
    end
  end

  def build_weights_tsquery(terms, weight)
    last_query =
      if terms.last.length <= 2
        Arel.sql("ngram @@ (quote_literal(:term#{terms.size - 1}) ||  ':' || :weight)::tsquery")
      else
        Arel.sql(<<~SQL.squish)
          (quote_literal(coalesce((ts_lexize('english_stem', :term#{terms.size - 1}))[1], :term#{terms.size - 1})) ||  ':*' || :weight)::tsquery
        SQL
      end

    query = terms[..-2].reduce(nil) do |acc, term|
      index = terms.index(term)

      arel = Arel.sql(<<~SQL.squish)
        (quote_literal(coalesce((ts_lexize('english_stem', :term#{index}))[1], :term#{index})) ||  ':' || :weight)::tsquery
      SQL

      acc ? Arel::Nodes::InfixOperation.new('&&', arel, acc) : arel
    end

    query =
      if terms.last.length <= 2
        query = Arel::Nodes::InfixOperation.new('@@', Arel.sql('tsvector'), Arel::Nodes::Grouping.new(query))

        Arel::Nodes::And.new([query, last_query])
      else
        Arel::Nodes::InfixOperation.new(
          '@@', Arel.sql('tsvector'),
          Arel::Nodes::Grouping.new(Arel::Nodes::InfixOperation.new('&&', query, last_query))
        )
      end

    [query.to_sql, terms.index_by.with_index { |_, index| :"term#{index}" }.merge(weight:)]
  end

  def build_weights_wildcard_tsquery(keyword, weight)
    keyword = TextUtils.transliterate(keyword.downcase).squish

    sql =
      if keyword.length <= 2
        <<~SQL.squish
          ngram @@ (quote_literal(:keyword) || ':' || :weight)::tsquery
        SQL
      else
        <<~SQL.squish
          tsvector @@ (quote_literal(coalesce((ts_lexize('english_stem', :keyword))[1], :keyword)) || ':*' || :weight)::tsquery
        SQL
      end

    [sql, { keyword:, weight: }]
  end

  def index_submitter(submitter)
    return if submitter.email.blank? && submitter.phone.blank? && submitter.name.blank?

    email_phone_name = [
      [submitter.email.to_s, submitter.email.to_s.split('@').last].join(' ').delete("\0"),
      [submitter.phone.to_s.gsub(/\D/, ''),
       submitter.phone.to_s.gsub(PhoneCodes::REGEXP, '').gsub(/\D/, '')].uniq.join(' ').delete("\0"),
      TextUtils.transliterate(submitter.name).delete("\0")
    ]

    sql = SearchEntry.sanitize_sql_array(
      [
        "SELECT setweight(to_tsvector(?), 'A') || setweight(to_tsvector(?), 'B') ||
                setweight(to_tsvector(?), 'C') || setweight(to_tsvector(?), 'D') as tsvector,
                setweight(to_tsvector('simple', ?), 'A') ||
                setweight(to_tsvector('simple', ?), 'B') ||
                setweight(to_tsvector('simple', ?), 'C') as ngram".squish,
        *email_phone_name,
        build_submitter_values_string(submitter),
        *email_phone_name
      ]
    )

    entry = submitter.search_entry || submitter.build_search_entry

    entry.account_id = submitter.account_id
    entry.tsvector, ngram = SearchEntry.connection.select_rows(sql).first
    entry.ngram = build_ngram(ngram)

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

    values.uniq.join(' ').downcase.delete("\0")
  end

  def index_template(template)
    sql = SearchEntry.sanitize_sql_array(
      ["SELECT to_tsvector(:text), to_tsvector('simple', :text)",
       { text: TextUtils.transliterate(template.name.to_s.downcase).delete("\0") }]
    )

    entry = template.search_entry || template.build_search_entry

    entry.account_id = template.account_id
    entry.tsvector, ngram = SearchEntry.connection.select_rows(sql).first
    entry.ngram = build_ngram(ngram)

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
      ["SELECT to_tsvector(:text), to_tsvector('simple', :text)",
       { text: TextUtils.transliterate(submission.name.to_s.downcase).delete("\0") }]
    )

    entry = submission.search_entry || submission.build_search_entry

    entry.account_id = submission.account_id
    entry.tsvector, ngram = SearchEntry.connection.select_rows(sql).first
    entry.ngram = build_ngram(ngram)

    return if entry.tsvector.blank?

    entry.save!

    entry
  rescue ActiveRecord::RecordNotUnique
    submission.reload

    retry
  end

  def build_ngram(ngram)
    ngrams =
      ngram.split(/\s(?=')/).each_with_object([]) do |item, acc|
        acc << item.sub(/'(.*?)':/) { "'#{Regexp.last_match(1).first(2)}':" }
        acc << item.sub(/'(.*?)':/) { "'#{Regexp.last_match(1).first(1)}':" }
      end

    ngrams.uniq { |e| e.sub(/':[\d,]/, "':1") }.join(' ')
  end
end
