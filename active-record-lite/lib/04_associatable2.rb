require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      through_table = through_options.table_name
      source_options = through_options.model_class.assoc_options[source_name]
      source_table = source_options.table_name
      foreign_key = source_options.foreign_key
      primary_key = source_options.primary_key
      model_class = source_options.model_class
      through_id = send(through_name).send(through_options.primary_key)
      model_class.parse_all(DBConnection.execute(<<-SQL, through_id)).first
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{foreign_key} = #{source_table}.#{primary_key}
        WHERE
          #{through_table}.#{through_options.primary_key} = ?
      SQL
    end
  end
end
