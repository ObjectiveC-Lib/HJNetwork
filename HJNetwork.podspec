Pod::Spec.new do |s|
  s.name            = 'HJNetwork'
  s.version         = '2.0.3'
  
  s.ios.deployment_target = '9.0'
  
  s.summary         = 'HJNetwork is a high level request util based on AFNetworking.'
  s.homepage        = 'https://github.com/ObjectiveC-Lib/HJNetwork'
  s.source          = { :git => 'https://github.com/ObjectiveC-Lib/HJNetwork.git', :tag => s.version }
  s.license         = { :type => 'MIT', :file => 'LICENSE' }
  s.author          = { 'navy' => 'lzxy169@gmail.com' }
  
  s.requires_arc    = true
  s.framework       = 'CFNetwork'
  
  s.source_files    = 'HJNetwork/Core/HJNetwork.h'
  s.default_subspec = 'Default'
  
  s.subspec 'Public' do |ss|
    ss.source_files = 'HJNetwork/Public/*.{h,m}'
    ss.dependency 'AFNetworking', '~> 4.0'
  end
  
  s.subspec 'Cache' do |ss|
    ss.source_files = 'HJNetwork/Cache/*.{h,m}'
    ss.dependency 'HJCache'
  end
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'HJNetwork/Core/*.{h,m}'
    ss.dependency 'HJNetwork/Public'
    ss.dependency 'HJNetwork/Cache'
  end
  
  s.subspec 'Default' do |ss|
    ss.source_files = 'HJNetwork/Default/*.{h,m}'
    ss.dependency 'HJNetwork/Core'
  end
  
  s.subspec 'Accessory' do |ss|
    ss.source_files = 'HJNetwork/Accessory/*.{h,m}'
    ss.dependency 'HJNetwork/Default'
  end
  
  s.subspec 'Protocol' do |ss|
    ss.source_files = 'HJNetwork/Protocol/*.{h,m}'
    ss.dependency 'HJNetwork/Public'
  end
  
  s.subspec 'AFURLConnection' do |ss|
    ss.source_files = 'HJNetwork/AFURLConnection/*.{h,m}'
    ss.dependency 'HJNetwork/Public'
  end
  
  s.subspec 'AFDefault' do |ss|
    ss.source_files = 'HJNetwork/AFDefault/*.{h,m}'
    ss.dependency 'HJNetwork/Public'
    ss.dependency 'HJNetwork/Protocol'
    ss.dependency 'HJNetwork/AFURLConnection'
  end
end
