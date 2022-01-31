Pod::Spec.new do |s|
  s.name          = 'ASJCoreDataOperation'
  s.version       = '1.3'
  s.platform      = :ios, '10.0'
  s.license       = { :type => 'MIT' }
  s.homepage      = 'https://github.com/sdpjswl/ASJCoreDataOperation'
  s.authors       = { 'Sudeep' => 'sdpjswl1@gmail.com' }
  s.summary       = 'Do asynchronous CoreData operations without blocking your UI'
  s.source        = { :git => 'https://github.com/sdpjswl/ASJCoreDataOperation.git', :tag => s.version }
  s.requires_arc  = true
  
  s.default_subspec = 'Swift'
  s.swift_version = '5'
  
  s.subspec 'Swift' do |spec|
    spec.source_files  = 'ASJCoreDataOperation/*.{swift}
  end
  
  s.subspec 'Obj-C' do |spec|
    spec.source_files  = 'ASJCoreDataOperation/*.{h,m}
  end

end
