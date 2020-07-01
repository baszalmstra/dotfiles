cur_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Trueline PS1
declare -a TRUELINE_SEGMENTS=(
	'user,black,white,bold'
        'venv,black,purple,bold'
        'git,grey,special_grey,normal'
        'working_dir,mono,cursor_grey,normal'
        'read_only,black,orange,bold'
        'exit_status,black,red,bold'
        #'bg_jobs,black,orange,bold'
        
        #'newline,black,orange,bold'
	'newline,white,black,bold'
)

source "$cur_dir/external/trueline/trueline.sh"
