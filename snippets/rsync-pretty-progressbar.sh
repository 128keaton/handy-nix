# Requires 'pv'
# sudo apt install pv
#
# Example output
# 1161 files to copy.
# [===================>] 100%

# Get the total files to be moved with rsync
TOTAL=$(rsync -av  --dry-run  /from /to | wc -l)

# Display the total number of files to be copied
echo "$TOTAL files to copy"

# Finally, lets do it for real, piping the output to 'pv'
rsync -av /from /to | pv -lep -s "$TOTAL" >/dev/null
