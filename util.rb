print "runtest #{ARGV.join(' ')}\n"

def run(cmd, use_system=false)
  print("#{cmd}\n")
  if use_system
    system(cmd)
  else
    prog = cmd.split(' ')[0]
    if (not prog.include?('/')) or File.exists?(prog)
      `#{cmd}`
    else
      print("SKIPPING: unknown command: #{cmd}\n")
    end
  end
end

run "mkdir -p out"
$out_file = "out/#{$test_name}"
run "rm -f #{$out_file}"

$time_curr = $time_start = Time.now
$time_prev = nil
$mesg_prev = nil
$work_prev = nil
$step_num  = 0

def step(mesg, cmd=nil, elapsed=nil, work=nil, description=nil)
  if description
    `mkdir -p ./step`
    step_name = mesg.gsub('.', '').split(' ')[0]
    step_file = "./step/#{step_name}.json"
    step_doc = <<EOS
{ "_id": "step_#{step_name}",
  "kind": "step",
  "description": "#{description.gsub("\n", ' ').strip}"
}
EOS
    File.open(step_file, 'w') {|f| f.write(step_doc) }
  end

  $time_curr = Time.now

  if $time_prev
    elapsed = $time_curr - $time_prev unless elapsed

    if $mesg_prev and $work_prev and elapsed > 0
      print "#{$mesg_prev} #{$work_prev}, items/sec: #{$work_prev.to_f / elapsed}\n"
      `echo "#{$mesg_prev} #{$work_prev}, items/sec: #{$work_prev.to_f / elapsed}" >> #{$out_file}`
    end

    print "# #{$step_num}. #{$mesg_prev} done. elapsed: #{elapsed}\n"
    `echo "# #{$step_num}. #{$mesg_prev} done. elapsed: #{elapsed}" >> #{$out_file}`
  end

  $step_num  = $step_num + 1

  print "# #{$step_num}. #{mesg} #{$time_curr.strftime('%Y%m%d-%H%M%S')}\n"
  `echo "# #{$step_num}. #{mesg} #{$time_curr.strftime('%Y%m%d-%H%M%S')}" >> #{$out_file}`

  $time_prev = $time_curr
  $mesg_prev = mesg
  $work_prev = work

  time(cmd) if cmd

  yield if block_given?
end

def time(cmd)
  proc_stats_start()

  run(cmd)

  proc_stats_end()
end

def proc_stats_start()
  return unless $mesg_prev
  step = $mesg_prev.gsub(".", "").split(' ')[0]
  system("./proc-stats \"#{$top_patt}\" > #{$out_file}-#{step}.proc-stats &")
  dev = `mount | grep "on / "`.split(' ')[0].split('/')[2] # Example: "sdb1"
  system("./proc-stats #{dev} /proc/diskstats > #{$out_file}-#{step}.proc-diskstats &")
  grab_du(step)
end

def proc_stats_end()
  killall('proc-stats')
  step = $mesg_prev.gsub(".", "").split(' ')[0]
  grab_du(step)
end

def killall(pattern)
  # A very dangerous function.
  #
  x = `grep -l #{pattern} /proc/*/cmdline`
  x.split("\n").map {|c| `kill #{c.split('/')[2]}` }
end

def grab_du(step, du_path=nil)
  du_path ||= $du_path
  system("du -b -c --time #{du_path} >> #{$out_file}-#{step}.du") if du_path
end

