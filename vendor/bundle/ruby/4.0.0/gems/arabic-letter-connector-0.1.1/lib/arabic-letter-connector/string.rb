class String
  def connect_arabic_letters
    ArabicLetterConnector.transform(self)
  end
end
