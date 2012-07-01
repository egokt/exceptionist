Gem::Specification.new do |s|
  s.name = 'exceptionist'
  s.version = '0.0.0'
  s.date = '2012-07-01'
  s.summary = 'Manage exceptions with ease'
  s.description = 'Exceptionist lets you define methods as handlers for ' +
    'processing certain exceptions raised in other methods, without tainting ' +
    'the code in the method that raises the exception. You can also define ' +
    'catch-all handler methods, for each instance or singular method, or for ' +
    'all methods in the class or instance.'
  s.authors = ['Erek Gokturk']
  s.email = ['erek@gokturk.name']
  s.homepage = 'http://blog.mdasheg.com'

  s.required_rubygems_version = '>= 1.8.0'

  s.files = Dir[ 
      "{lib}/**/*.rb", 
      'LICENSE', 
      'README', 
      'Rakefile',
      'exceptionist.gemspec'
    ]
  s.test_files = Dir["{test}/**/*.rb"]
  s.require_path = 'lib'
end
