# $Id$
#
# ParamILS wrapper for Spear theorem prover.
#
# ** Edited to delete tmp files and respond to
#    HAL termination. **

# Deal with inputs.
if ARGV.length < 5
    puts "spear_wrapper.rb is a wrapper for the Spear theorem prover."
    puts "Usage: ruby spear_wrapper.rb <instance_relname>
<instance_specifics (string in \"quotes\"> <cutoff_time> <cutoff_length> <seed> <params to be
passed on>."
    exit -1
end

input_file = ARGV[0]
#=== Here instance_specifics are not used - but you can put any information into this string you wish ...
instance_specifics = ARGV[1]
timeout = ARGV[2].to_i
cutoff_length = ARGV[3].to_i
seed = ARGV[4].to_i

# By default, ParamILS builds parameters as -param, but Spear requires
# --param. The following line fixes that.
tmpparams = ARGV[5...ARGV.length].collect{|x| x.sub(/^-sp/, "--sp")}

# Concatenate all params.
paramstring = tmpparams.join(" ")

# Build algorithm command and execute it.
#
# Change --dimacs according to your input (--sf for modular arithmetic)
cmd = "./Spear-32_1.2.1 --nosplash --time #{paramstring} --dimacs #{input_file} --tmout #{timeout} --seed #{seed}"

tmp_file = "spear_output#{rand}.txt"
exec_cmd = "#{cmd} > #{tmp_file}"

solved = "CRASHED"
runtime = nil

Signal.trap("TERM") {
    #=== Respond to termination by deleting temporary file
    # and reporting timeout.
	begin
		File.delete(tmp_file)
	rescue SystemCallError
	    # ignore ENOENT errors.
	end
    puts "Result for HAL: TIMEOUT"
    Process.exit 1
}

begin
    STDERR.puts "Calling: #{exec_cmd}"
    system exec_cmd

    #=== Parse algorithm output to extract relevant information for ParamILS.
    File.open(tmp_file){|file|
        while line = file.gets
            if line =~ /s UNSATISFIABLE/
                solved = "UNSAT"
	        end
            if line =~ /s SATISFIABLE/
                solved = "SAT"
            end
            if line =~ /s UNKNOWN/
		    solved = "TIMEOUT"
            end
            if line =~ /runtime (\d+\.\d+)/
                runtime = $1.to_f
            end
        end
    }
ensure
	begin
		File.delete(tmp_file)
	rescue SystemCallError
	    # ignore ENOENT errors. (errno 2)
	end
	
    puts "Result for HAL: #{solved}, #{runtime}, 0, 0, #{seed}"

    if solved == "CRASHED"
        Process.exit 1
    end
end
#instances/SPEAR-SWV-q075inst/winegcc_vc1107.cnf 0 5 max 1410541459 --sp-var-dec-heur 0 --sp-learned-clause-sort-heur 0 --sp-orig-clause-sort-heur 0 --sp-res-order-heur 0 --sp-clause-del-heur 2 --sp-phase-dec-heur 5 --sp-resolution 1 --sp-variable-decay 1.4 --sp-clause-decay 1.4 --sp-restart-inc 1.5 --sp-learned-size-factor -0.916290731874155 --sp-learned-clauses-inc 1.3 --sp-clause-activity-inc 1.0 --sp-var-activity-inc 1.0 --sp-rand-phase-dec-freq -6.907755278982137 --sp-rand-var-dec-freq -6.907755278982137 --sp-rand-var-dec-scaling 1.0 --sp-rand-phase-scaling 1.0 --sp-max-res-lit-inc 1.0 --sp-first-restart 4.605170185988092 --sp-res-cutoff-cls 2.0794415416798357 --sp-res-cutoff-lits 5.991464547107982 --sp-max-res-runs 1.3862943611198906 --sp-update-dec-queue 1 --sp-use-pure-literal-rule 1 

