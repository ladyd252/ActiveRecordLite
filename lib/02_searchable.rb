require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # I used a local variable where_line where I mapped the keys of the params to "#{key} = ?" and joined with AND.
    #
    # To fill in the question marks, I used the values of the params object.
    where_line = params.map {|key, value| "#{key} = ?" }.join(" AND ")
    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
