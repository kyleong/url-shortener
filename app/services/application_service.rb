class ApplicationService
  class << self
    def call!(*args, &block)
      new(*args, &block).call!
    end

    def call(*args, &block)
      new(*args, &block).call
    end
  end
end
