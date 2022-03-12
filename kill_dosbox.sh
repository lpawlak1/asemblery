kill -9 `ps | grep dosbox | awk '{print $1}'`
dosbox &
