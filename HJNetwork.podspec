Pod::Spec.new do |s|
  s.name            = 'HJNetwork'
  s.version         = '2.1.6'
  
  s.ios.deployment_target = '9.0'
  
  s.summary         = 'HJNetwork is a high level request util based on AFNetworking.'
  s.homepage        = 'https://github.com/ObjectiveC-Lib/HJNetwork'
  s.source          = { :git => 'https://github.com/ObjectiveC-Lib/HJNetwork.git', :tag => s.version }
  s.license         = { :type => 'MIT', :file => 'LICENSE' }
  s.author          = { 'navy' => 'lzxy169@gmail.com' }
  
  s.requires_arc    = true
  s.framework       = 'CFNetwork'
  
  s.source_files    = 'HJNetwork/HJNetwork.h'
  s.default_subspec = 'Request'
  
  s.subspec 'AFURLConnection' do |ss|
    ss.source_files = 'HJNetwork/AFURLConnection/*.{h,m}'
    ss.dependency 'AFNetworking'
  end
  
  s.subspec 'Cache' do |ss|
    ss.source_files = 'HJNetwork/Cache/*.{h,m}'
    ss.dependency 'HJCache'
  end
  
  s.subspec 'Common' do |ss|
    ss.source_files = 'HJNetwork/Common/*.{h,m}'
    ss.dependency 'AFNetworking'
  end
  
  s.subspec 'Default' do |ss|
    ss.source_files = 'HJNetwork/Default/*.{h,m}'
    ss.dependency 'HJNetwork/Protocol'
    ss.dependency 'HJNetwork/AFURLConnection'
  end
  
  s.subspec 'DNS' do |ss|
    ss.source_files = 'HJNetwork/DNS/*.{h,m}'
    ss.dependency 'HJNetwork/Common'
  end
  
  s.subspec 'Download' do |ss|
    ss.source_files = 'HJNetwork/Download/*.{h,m}'
    ss.dependency 'HJNetwork/Common'
    ss.dependency 'HJNetwork/AFURLConnection'
  end
  
  s.subspec 'Protocol' do |ss|
    ss.source_files = 'HJNetwork/Protocol/*.{h,m}'
    ss.dependency 'HJNetwork/Common'
  end
  
  s.subspec 'Request' do |ss|
    ss.source_files = 'HJNetwork/Request/*.{h,m}'
    ss.dependency 'HJNetwork/Common'
    ss.dependency 'HJNetwork/Cache'
    ss.subspec 'Accessory' do |sss|
      sss.source_files = 'HJNetwork/Request/Accessory/**/*.{h,m}'
    end
    ss.subspec 'Core' do |sss|
      sss.source_files = 'HJNetwork/Request/Core/**/*.{h,m}'
    end
    ss.subspec 'Default' do |sss|
      sss.source_files = 'HJNetwork/Request/Default/**/*.{h,m}'
    end
  end
  
  s.subspec 'RetryRequest' do |ss|
    ss.source_files = 'HJNetwork/RetryRequest/**/*.{h,m}'
    ss.dependency 'HJNetwork/Request'
    ss.dependency 'HJTask'
  end
  
  s.subspec 'Upload' do |ss|
    ss.source_files = 'HJNetwork/Upload/**/*.{h,m}'
    ss.dependency 'HJNetwork/Request'
    ss.dependency 'HJTask'
  end
end
