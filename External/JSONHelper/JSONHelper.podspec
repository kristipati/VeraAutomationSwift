Pod::Spec.new do |s|
  s.name = 'JSONHelper'
  s.version = '1.6.1'
  s.license = { :type => 'zlib', :file => 'LICENSE' }
  s.summary = 'Lightning fast JSON deserialization and value conversion library for iOS & OS X written in Swift.'

  s.homepage = 'https://github.com/isair/JSONHelper'
  s.author = { 'Baris Sencan' => 'baris.sncn@gmail.com' }
  s.social_media_url = 'https://twitter.com/IsairAndMorty'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.source       = { :git => 'https://github.com/isair/JSONHelper.git', :tag => s.version }
  s.source_files = 'JSONHelper'
  s.frameworks   = 'Foundation'
  s.requires_arc = true
end
