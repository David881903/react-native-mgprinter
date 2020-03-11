
Pod::Spec.new do |s|
  s.name         = "RNPrinter"
  s.version      = "1.0.0"
  s.summary      = "RNPrinter"
  s.description  = <<-DESC
                  RNPrinter
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/author/RNPrinter.git", :tag => "master" }
  s.source_files  = "RNPrinter/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  