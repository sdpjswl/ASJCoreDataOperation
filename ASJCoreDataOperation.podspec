Pod::Spec.new do |s|
  s.name         = 'ASJCoreDataOperation'
  s.version      = '0.1'
  s.platform	   = :ios, '8.0'
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/sudeepjaiswal/ASJCoreDataOperation'
  s.authors      = { 'Sudeep Jaiswal' => 'sudeepjaiswal87@gmail.com' }
  s.summary      = 'Do asynchronous CoreData operations without blocking your UI'
  s.source       = { :git => 'https://github.com/sudeepjaiswal/ASJCoreDataOperation.git', :tag => '0.1' }
  s.source_files = 'ASJCoreDataOperation/*.{h,m}'
  s.requires_arc = true
end