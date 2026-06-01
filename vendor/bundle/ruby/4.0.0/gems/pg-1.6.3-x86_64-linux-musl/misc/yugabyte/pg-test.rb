require 'pg'

conn = PG.connect(
  host: 'yb',
  port: 5433,
  user: 'yugabyte',
  dbname: 'yugabyte',
  sslmode: 'require',
  sslrootcert: 'app/generated_certs/127.0.0.1/ca.crt',
  sslcert: 'app/generated_certs/127.0.0.1/node.127.0.0.1.crt',
  sslkey: 'app/generated_certs/127.0.0.1/node.127.0.0.1.key'
)

$stdout.sync = true
# fd = File.open("pg_trace.log", "a+")
# conn.trace(fd)

begin
  # Validate connection is working
  res = conn.exec("SELECT version();")
  res.each_row do |row|
    puts "You are connected to: #{row[0]}"
  end
# 53*511
# 53*767
# 53*1023
# 53*1279
# 7*1817
# 11*1487
# 13*1363
# 16*1211
# 18*1128
# 22*1984
# 27*1723

  (22..53).each do |m|
    (1..2048).each do |l|
      hanging_query = "SELECT lpad(''::text, #{m}, '0') FROM generate_series(1, #{l});"
      puts "Executing hanging query: #{hanging_query}"
      conn.exec(hanging_query)
    end
  end
ensure
  conn.close if conn
end
