Data::Country = Data.define(:id, :name, :states) do
  include DataFor::Model
  config :countries

  def flag
    id.upcase.chars.map { |character| (character.ord + 127397).chr(Encoding::UTF_8) }.join
  end

  private

  def cast_states(data)
    Array(data).map { Data::State[**it] }
  end
end
