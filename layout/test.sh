# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

echo $(get_ibc_denom_trace "$NAM_IBC")
echo $(gen_ibc_memo "$NAM_SHIELDED" "$NAM_IBC" "100")