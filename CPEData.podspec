Pod::Spec.new do |s|

  s.name            = 'CPEData'
  s.version         = '3.1.4'
  s.summary         = 'iOS native object mapping for MovieLabs Cross-Platform Extras Manifest, Common Metadata, AppData and Style specs'
  s.license         = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.homepage        = 'https://github.com/warnerbros/cpe-manifest-ios-data'
  s.author          = { 'Alec Ananian' => 'alec.ananian@warnerbros.com' }

  s.platform        = :ios, '8.0'

  s.dependency        'SWXMLHash', '~> 4.0'
  
  s.source          = { :git => 'https://github.com/warnerbros/cpe-manifest-ios-data.git', :tag => s.version.to_s }
  s.source_files    = 'Source/**/*.swift', 'Source/*.swift'

end
