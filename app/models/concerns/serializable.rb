module Serializable
  extend ActiveSupport::Concern

  class_methods do
    def serializes(*scalars, **nested)
      serialized_scalars.concat(scalars)
      serialized_nested.merge!(nested)
    end

    def serialized_scalars = @serialized_scalars ||= inherited_serialized(:serialized_scalars, [])
    def serialized_nested = @serialized_nested ||= inherited_serialized(:serialized_nested, {})

    def load(hash)
      return if hash.blank?
      allocate.tap { |obj| obj.send(:assign_serialized, hash) }
    end

    private

    def inherited_serialized(method, default)
      superclass.respond_to?(method) ? superclass.public_send(method).dup : default
    end
  end

  def as_json
    scalar_pairs.merge(nested_pairs)
  end

  private

  def scalar_pairs
    self.class.serialized_scalars.to_h { |attr| [ attr.to_s, instance_variable_get(:"@#{attr}") ] }
  end

  def nested_pairs
    self.class.serialized_nested.to_h do |attr, klass|
      [ attr.to_s, dump_nested(instance_variable_get(:"@#{attr}"), klass) ]
    end
  end

  def dump_nested(value, klass)
    klass.is_a?(Array) ? Array(value).map(&:as_json) : value&.as_json
  end

  def assign_serialized(hash)
    self.class.serialized_scalars.each { |attr| instance_variable_set(:"@#{attr}", hash[attr.to_s]) }
    self.class.serialized_nested.each { |attr, klass| assign_nested(attr, klass, hash) }
  end

  def assign_nested(attr, klass, hash)
    value = hash[attr.to_s]
    loaded = klass.is_a?(Array) ? Array(value).map { |item| klass.first.load(item) } : klass.load(value)
    instance_variable_set(:"@#{attr}", loaded)
  end
end
