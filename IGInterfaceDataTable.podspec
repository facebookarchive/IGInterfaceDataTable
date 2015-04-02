Pod::Spec.new do |spec|
  spec.name         = 'IGInterfaceDataTable'
  spec.version      = '0.1.0'
  spec.license      =  { :type => 'BSD' }
  spec.authors      = { 'Ryan Nystrom' => 'rnystrom@fb.com' }
  spec.summary      = 'A category on WKInterfaceTable that makes configuring tables with multi-dimensional data easier.'
  spec.source       = { :git => 'https://github.com/instagram/IGInterfaceDataTable.git', :tag => '0.1.0' }
  spec.homepage	    = 'https://github.com/Instagram/IGInterfaceDataTable'

  spec.public_header_files = [
      'IGInterfaceDataTable/*.h'
  ]

  spec.source_files = [
      'IGInterfaceDataTable/*.{h,m}'
  ]

  spec.frameworks = 'WatchKit'

  spec.social_media_url = 'https://twitter.com/fbOpenSource'

  spec.ios.deployment_target = '8.2'
end
