
Pod::Spec.new do |spec|

  spec.name          = "MonitorDevToolsSwift"

  spec.version       = "0.0.1"

  spec.summary       = "Swift SDK for https://github.com/reduxjs/redux-devtools"

  spec.homepage      = "https://github.com/msfrms/MonitorDevToolsSwift.git"
  
  spec.license       = "MIT"  

  spec.author        = { "Radaev Mikhail" => "msfrms@gmail.com" }
  
  spec.swift_version = '5.0'

  spec.source        = { :git => "https://github.com/msfrms/MonitorDevToolsSwift.git", :branch => "master" }

  spec.source_files  = "Source/*.swift"
  
  spec.dependency 'ScClient'

end
