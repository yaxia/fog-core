require 'spec_helper'
require 'xmlrpc/datetime'

class FogAttributeTestModel < Fog::Model
  identity  :id
  attribute :key, :aliases => "keys", :squash => "id"
  attribute :time, :type => :time
  attribute :bool, :type => :boolean
  attribute :float, :type => :float
  attribute :integer, :type => :integer
  attribute :string, :type => :string
  attribute :timestamp, :type => :timestamp
  attribute :array, :type => :array
  attribute :default, :default => 'default_value'
  attribute :another_default, :default => false

  association :one_object, :single_associations
  association :many_objects, :multiple_associations, :magnitude => :many
  association :one_identity, :single_associations, :type => :identity
  association :many_identities, :multiple_associations, :type => :identity, :magnitude => :many

  def service
    Service.new
  end
end

class Service
  def single_associations
    FogSingleAssociationCollection.new
  end

  def multiple_associations
    FogMultipleAssociationsCollection.new
  end
end

class FogSingleAssociationCollection
  def get(id)
    FogSingleAssociationModel.new(:id => id)
  end
end

class FogMultipleAssociationsCollection
  def get(id)
    FogMultipleAssociationsModel.new(:id => id)
  end
end

class FogSingleAssociationModel < Fog::Model
  identity  :id
  attribute :name,  :type => :string
end

class FogMultipleAssociationsModel < Fog::Model
  identity  :id
  attribute :name,  :type => :string
end

describe "Fog::Attributes" do

  let(:model) { FogAttributeTestModel.new }

  it "should not create alias for nil" do
    FogAttributeTestModel.aliases.must_equal({ "keys" => :key })
  end

  describe "squash 'id'" do
    it "squashes if the key is a String" do
      model.merge_attributes("keys" => {:id => "value"})
      assert_equal"value", model.key
    end

    it "squashes if the key is a Symbol" do
      model.merge_attributes("keys" => {"id" => "value"})
      assert_equal "value", model.key
    end
  end

  describe ":type => time" do
    it "returns nil when provided nil" do
      model.merge_attributes(:time => nil)
      refute model.time
    end

    it "returns '' when provided ''" do
      model.merge_attributes(:time => "")
      assert_equal "",  model.time
    end

    it "returns a Time object when passed a Time object" do
      now = Time.now
      model.merge_attributes(:time => now.to_s)
      assert_equal Time.parse(now.to_s), model.time
    end

    it "returns a Time object when passed a XMLRPC::DateTime object" do
      now = XMLRPC::DateTime.new(2000, 7, 8, 10, 20, 34)
      model.merge_attributes(:time => now)
      assert_equal now.to_time, model.time
    end
  end

  describe ":type => :boolean" do
    it "returns the String 'true' as a boolean" do
      model.merge_attributes(:bool => "true")
      assert_equal true, model.bool
    end

    it "returns true as true" do
      model.merge_attributes(:bool => true)
      assert_equal true, model.bool
    end

    it "returns the String 'false' as a boolean" do
      model.merge_attributes(:bool => "false")
      assert_equal false, model.bool
    end

    it "returns false as false" do
      model.merge_attributes(:bool => false)
      assert_equal false, model.bool
    end

    it "returns a non-true/false value as nil" do
      model.merge_attributes(:bool => "foo")
      refute model.bool
    end
  end

  describe ":type => :float" do
    it "returns an integer as float" do
      model.merge_attributes(:float => 1)
      assert_in_delta 1.0, model.float
    end

    it "returns a string as float" do
      model.merge_attributes(:float => '1')
      assert_in_delta 1.0, model.float
    end
  end

  describe ":type => :integer" do
    it "returns a float as integer" do
      model.merge_attributes(:integer => 1.5)
      assert_in_delta 1, model.integer
    end

    it "returns a string as integer" do
      model.merge_attributes(:integer => '1')
      assert_in_delta 1, model.integer
    end
  end

  describe ":type => :string" do
    it "returns a float as string" do
      model.merge_attributes(:string => 1.5)
      assert_equal '1.5', model.string
    end

    it "returns a integer as string" do
      model.merge_attributes(:string => 1)
      assert_equal '1', model.string
    end
  end

  describe ":type => :timestamp" do
    it "returns a date as time" do
      model.merge_attributes(:timestamp => Date.new(2008, 10, 12))
      assert_equal '2008-10-12 00:00', model.timestamp.strftime('%Y-%m-%d %M:%S')
      assert_instance_of Fog::Time, model.timestamp
    end

    it "returns a time as time" do
      model.merge_attributes(:timestamp => Time.mktime(2007, 11, 1, 15, 25))
      assert_equal '2007-11-01 25:00', model.timestamp.strftime('%Y-%m-%d %M:%S')
      assert_instance_of Fog::Time, model.timestamp
    end

    it "returns a date_time as time" do
      model.merge_attributes(:timestamp => DateTime.new(2007, 11, 1, 15, 25, 0))
      assert_equal '2007-11-01 25:00', model.timestamp.strftime('%Y-%m-%d %M:%S')
      assert_instance_of Fog::Time, model.timestamp
    end
  end

  describe ":type => :array" do
    it "returns an empty array when not initialized" do
      assert_equal [], model.array
    end

    it "returns an empty array as an empty array" do
      model.merge_attributes(:array => [])
      assert_equal [], model.array
    end

    it "returns nil as an empty array" do
      model.merge_attributes(:array => nil)
      assert_equal [], model.array
    end

    it "returns an array with nil as an array with nil" do
      model.merge_attributes(:array => [nil])
      assert_equal [nil], model.array
    end

    it "returns a single element as array" do
      model.merge_attributes(:array => 1.5)
      assert_equal [ 1.5 ], model.array
    end

    it "returns an array as array" do
      model.merge_attributes(:array => [ 1, 2 ])
      assert_equal [ 1, 2 ], model.array
    end
  end

  describe ":default => 'default_value'" do
    it "should return nil when default is not defined on a new object" do
      assert_equal model.bool, nil
    end

    it "should return the value of the object when default is not defined" do
      model.merge_attributes({ :bool => false })
      assert_equal model.bool, false
    end

    it "should return the default value on a new object with value equal nil" do
      assert_equal model.default, 'default_value'
    end

    it "should return the value on a new object with value not equal nil" do
      model.default = 'not default'
      assert_equal model.default, 'not default'
    end

    it "should return false when default value is false on a new object" do
      assert_equal model.another_default, false
    end

    it "should return the value of the persisted object" do
      model.merge_attributes({ :id => 'some-crazy-id', :default => 23 })
      assert_equal model.default, 23
    end

    it "should return nil on a persisted object without a value" do
      model.merge_attributes({ :id => 'some-crazy-id' })
      assert_equal model.default, nil
    end
  end

  describe ".association" do
    describe "with a single magnitude" do
      describe "and with an object as param" do
        it "should create an instance_variable to save the association object" do
          assert_equal model.one_object, nil
        end

        it "should create a getter to save the association model" do
          model.merge_attributes(:one_object => FogSingleAssociationModel.new(:id => '123'))
          assert_instance_of FogSingleAssociationModel, model.one_object
          assert_equal model.one_object.attributes, { :id => '123' }
        end

        it "should create a setter that accept an object as param" do
          model.one_object = FogSingleAssociationModel.new(:id => '123')
          assert_equal model.one_object.attributes, { :id => '123' }
        end
      end

      describe "with an identity as param" do
        it "should create an instance_variable to save the association identity" do
          assert_equal model.one_identity, nil
        end

        it "should create a getter to load the association model" do
          model.merge_attributes(:one_identity => '123')
          assert_instance_of FogSingleAssociationModel, model.one_identity
          assert_equal model.one_identity.attributes, { :id => '123' }
        end

        it "should create a setter that accept an id as param" do
          model.one_identity = '123'
          assert_equal model.one_identity.attributes, { :id => '123' }
        end
      end
    end

    describe "with a multiple magnitude" do
      describe "with an array of objects as param" do
        it "should create an instance_variable to save the associated objects" do
          assert_equal model.many_objects, []
        end

        it "should create a getter to save all associated models" do
          model.merge_attributes(:many_objects => [ FogMultipleAssociationsModel.new(:id => '456') ])
          assert_instance_of Array, model.many_objects
          assert_equal model.many_objects.size, 1
          assert_instance_of FogMultipleAssociationsModel, model.many_objects.first
          assert_equal model.many_objects.first.attributes, { :id => '456' }
        end

        it "should create a setter that accept an array of objects as param" do
          model.many_objects = [ FogMultipleAssociationsModel.new(:id => '456') ]
          assert_equal model.many_objects.first.attributes, { :id => '456' }
        end
      end

      describe "with an array of identities as param" do
        it "should create an instance_variable to save the associations identities" do
          assert_equal model.many_identities, []
        end

        it "should create a getter to load all association models" do
          model.merge_attributes(:many_identities => [ '456' ])
          assert_instance_of Array, model.many_identities
          assert_equal model.many_identities.size, 1
          assert_instance_of FogMultipleAssociationsModel, model.many_identities.first
          assert_equal model.many_identities.first.attributes, { :id => '456' }
        end

        it "should create a setter that accept an array of ids as param" do
          model.many_identities = [ '456' ]
          assert_equal model.many_identities.first.attributes, { :id => '456' }
        end
      end
    end
  end

  describe "#all_attributes" do
    describe "on a persisted object" do
      it "should return all attributes without default values" do
        model.merge_attributes( :id => 2, :float => 3.2, :integer => 55555555 )
        assert_equal model.all_attributes, { :id => 2,
                                             :key => nil,
                                             :time => nil,
                                             :bool => nil,
                                             :float => 3.2,
                                             :integer => 55555555,
                                             :string => '',
                                             :timestamp => Time.at(0),
                                             :array => [],
                                             :default => nil,
                                             :another_default => nil }
      end
    end

    describe "on a new object" do
      it "should return all attributes including default values for empty attributes" do
        model.merge_attributes( :id => nil, :float => 3.2, :integer => 55555555 )
        assert_equal model.all_attributes, { :id => nil,
                                             :key => nil,
                                             :time => nil,
                                             :bool => nil,
                                             :float => 3.2,
                                             :integer => 55555555,
                                             :string => '',
                                             :timestamp => Time.at(0),
                                             :array => [],
                                             :default => 'default_value',
                                             :another_default => false }
      end
    end
  end
end
