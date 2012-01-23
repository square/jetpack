hash_in_19_syntax = {
  a: 1
}

run Proc.new {|env| [200,
  {"Content-Type" => "application/json"},
  ["Hello World"]
]}
