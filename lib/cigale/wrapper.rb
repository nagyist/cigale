
module Cigale::Wrapper
  require "cigale/wrapper/timeout"
  require "cigale/wrapper/config-file-provider"
  require "cigale/wrapper/inject-passwords"
  require "cigale/wrapper/delivery-pipeline"
  require "cigale/wrapper/port-allocator"
  require "cigale/wrapper/mongo-db"
  require "cigale/wrapper/rbenv"

  def wrapper_classes
    @wrapper_classes ||= {
      "timeout" => "hudson.plugins.build__timeout.BuildTimeoutWrapper",
      "inject-passwords" => "EnvInjectPasswordWrapper",
      "delivery-pipeline" => "se.diabol.jenkins.pipeline.PipelineVersionContributor",
      "port-allocator" => "org.jvnet.hudson.plugins.port__allocator.PortAllocator",
    }
  end

  def translate_wrappers (xml, wrappers)
    if (wrappers || []).size == 0
      return xml.buildWrappers
    end

    xml.buildWrappers do
      for w in wrappers
        case w
        when "rbenv"
          translate_rbenv_wrapper xml, {}
          next
        end

        wtype, wdef = first_pair(w)
        clazz = wrapper_classes[wtype]

        if clazz
          xml.tag! clazz do
            self.send "translate_#{underize(wtype)}_wrapper", xml, wdef
          end
        else
          case wtype
          when "config-file-provider"
            translate_config_file_provider_wrapper xml, wdef
          when "mongo-db"
            translate_mongo_db_wrapper xml, wdef
          when "rbenv"
            translate_rbenv_wrapper xml, wdef
          else
            raise "Unknown wrapper type: #{wtype}"
          end
        end # unless clazz

      end # for w in wrappers
    end # wrappers
  end
end