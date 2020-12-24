Pod::Spec.new do |s|
  s.name            = 'HJNetwork'
  s.version         = '1.0.0'

  s.ios.deployment_target     = '7.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'

  s.summary         = 'HJNetwork is a high level request util based on AFNetworking.'
  s.homepage        = 'https://github.com/ObjectiveC-Lib/HJNetwork'
  s.source          = { :git => 'https://github.com/ObjectiveC-Lib/HJNetwork.git', :tag => s.version }
  s.license         = { :type => 'MIT', :file => 'LICENSE' }
  s.author          = { 'navy' => 'lzxy169@gmail.com' }

  s.requires_arc    = true
  s.framework       = 'CFNetwork'

  s.source_files = 'HJNetwork/HJNetwork.h'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'HJNetwork/**/*.{h,m}'
    core.private_header_files = 'HJNetwork/HJNetworkPrivate.h'
  end

  s.dependency 'AFNetworking', '~> 3.0'
  s.dependency 'HJCache'
end
