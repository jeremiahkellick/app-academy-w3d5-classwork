require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_str = params.map { |attr, value| "#{attr} = ?" }.join(" AND ")
    parse_all(DBConnection.execute(<<-SQL, *params.values))
      SELECT * FROM #{table_name} WHERE #{where_str}
    SQL
  end
end

class SQLObject
  extend Searchable
end

