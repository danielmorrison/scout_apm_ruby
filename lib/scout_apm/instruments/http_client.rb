module ScoutApm
  module Instruments
    class HttpClient
      attr_reader :context

      def initialize(context)
        @context = context
        @installed = false
      end

      def logger
        context.logger
      end

      def installed?
        @installed
      end

      def install
        if defined?(::HTTPClient)
          @installed = true

          logger.info "Instrumenting HTTPClient"

          ::HTTPClient.class_eval do
            include ScoutApm::Tracer

            def request_with_scout_instruments(*args, **kwargs, &block)

              method = args[0].to_s
              url = args[1]

              max_length = ScoutApm::Agent.instance.context.config.value('instrument_http_url_length')
              url = url && url.to_s[0..(max_length - 1)]

              self.class.instrument("HTTP", method, :desc => url) do
                request_without_scout_instruments(*args, **kwargs, &block)
              end
            end

            alias request_without_scout_instruments request
            alias request request_with_scout_instruments
          end
        end
      end
    end
  end
end
