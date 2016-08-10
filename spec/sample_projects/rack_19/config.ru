hash_in_19_syntax = {
  a: 1
}

run proc {
  [
    200,
    { 'Content-Type' => 'application/json' },
    ['Hello World']
  ]
}
