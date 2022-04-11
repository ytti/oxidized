class NetScaler < Oxidized::Model
  prompt /^([\w\.-]*>\s?)$/
  comment '# '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-3].join
  end

  cmd 'show version' do |cfg|
    comment cfg
  end

  cmd 'show hardware' do |cfg|
    comment cfg
  end

  cmd 'show partition' do |cfg|
    comment cfg
  end

  cmd :secret do |cfg|
    cfg.gsub! /\w+\s(-encrypted)/, '<secret hidden> \\1'
    cfg
  end

  # check for multiple partitions
  cmd 'show partition' do |cfg|
    @is_multiple_partition = cfg.include? 'Name:'
  end

  post do
    if @is_multiple_partition
      multiple_partition
    else
      single_partition
    end
  end

  def single_partition
    # Single partition mode
    cmd 'show ns ns.conf' do |cfg|
      cfg
    end
  end

  def multiple_partition
    # Multiple partition mode
    cmd 'show partition' do |cfg|
      allcfg = ""
      partitions = [["default"]] + cfg.scan(/Name: (\S+)$/)
      partitions.each do |part|
        allcfg = allcfg + "\n\n####################### [ partition " + part.join(" ") + " ] #######################\n\n"
        cmd "switch ns partition " + part.join(" ") + "; show ns ns.conf; switch ns partition default" do |cfgpartition|
          allcfg += cfgpartition
        end
      end
      allcfg
    end
  end

  cfg :ssh do
    pre_logout 'exit'
  end
end
