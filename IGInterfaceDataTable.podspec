Pod::Spec.new do |spec|
  spec.name         = 'IGInterfaceDataTable'
  spec.version      = '0.1.0'
  spec.license      =  { :type => 'BSD' }
  spec.authors      = { 'Ryan Nystrom' => 'rnystrom@fb.com' }
  spec.summary      = 'TODO'
  spec.source       = { :git => 'https://github.com/instagram/IGInterfaceDataTable.git', :tag => '0.1.0' }

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
