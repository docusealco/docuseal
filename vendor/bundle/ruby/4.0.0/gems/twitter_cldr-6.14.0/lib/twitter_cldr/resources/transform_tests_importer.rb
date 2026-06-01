# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'

module TwitterCldr
  module Resources

    # This class should be used with JRuby in 1.9 mode
    class TransformTestsImporter < Importer
      # most of these were taken from wikipedia, lol
      TEXT_SAMPLES = {
        latin: ["From today's featured article"],  # @TODO test capital letters,
        serbian: ["На данашњи дан"],
        oriya: ["ଉଇକିପିଡ଼ିଆ ବ୍ୟବହାର କରିବେ କିପରି"],
        kannada: ["ಈ ತಿಂಗಳ ಪ್ರಮುಖ ದಿನಗಳು"],
        gurmukhi: ["ਅੱਜ ਇਤਿਹਾਸ ਵਿੱਚ"],
        gujarati: ["આ માસનો ઉમદા લેખ"],
        bengali: ["নির্বাচিত নিবন্ধ"],
        hangul: ["김창옥", '모든 사용자는 위키백과에 직접 참여해 확인 가능'],
        arabic: ["مقالة اليوم المختارة"],
        han: ["因此只有两场风暴因造成"],
        hiragana: ["くろねこさま"],
        katakana: ['フライドポテトサラリーマン'],
        greek: ["Αλφαβητικός Κατάλογος"],
        cyrillic: ["Влади́мир Влади́мирович Пу́тин"],
        amharic: ["ወደ ውክፔዲያ እንኳን ደህና መጡ"],
        armenian: ['Վիքիպեդիան հանրագիտարան է, որն ստեղծվել'],
        devanagari: ['विकिपीडिया सभी विषयों पर प्रामाणिक'],
        telugu: ['అనంతపురం జిల్లా తాడిపత్రిలో పెన్నా'],
        malayalam: ['ഇടുക്കിയിലെ സൂര്യനെല്ലി സ്വദേശിനിയായ'],
        tamil: ['சென்னையில் வாழும் உலோ.செந்தமிழ்க்கோதை'],
        interindic: ['  '],
        hebrew: ['על שמן של המיילדות במצרים, שפרה ופועה, נקראו'],
        simplified:  ['系统源于墨西哥以西的扰动天气区，并且位于更大规模的天气系统以内'],
        traditional: ['系統源於墨西哥以西的擾動天氣區，並且位於更大規模的天氣系統以內'],
        georgian: ['მზის სისტემა შედგება მზისა და მის გარშემო'],
        pashto: ['پښتو ژبه د لرغونو آرياني ژبو څخه يوه خپلواکه ژبه ده'],
        persian: ['فارسی یکی از زبان‌های هندواروپایی در شاخهٔ زبان‌های'],
        macedonian: ['Римскиот цар Калигула, познат по својата ексцентричност'],
        ukrainian: ['У списку наведено усіх султанів, які правили в Єгипті']
      }

      BGN_SAMPLES = [:armenian, :katakana, :korean]

      requirement :icu, Versions.icu_version
      output_path File.join(TwitterCldr::SPEC_DIR, 'transforms', 'test_data.yml')
      ruby_engine :jruby

      def execute
        File.open(params.fetch(:output_path), 'w+') do |f|
          f.write(
            YAML.dump(
              generate_test_data(transformer.each_transform)
            )
          )
        end
      end

      private

      def generate_test_data(transforms)
        transforms.each_with_object([]) do |transform_id_str, ret|
          forward_id = transform_id.parse(transform_id_str)

          [forward_id, forward_id.reverse].each do |id|
            if id_exists?(id)
              if bgn_sample?(id.source)
                bgn_id = TwitterCldr::Transforms::TransformId.parse("#{id.to_s}/BGN") rescue nil
                id = bgn_id if bgn_id
              end

              if have_text_samples_for?(id.source)
                samples = text_samples_for(id.source)
                transformed_samples = generate_transform_samples(id, samples)

                if transformed_samples
                  ret << {
                    id: id.to_s,
                    samples: transformed_samples
                  }
                end
              end
            end
          end
        end
      end

      private

      def bgn_sample?(script)
        BGN_SAMPLES.include?(script.downcase.to_sym)
      end

      def id_exists?(id)
        TwitterCldr::Transforms::Transformer.exists?(id)
      end

      def transliterator_class
        @transliterator_class ||= requirements[:icu].get_class('com.ibm.icu.text.Transliterator')
      end

      def generate_transform_samples(id, samples)
        trans = transliterator_class.getInstance(id.to_s)
        samples.each_with_object({}) do |sample, ret|
          ret[sample] = trans.transliterate(sample)
        end
      end

      def have_text_samples_for?(script)
        TEXT_SAMPLES.include?(script.downcase.to_sym)
      end

      def text_samples_for(script)
        TEXT_SAMPLES.fetch(script.downcase.to_sym)
      end

      def transformer
        TwitterCldr::Transforms::Transformer
      end

      def transform_id
        TwitterCldr::Transforms::TransformId
      end
    end

  end
end
