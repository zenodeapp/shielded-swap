# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

echo $(estimate_swap_amount "$NAM_IBC" "10")