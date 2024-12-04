#!/bin/sh

#This file shows some examples of how to use the manage_shebang script.

#This goes through each python file and will replace the shebang with
# #!/usr/bin/env my_python_wrapper, unless that shebang includes 'impala-python'.
find testdata/python -type f -name "*.py"\
     -exec ../manage_shebang.sh -f {} -e my_python_wrapper -v -i impala-python \;
echo
printf "Showing the first line of each python file\n"
for f in testdata/python/*.py; do
    printf "%s: %s\n" "$f" "$(head -n 1 "$f")"
done
#Now that we've modified everything, set it back to what it was originally
#using the .orig backup files we created
for f in testdata/python/*.orig; do
    if [ -f "$f" ]; then
        NAME="$(echo "$f" | awk -F"." '{for(i=1; i < NF; i++) output=output $i (i<NF-1 ? "." : "");} END{print output}')"
        \mv "$f" "$NAME"
    fi
done

#It can also be used on non-python files. This will change all sh files to use
#ksh (korn shell) instead of their current shell
find testdata/shell -type f -name "*.sh"\
     -exec ../manage_shebang.sh -f {} -p /bin/ -e ksh -v \;
echo
echo "Printing new shell shebangs..."
for f in testdata/shell/*.sh; do
    printf "%s: %s\n" "$f" "$(head -n 1 "$f")"
done
for f in testdata/shell/*.orig; do
    if [ -f "$f" ]; then
        NAME="$(echo "$f" | awk -F"." '{for(i=1; i < NF; i++) output=output $i (i<NF-1 ? "." : "");} END{print output}')"
        \mv "$f" "$NAME"
    fi
done
