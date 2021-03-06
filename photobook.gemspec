require 'rake'

Gem::Specification.new do |s|
    s.name = 'photobook'
    s.version = '0.0.2'
    s.date = '2018-11-13'
    s.license = "MIT"
    s.summary = 'Photo book maker'
    s.description = 'Makes photo book from pictures'
    s.author = [ 'Charles Duan' ]
    s.email = 'rubygems.org@cduan.com'
    s.files = FileList[
        'lib/**/*.rb',
        'data/**/*',
        'test/**/*.rb',
        'bin/*',
        "LICENSE",
    ].to_a
    s.executables << 'photobook'
    s.add_runtime_dependency 'fastimage', "~> 2.1"
    s.add_runtime_dependency 'exifr', '~> 1.3'
end

