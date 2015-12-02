
module Cigale::Builder
  require "cigale/builder/conditional"
  include Cigale::Builder::Conditional

  require "cigale/builder/inject"
  include Cigale::Builder::Inject

  require "cigale/builder/shell"
  include Cigale::Builder::Shell

  require "cigale/builder/batch"
  include Cigale::Builder::Batch

  require "cigale/builder/gradle"
  include Cigale::Builder::Gradle

  require "cigale/builder/managed-script"
  include Cigale::Builder::ManagedScript

  require "cigale/builder/trigger-builds"
  include Cigale::Builder::TriggerBuilds

  require "cigale/builder/ssh"
  include Cigale::Builder::Ssh

  require "cigale/builder/maven-target"
  include Cigale::Builder::MavenTarget

  require "cigale/builder/sonar"
  include Cigale::Builder::Sonar

  require "cigale/builder/shining-panda"
  include Cigale::Builder::ShiningPanda

  require "cigale/builder/powershell"
  include Cigale::Builder::PowerShell

  require "cigale/builder/python"
  include Cigale::Builder::Python

  def builder_classes
    @builder_classes = {
      "inject" => "EnvInjectBuilder",
      "shell" => "hudson.tasks.Shell",
      "batch" => "hudson.tasks.BatchFile",
      "gradle" => "hudson.plugins.gradle.Gradle",
      "trigger-builds" => "hudson.plugins.parameterizedtrigger.TriggerBuilder",
      "ssh-builder" => "org.jvnet.hudson.plugins.SSHBuilder",
      "maven-target" => "hudson.tasks.Maven",
      "sonar" => "hudson.plugins.sonar.SonarRunnerBuilder",
      "powershell" => "hudson.plugins.powershell.PowerShell",
      "python" => "hudson.plugins.python.Python",
    }
  end

  def translate_builders (xml, tag, builders)
    if (builders || []).size == 0
      return xml.builders
    end

    xml.tag! tag do
      for b in builders
        case b
        when "critical-block-start"
          xml.tag! "org.jvnet.hudson.plugins.exclusion.CriticalBlockStart", :plugin => "Exclusion"
          next
        when "critical-block-end"
          xml.tag! "org.jvnet.hudson.plugins.exclusion.CriticalBlockEnd", :plugin => "Exclusion"
          next
        when "github-notifier"
          xml.tag! "com.cloudbees.jenkins.GitHubSetCommitStatusBuilder"
          next
        end

        btype, bdef = first_pair(b)
        clazz = builder_classes[btype]

        if clazz.nil?
          case btype
          when "managed-script"
            translate_managed_script_builder xml, bdef
          when "conditional-step"
            translate_conditional_step_builder xml, bdef
          when "shining-panda"
            translate_shining_panda_builder xml, bdef
          else
            raise "Unknown builder type: #{btype}" unless clazz
          end
        else
          xml.tag! clazz do
            self.send "translate_#{underize(btype)}_builder", xml, bdef
          end
        end
      end
    end
  end
end # Cigale::Builder
