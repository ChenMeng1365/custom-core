
Gem::Specification.new do |spec|
  spec.name          = "cc"
  spec.version       = '1.1.1'
  spec.authors       = ["Matt"]
  spec.email         = ["matthrewchains@gmail.com","18995691365@189.cn"]
  spec.license       = "MIT"

  spec.summary       = %q{custom core}
  spec.description   = %q{custom-core is a custom library for ruby programming.}
  spec.homepage      = %q{https://github.com/ChenMeng1365/custom-core}
  spec.files         = [
    'cc',
    'attribute',
    'chinese',
    'chrono',
    'enum',
    'exception',
    'file',
    'kernel',
    'monkey-patch',
    'number',
    'regexp',
    'string',
    'tree'
  ].map{|file|"#{file}.rb"} + ["README.md", "LICENSE", "LICENSE-CN.md"]

  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["."]
end
