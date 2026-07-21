require 'rails_helper'

class SerializableTag
  include Serializable
  attr_accessor :label

  def initialize(label = nil)
    @label = label
  end

  serializes :label
end

class SerializableAddress
  include Serializable
  attr_accessor :city

  def initialize(city = nil)
    @city = city
  end

  serializes :city
end

class SerializableDummy
  include Serializable
  attr_accessor :name, :address, :tags

  def initialize(name: nil, address: nil, tags: [])
    @name = name
    @address = address
    @tags = tags
  end

  serializes :name, address: SerializableAddress, tags: [ SerializableTag ]
end

class SerializableDummySubclass < SerializableDummy
end

RSpec.describe Serializable do
  let(:dummy) do
    SerializableDummy.new(
      name: "dummy",
      address: SerializableAddress.new("Greenville"),
      tags: [ SerializableTag.new("a"), SerializableTag.new("b") ]
    )
  end

  it "round-trips a scalar attribute" do
    reloaded = SerializableDummy.load(dummy.as_json)
    expect(reloaded.name).to eq "dummy"
  end

  it "round-trips a single nested object" do
    reloaded = SerializableDummy.load(dummy.as_json)
    expect(reloaded.address.city).to eq "Greenville"
  end

  it "round-trips an array of nested objects" do
    reloaded = SerializableDummy.load(dummy.as_json)
    expect(reloaded.tags.map(&:label)).to eq [ "a", "b" ]
  end

  context "when an array key is missing from the hash" do
    it "defaults to an empty array" do
      reloaded = SerializableDummy.load({ "name" => "dummy" })
      expect(reloaded.tags).to eq []
    end
  end

  context "when a nested object's value is nil" do
    it "loads it as nil rather than raising" do
      reloaded = SerializableDummy.load({ "name" => "dummy", "address" => nil })
      expect(reloaded.address).to be_nil
    end
  end

  context "when the hash itself is blank" do
    it "returns nil" do
      expect(SerializableDummy.load(nil)).to be_nil
    end
  end

  context "when a subclass declares no schema of its own" do
    it "inherits the parent's serializes schema" do
      reloaded = SerializableDummySubclass.load(dummy.as_json)
      expect(reloaded.tags.map(&:label)).to eq [ "a", "b" ]
    end
  end
end
