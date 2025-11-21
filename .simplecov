SimpleCov.configure do
  enable_coverage :line
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/bin/'
end
