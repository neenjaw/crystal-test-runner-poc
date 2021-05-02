class Bob
  def self.hey(string : String)
    case string
    when .blank?
      "Fine. Be that way!"
    else
      "Whatevah."
    end
  end
end
