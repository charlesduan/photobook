require 'rake'

Gem::Specification.new do |s|
    s.name = 'photobook'
    s.version = '0.0.1'
    s.date = '2018-11-13'
    s.summary = 'Photo book maker'
    s.description = 'Makes photo book from pictures'
    s.author = [ 'Charles Duan' ]
    s.email = 'rubygems.org@cduan.com'
    s.files = FileList[
        'lib/**/*.rb',
        'test/**/*.rb',
        'bin/*'
    ].to_a
end

