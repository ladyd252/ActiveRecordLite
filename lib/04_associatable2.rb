require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method name do

      through_options = self.class.assoc_options[through_name]#human options
      through_table = through_options.table_name#'humans'
      target_options = through_options.model_class.assoc_options[source_name]#house options
      target_table = target_options.table_name

      results = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))
        SELECT
          #{target_table}.*
        FROM
          #{through_table}
        JOIN
          #{target_table}
        ON
          #{through_table}.#{target_options.foreign_key} = #{target_table}.id
        WHERE
          #{through_table}.id = ?
        SQL
      target_options.model_class.parse_all(results).first
    end
  end
end
