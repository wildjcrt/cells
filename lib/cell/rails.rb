module Cell
  class Rails < Base
    # When this file is included we can savely assume that a rails environment with caching, etc. is available.
    include ActionController::RequestForgeryProtection

    abstract!

    # FIXME: session: request_forgery_protection.rb:101:in `form_authenticity_token'
     #, :request, :config, :env, :url_options
    delegate :session, :params, :to => :controller
    def controller

      # TODO: introduce Metal::Dependency object
      Object.new.instance_eval do
        def params
          {}
        end

        def session
          {}
        end
        self
      end
    end

    class Builder < Cell::Builder
      def run_builder_block(block, *args)
        super(block, *args)
      end
    end

    class << self
      def cache_store
        # FIXME: i'd love to have an initializer in the cells gem that _sets_ the cache_store attr instead of overriding here.
        # since i dunno how to do that we'll have this method in rails for now.
        # DISCUSS: should this be in Cell::Rails::Caching ?
        ActionController::Base.cache_store
      end

      def expire_cache_key(key, *args)  # FIXME: move to Rails.
        expire_cache_key_for(key, cache_store ,*args)
      end

      # Main entry point for instantiating cells.

      def cell_for(name, *args)
        # FIXME: too much redundancy from Base.
        Builder.new(class_from_cell_name(name), nil).call(*args) # use Cell::Rails::Builder.
      end
    end


    def cache_configured?
      ActionController::Base.send(:cache_configured?) # DISCUSS: why is it private?
    end

    def cache_store
      self.class.cache_store  # in Rails, we have a global cache store.
    end

    module DSL
      def cell(name, *args)
        # TODO: this method should be an instance method everywhere.
        Base.cell_for(name, *args)
      end
    end
    include DSL
  end
end
