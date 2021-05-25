module Clear::Model::HasTimestamps
  # Generate the columns `updated_at` and `created_at`
  # The two column values are automatically set during insertion
  #   or update of the model.
  macro timestamps
    column( updated_at : Time )
    column( created_at : Time )

    before(:validate) do |model|
      model = model.as(self)

      unless model.persisted?
        now = Time.local
        model.created_at = now unless model.created_at_column.defined?
        model.updated_at = now unless model.updated_at_column.defined?
      end
    end

    after(:validate) do |model|
      model = model.as(self)

      # In the case the updated_at has been changed, we do not override.
      # It happens on first insert, in the before validation setup.
      model.updated_at = Time.local if model.changed? && !model.updated_at_column.changed?
    end

    # Saves the record with the updated_at set to the current time.
    def touch(now = Time.local) : Clear::Model
      self.updated_at = now
      self.save!

      self
    end

  end

  macro timestamps_unix
    column( updated_at : Int64 )
    column( created_at : Int64 )

    before(:validate) do |model|
      model = model.as(self)

      unless model.persisted?
        now = Time.local.to_unix
        model.created_at = now unless model.created_at_column.defined?
        model.updated_at = now unless model.updated_at_column.defined?
      end
    end

    after(:validate) do |model|
      model = model.as(self)

      # In the case the updated_at has been changed, we do not override.
      # It happens on first insert, in the before validation setup.
      model.updated_at = Time.local.to_unix if model.changed? && !model.updated_at_column.changed?
    end

    # Saves the record with the updated_at set to the current time.
    def touch(now = Time.local.to_unix) : Clear::Model
      self.updated_at = now
      self.save!

      self
    end

  end
end
