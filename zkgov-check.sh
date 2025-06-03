#!/usr/bin/env bash

# @license GNU Affero General Public License v3.0 only
# @author patrickalphac

# Enable strict error handling:
# -E: Inherit `ERR` traps in functions and subshells.
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error and exit.
# -o pipefail: Return the exit status of the first failed command in a pipeline.
set -Eeuo pipefail

# Enable debug mode if the environment variable `DEBUG` is set to `true`.
if [[ "${DEBUG:-false}" == "true" ]]; then
    # Print each command before executing it.
    set -x
fi

# Default values
# Set the terminal formatting constants.
readonly VERSION="0.1.0"
readonly GREEN="\e[32m"
readonly RED="\e[31m"
readonly UNDERLINE="\e[4m"
readonly BOLD="\e[1m"
readonly RESET="\e[0m"
readonly DEFAULT_GOVERNOR="0x76705327e682F2d96943280D99464Ab61219e34f" # This is the Era L2 governance contract
readonly PROPOSAL_CREATED_TOPIC="0x7d84a6263ae0d98d3329bd7b46bb4e8d6f98cd35a7adb45c274c8b7fd5ebd5e0"
readonly DEFAULT_MAILBOX="0x32400084C286CF3E17e7B677ea9583e60a000324" # This is the ETH L1 mailbox contract for sending messages to L2

print_help() {
    cat << EOF
zkSync Era Governance Tool ${VERSION}

Usage: 
    ${0##*/} [options] <command> <tx_hash> [--rpc-url URL] [--governor ADDRESS]

Commands:
    get-zk-id     Get the zkSync proposal ID from a transaction hash
    get-upgrades  Get the upgrade details from a transaction hash
    get-eth-id    Get the Ethereum proposal ID from a transaction hash [Not implemented]

Options:
    -h, --help           Show this help message
    -v, --version        Show version information
    --show-solidity      Show Solidity contracts for verification (on get-eth-id)
    --decode             Decode calldata for each transaction (on get-upgrades)
    --rpc-url URL        RPC URL for zkSync Era (can also be set via ZKSYNC_RPC_URL env var)
    --governor           Governor contract address (optional)
    --from-file FILE     Read proposal from JSON file (for get-eth-id or get-upgrades command)

Examples:
    ${0##*/} get-upgrades 0x123... --rpc-url https://mainnet.era.zksync.io
    ${0##*/} get-zk-id 0x123... --rpc-url \$ZKSYNC_RPC_URL
    ${0##*/} get-eth-id 0x123... --rpc-url \$ZKSYNC_RPC_URL --show-solidity
    ${0##*/} get-eth-id --from-file proposal.json
EOF
}

print_version() {
    echo "${0##*/} version ${VERSION}"
}

# Command: get-zk-id
get_zk_id() {
    local tx_hash="$1"
    local rpc_url="$2"
    local governor="$3"
    
    # Get transaction receipt and extract proposal ID
    local receipt=$(cast receipt "$tx_hash" --rpc-url "$rpc_url" --json)
    local proposal_log=$(echo "$receipt" | jq -r --arg topic "$PROPOSAL_CREATED_TOPIC" '.logs[] | select(.topics[0] == $topic) | .data[0:66]')
    
    # Extract proposal ID (first 32 bytes / 64 characters after '0x')
    local proposal_id_dec=$(cast to-base "$proposal_log" dec)
    
    print_header "Proposal ID"
    print_field "Hex" $proposal_log
    print_field "Decimal" $proposal_id_dec
}

decode_with_fallback() {
    local signature="$1"
    local data="$2"
    local decoded_data
    
    # Try cast first
    if decoded_data=$(cast calldata-decode "$signature" "$data" 2>&1); then
        # Success - return the decoded data
        echo "$decoded_data"
        return 0
    else
        # Check if it's the "Argument list too long" error
        if [[ "$decoded_data" == *"Argument list too long"* ]]; then
            # Use uv with Python fallback
            if command -v uv >/dev/null 2>&1; then
                # Create Python decoder script if it doesn't exist
                local decoder_script="/tmp/decode_calldata_$$.py"
                cat > "$decoder_script" << 'EOF'
import sys
import json
from eth_abi import decode

# Read hex from file
with open(sys.argv[1], 'r') as f:
    hex_data = f.read().strip()

# Remove 0x and function selector (first 8 chars after 0x)
if hex_data.startswith('0x'):
    hex_data = hex_data[2:]
# Function selector is 4 bytes = 8 hex chars
data_hex = hex_data[8:]
bytes_data = bytes.fromhex(data_hex)

# Decode based on signature
signature = sys.argv[2]
if "propose(address[],uint256[],bytes[],string)" in signature:
    types = ['address[]', 'uint256[]', 'bytes[]', 'string']
    decoded = decode(types, bytes_data)
    
    # Format output similar to cast
    addresses = ["0x" + addr.hex() if isinstance(addr, bytes) else addr for addr in decoded[0]]
    print("[" + ", ".join(addresses) + "]")
    print("[" + ", ".join(str(d) for d in decoded[1]) + "]")
    print("[" + ", ".join("0x" + d.hex() for d in decoded[2]) + "]")
    print(decoded[3])
else:
    print(f"Error: Unsupported signature: {signature}")
    sys.exit(1)
EOF
                
                # Write data to file and decode with uv
                local data_file="/tmp/large_calldata_$$.hex"
                echo "$data" > "$data_file"
                
                if uv run --no-project --with eth-abi "$decoder_script" "$data_file" "$signature"; then
                    rm -f "$data_file" "$decoder_script"
                    return 0
                else
                    echo "Error: Python decoder failed" >&2
                    rm -f "$data_file" "$decoder_script"
                    return 1
                fi
            else
                echo "Error: Argument list too long and uv not available for fallback" >&2
                echo "Install uv from https://github.com/astral-sh/uv" >&2
                return 1
            fi
        else
            # Some other error - display it
            echo "$decoded_data" >&2
            return 1
        fi
    fi
}


# Command: get-upgrades
get_upgrades() {
    local tx_hash="$1"
    local rpc_url="$2"
    local governor="$3"
    local decode_flag="$4"
    
    # Get transaction data
    local tx_data=$(cast tx "$tx_hash" --rpc-url "$rpc_url" --json)
    local input_data=$(echo "$tx_data" | jq -r '.input')
    local to_address=$(echo "$tx_data" | jq -r '.to')
    
    # Decode the propose call
    # local decoded_data=$(cast calldata-decode "propose(address[],uint256[],bytes[],string)" "$input_data")
    local decoded_data=$(decode_with_fallback "propose(address[],uint256[],bytes[],string)" "$input_data")

    # Extract arrays using sed and convert to arrays
    # Remove brackets and get first line
    local targets_string=$(echo "$decoded_data" | sed -n '1s/^\[\(.*\)\]/\1/p')
    # Get second line
    local values_string=$(echo "$decoded_data" | sed -n '2s/^\[\(.*\)\]/\1/p')
    # Get third line
    local calldatas_string=$(echo "$decoded_data" | sed -n '3s/^\[\(.*\)\]/\1/p')
    
    # Convert comma-separated strings to arrays
    IFS=',' read -ra targets_array <<< "$targets_string"
    IFS=',' read -ra values_array <<< "$values_string"
    IFS=',' read -ra calldatas_array <<< "$calldatas_string"
    
    print_header "ZKsync Transactions"
    
    # Process each transaction
    local num_transactions=${#targets_array[@]}
    for ((i=0; i<num_transactions; i++)); do
        # Trim whitespace
        local target=$(echo "${targets_array[$i]}" | xargs)
        local value=$(echo "${values_array[$i]}" | xargs)
        local calldata=$(echo "${calldatas_array[$i]}" | xargs)
        
        printf "\nZKsync Transaction #%d:\n" "$((i+1))"
        print_field "Target Address" "$target"
        print_field "Value" "$value"
        print_field "Calldata" "$calldata"
        
        # Check if this is an ETH transaction
        if [[ "$target" == "0x0000000000000000000000000000000000008008" ]] && [[ "$calldata" == 0x62f84b24* ]]; then # This is the "sendToL1" function
            if [[ -t 1 ]] && tput sgr0 >/dev/null 2>&1; then
                printf "${BOLD}(ETH transaction)${RESET}\n"
            else
                printf "(This is an ETH transaction)\n"
            fi
            
            # Process L2->L1 transaction
            local l1_data=$(cast calldata-decode "sendToL1(bytes)" "$calldata")
            local l1_data_with_prefix="0xa1dcb9b8${l1_data:2}"
            
            # Decode the L1 execution data
            local l1_decoded=$(cast decode-calldata "execute(((address,uint256,bytes)[],address,bytes32))" "$l1_data_with_prefix")
            
            print_header "Ethereum Transaction #$((i+1))"
            
            # Remove outer parentheses and get the parts
            local cleaned_data="${l1_decoded#(}"
            cleaned_data="${cleaned_data%)}"

            # Extract the executor and salt from the end
            local executor=$(echo "$cleaned_data" | grep -o "0x[0-9a-fA-F]\{40\}" | tail -n1)
            local salt=$(echo "$cleaned_data" | grep -o "0x[0-9a-fA-F]\{64\}" | tail -n1)

            # Remove outer brackets to get operations part
            if [[ "$cleaned_data" =~ \[(.*)\],[[:space:]]*0x ]]; then
                local ops_part="${BASH_REMATCH[1]}"
                
                # Keep processing until we've handled all operations
                while [[ "$ops_part" == *"("* ]]; do
                    # Get the content between parentheses
                    local op_content="${ops_part#*\(}"
                    op_content="${op_content%%\)*}"
                    
                    if [[ -n "$op_content" ]]; then
                        # Split into components
                        IFS=',' read -r target value calldata <<< "$op_content"
                        
                        printf "\n  Call:\n"
                        print_field "    Target" "$target"
                        # Clean up value
                        value=$(echo "$value" | sed 's/\[.*\]//' | xargs)
                        print_field "    Value" "$value"
                        print_field "    Calldata" "$calldata"
                        if [ "$decode_flag" = true ]; then
                            decode_and_print_calldata "$calldata" "    "
                        fi
                        
                        # Remove processed operation
                        ops_part="${ops_part#*\)}"
                        ops_part="${ops_part#, }"
                    else
                        break
                    fi
                done
            fi
            
            printf "\n"
            print_field "Executor" "$executor"
            print_field "Salt" "$salt"
        else 
            if [ "$decode_flag" = true ]; then
                decode_and_print_calldata "$calldata"
            fi
        fi
    done
}

# Function to decode and format calldata
decode_and_print_calldata() {
    local calldata="$1"
    local padding="${2:-}"
    local decoded_output
    
    # Get the decoded output from cast
    if [[ ${#calldata} -eq 11 ]]; then
        # Use cast 4byte for function selectors
        decoded_output=$(cast 4byte  $(echo "$calldata" | xargs)) || true
    else
        # Use cast 4byte-decode for full calldata
        decoded_output=$(cast 4byte-decode $(echo "$calldata" | xargs)) || true
    fi
    
    printf "${padding}Decoded Calldata:\n" 
    echo "${padding}$decoded_output"
}

# Command: get_eth_id
get_eth_id() {
    local tx_hash="$1"
    local rpc_url="$2"
    local governor="$3"
    local show_solidity="$4"
    local from_file="$5"
    
    if [[ -n "$from_file" ]]; then
        process_eth_id_from_file "$from_file"
    else
        process_eth_id_from_tx "$tx_hash" "$rpc_url" "$governor" "$show_solidity"
    fi
}

process_eth_id_from_tx() {
    # Get transaction data and decode the proposal calldata.
    local tx_data
    tx_data=$(cast tx "$tx_hash" --rpc-url "$rpc_url" --json)
    local input_data
    input_data=$(echo "$tx_data" | jq -r '.input')
    local decoded_data
    decoded_data=$(cast calldata-decode "propose(address[],uint256[],bytes[],string)" "$input_data")

    # Extract the three arrays (targets, values, calldatas)
    local targets_string
    targets_string=$(echo "$decoded_data" | sed -n '1s/^\[\(.*\)\]/\1/p')
    local values_string
    values_string=$(echo "$decoded_data" | sed -n '2s/^\[\(.*\)\]/\1/p')
    local calldatas_string
    calldatas_string=$(echo "$decoded_data" | sed -n '3s/^\[\(.*\)\]/\1/p')

    IFS=',' read -ra targets_array <<< "$targets_string"
    IFS=',' read -ra values_array <<< "$values_string"
    IFS=',' read -ra calldatas_array <<< "$calldatas_string"

    local eth_tx_counter=0
    local num_transactions=${#targets_array[@]}

    for (( i = 0; i < num_transactions; i++ )); do
        local target
        target=$(echo "${targets_array[$i]}" | xargs)
        local value
        value=$(echo "${values_array[$i]}" | xargs)
        # Remove any extra text (like a scientific notation annotation) from the value.
        value="${value%% *}"
        local calldata
        calldata=$(echo "${calldatas_array[$i]}" | xargs)

        # Check if this transaction is an ETH transaction.
        if [[ "$target" == "0x0000000000000000000000000000000000008008" && "$calldata" == 0x62f84b24* ]]; then
            eth_tx_counter=$((eth_tx_counter + 1))

            # Decode the L1 data inside the ETH call.
            local l1_data
            l1_data=$(cast calldata-decode "sendToL1(bytes)" "$calldata")
            local l1_data_with_prefix="0xa1dcb9b8${l1_data:2}"
            local l1_decoded
            l1_decoded=$(cast decode-calldata "execute(((address,uint256,bytes)[],address,bytes32))" "$l1_data_with_prefix")

            # Extract executor and salt.
            local executor
            executor=$(echo "$l1_decoded" | grep -o "0x[0-9a-fA-F]\{40\}" | tail -n1)
            local salt
            salt=$(echo "$l1_decoded" | grep -o "0x[0-9a-fA-F]\{64\}" | tail -n1)

            # Extract the operations (calls) part from the decoded output.
            local ops_part
            if [[ "$l1_decoded" =~ \[(.*)\],[[:space:]]*0x ]]; then
                ops_part="${BASH_REMATCH[1]}"
            else
                echo "Error: Could not extract operations from ETH transaction $eth_tx_counter"
                continue
            fi

            # Reconstruct the calls array in a format suitable for abi-encode
            local calls_array=""
            local call_index=0
            local contract_calls_sol=""
            
            # Process each operation in the operations array.
            while [[ "$ops_part" == *"("* ]]; do
                local op_content="${ops_part#*(}"
                op_content="${op_content%%)*}"
                if [[ -n "$op_content" ]]; then
                    IFS=',' read -r op_target op_value op_calldata <<< "$op_content"
                    op_target=$(echo "$op_target" | xargs)
                    op_value=$(echo "$op_value" | xargs)
                    op_value="${op_value%% *}"
                    op_calldata=$(echo "$op_calldata" | xargs)
                    
                    # Add this call to the calls array for direct calculation
                    if [[ -n "$calls_array" ]]; then
                        calls_array+=","
                    fi
                    calls_array+="($op_target,$op_value,$op_calldata)"
                    
                    # For Solidity code generation
                    if [[ "$show_solidity" == "true" ]]; then
                        call_index=$((call_index + 1))
                        # Remove the "0x" prefix for Solidity's hex literal syntax.
                        local op_calldata_hex="${op_calldata#0x}"
                        contract_calls_sol+=$'\n'"    IProtocolUpgradeHandler.Call call${call_index} = IProtocolUpgradeHandler.Call({"
                        contract_calls_sol+=$'\n'"        target: ${op_target},"
                        contract_calls_sol+=$'\n'"        value: ${op_value},"
                        contract_calls_sol+=$'\n'"        data: hex\"${op_calldata_hex}\""
                        contract_calls_sol+=$'\n'"    });"
                    fi
                    
                    # Remove the processed operation (and any following comma+space).
                    ops_part="${ops_part#*)}"
                    ops_part="${ops_part#, }"
                else
                    break
                fi
            done
            
            # Construct the final UpgradeProposal and calculate the hash
            local proposal="([$calls_array],$executor,$salt)"
            local encoded_proposal
            encoded_proposal=$(cast abi-encode "UpgradeProposal(((address,uint256,bytes)[],address,bytes32))" "$proposal")
            local proposal_id
            proposal_id=$(cast keccak "$encoded_proposal")
            
            # Always show the proposal ID directly
            echo "Ethereum proposal ID #$eth_tx_counter: $proposal_id"
            
            # If show_solidity is true, also generate and output the Solidity contract
            if [[ "$show_solidity" == "true" ]]; then
                # (Inside the loop for each ETH transaction, after processing its operations.)
                # Now output the complete Solidity contract for this ETH transaction.
                cat <<EOF


/*//////////////////////////////////////////////////////////////
                              CONTRACT ${eth_tx_counter}
//////////////////////////////////////////////////////////////*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IProtocolUpgradeHandler} from "src/interfaces/IProtocolUpgradeHandler.sol";
import {Test, console} from "forge-std/Test.sol";

contract ZIPTest_eth_${eth_tx_counter} {
    bytes32 public salt = ${salt};
    IProtocolUpgradeHandler.Call[] public calls;
${contract_calls_sol}

    constructor() {
EOF
                local j
                for (( j = 1; j <= call_index; j++ )); do
                    echo "        calls.push(call${j});"
                done
                cat <<EOF
    }

    function getHash() public view returns (bytes32) {
        IProtocolUpgradeHandler.UpgradeProposal memory upgradeProposal = IProtocolUpgradeHandler.UpgradeProposal({
            calls: calls,
            salt: salt,
            executor: ${executor}
        });
        return keccak256(abi.encode(upgradeProposal));
    }
}
EOF

                # Append the test contract at the end of the file.
                cat <<EOF
contract TestZIPEth_${eth_tx_counter} is Test {
    ZIPTest_eth_${eth_tx_counter} zip;

    function setUp() public {
        zip = new ZIPTest_eth_${eth_tx_counter}();
    }

    function testZIPEthProposalId_${eth_tx_counter}() public view {
        bytes32 hash = zip.getHash();
        console.logBytes32(hash);
    }
}
EOF

                echo ""  # extra newline separator
            fi
        fi
    done

    if [ "$eth_tx_counter" -eq 0 ]; then
        echo "Error: No ETH transactions found in proposal."
        exit 1
    fi

    if [[ "$eth_tx_counter" -gt 0 && "$show_solidity" == "true" ]]; then
        echo "Total ETH transactions (and therefore, contracts): ${eth_tx_counter}"
        echo "The proposal IDs have been calculated directly above."
        echo "If you'd like to verify via Solidity, copy paste the contract you're looking for into the test folder, and run:"
        echo "  forge test --mt testZIPEthProposalId --mc TestZIPEth_* -vv"
    fi
}

process_eth_id_from_file() {
    local file_path="$1"
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        echo "Error: File not found: $file_path"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq to parse JSON files."
        exit 1
    fi
    
    # Parse the JSON file
    local executor
    executor=$(jq -r '.executor // empty' "$file_path")
    # If executor is null or empty, use the zero address
    if [[ -z "$executor" ]]; then
        executor="0x0000000000000000000000000000000000000000"
    fi

    local salt
    salt=$(jq -r '.salt // empty' "$file_path")
    # If salt is null or empty, use the zero bytes32
    if [[ -z "$salt" ]]; then
        salt="0x0000000000000000000000000000000000000000000000000000000000000000"
    fi
    
    # Extract the array of calls
    local calls_array=""
    local calls_count
    calls_count=$(jq '.calls | length' "$file_path")
    
    for (( i = 0; i < calls_count; i++ )); do
        local target
        target=$(jq -r ".calls[$i].target" "$file_path")
        
        local value
        value=$(jq -r ".calls[$i].value" "$file_path")
        # If value is in hex format, convert to decimal
        if [[ "$value" == 0x* ]]; then
            value=$(cast --to-dec "$value")
        fi
        
        local data
        data=$(jq -r ".calls[$i].data" "$file_path")
        
        # Add this call to the calls array
        if [[ -n "$calls_array" ]]; then
            calls_array+=","
        fi
        calls_array+="($target,$value,$data)"
    done
    
    # Construct the final UpgradeProposal
    local proposal="([$calls_array],$executor,$salt)"
    
    # Encode the UpgradeProposal struct and compute its keccak256 hash
    local encoded_proposal
    encoded_proposal=$(cast abi-encode "UpgradeProposal(((address,uint256,bytes)[],address,bytes32))" "$proposal")
    local proposal_id
    proposal_id=$(cast keccak "$encoded_proposal")
    
    # Print the result
    print_header "Ethereum Proposal ID"
    print_field "Proposal ID" "$proposal_id"
    print_field "Encoded Proposal" "$encoded_proposal"
}

main() {
    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        print_help
        exit 0
    fi

    local decode_flag=false
    local show_solidity=false
    local from_file=false
    local command=""
    local tx_hash=""

    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_help
                exit 0
                ;;
            -v|--version)
                print_version
                exit 0
                ;;
            get-zk-id|get-upgrades)
                command="$1"
                if [ -z "$2" ]; then
                    echo "Error: Missing transaction hash for command '$1'"
                    print_help
                    exit 1
                fi
                tx_hash="$2"
                shift 2
                ;;
            get-eth-id)
                command="$1"
                # For get-eth-id, we'll either expect a transaction hash or --from-file later
                if [[ "$2" == "--"* ]]; then
                    # If the next argument is an option (starts with --), just record the command
                    shift 1
                else
                    # Otherwise, it's likely a transaction hash
                    if [ -z "$2" ]; then
                        echo "Error: Missing transaction hash or --from-file option for command '$1'"
                        print_help
                        exit 1
                    fi
                    tx_hash="$2"
                    shift 2
                fi
                ;;
            --rpc-url)
                if [ -z "$2" ]; then
                    echo "Error: Missing URL after --rpc-url"
                    exit 1
                fi
                rpc_url="$2"
                shift 2
                ;;
            --decode)
                decode_flag=true
                shift 1
                ;;
            --show-solidity)
                show_solidity=true
                shift 1
                ;;
            --governor)
                if [ -z "$2" ]; then
                    echo "Error: Missing address after --governor"
                    exit 1
                fi
                governor="$2"
                shift 2
                ;;
            --from-file)
                if [ -z "$2" ]; then
                    echo "Error: Missing file path after --from-file"
                    exit 1
                fi
                from_file=true
                file_path="$2"
                shift 2
                ;;
            *)
               # If this could be a transaction hash or file path (for the command that expects it)
                if [[ "$1" == 0x* || -f "$1" ]] && [ -z "$tx_hash" ] && [ -z "$file_path" ]; then
                    tx_hash="$1"
                    shift
                else
                    echo "Error: Unknown option or invalid argument: $1"
                    exit 1
                fi
                ;;
        esac
    done

    # Set default values
    local rpc_url="${rpc_url:-${ZKSYNC_RPC_URL:-}}"
    local governor="${governor:-$DEFAULT_GOVERNOR}"

    # Check if command is set
    if [ -z "$command" ]; then
        print_help
        exit 1
    fi

    # Check if RPC URL is set
    if [ -z "${rpc_url}" ]; then
        echo "Error: No RPC URL provided. Either use --rpc-url or set ZKSYNC_RPC_URL environment variable"
        exit 1
    fi

    # Validate arguments based on command
    case "$command" in
        get-zk-id|get-upgrades)
            if [ -z "$tx_hash" ]; then
                echo "Error: Missing transaction hash for command '$command'"
                print_help
                exit 1
            fi
            
            # Check if RPC URL is set
            if [ -z "${rpc_url}" ]; then
                echo "Error: No RPC URL provided. Either use --rpc-url or set ZKSYNC_RPC_URL environment variable"
                exit 1
            fi
            ;;
        get-eth-id)
            if [ "$from_file" = true ]; then
                if [ -z "$file_path" ]; then
                    echo "Error: Missing file path for --from-file option"
                    print_help
                    exit 1
                fi
            else
                if [ -z "$tx_hash" ]; then
                    echo "Error: Missing transaction hash for command '$command'"
                    print_help
                    exit 1
                fi
                
                # Check if RPC URL is set when using transaction hash
                if [ -z "${rpc_url}" ]; then
                    echo "Error: No RPC URL provided. Either use --rpc-url or set ZKSYNC_RPC_URL environment variable"
                    exit 1
                fi
            fi
            ;;
    esac

    # Main command router
    case "$command" in
        get-zk-id)
            get_zk_id "$tx_hash" "$rpc_url" "$governor"
            ;;
        get-upgrades)
            get_upgrades "$tx_hash" "$rpc_url" "$governor" "$decode_flag"
            ;;
        get-eth-id)
            if [ "$from_file" = true ]; then
                get_eth_id "" "$rpc_url" "$governor" "$show_solidity" "$file_path"
            else
                get_eth_id "$tx_hash" "$rpc_url" "$governor" "$show_solidity" ""
            fi
            ;;
        *)
            echo "Error: Unknown command: $command"
            print_help
            exit 1
            ;;
    esac
}

# Utility function to print a section header.
print_header() {
    local header=$1
    if [[ -t 1 ]] && tput sgr0 >/dev/null 2>&1; then
        # Terminal supports formatting.
        printf "\n${UNDERLINE}%s${RESET}\n" "$header"
    else
        # Fallback for terminals without formatting support.
        printf "\n%s\n" "> $header:"
    fi
}

print_parameter(){
    local value=$1
    printf "${GREEN}%s${RESET}\n" "$value"
}

# Utility function to print a labelled value.
print_field() {
    local label=$1
    local value=$2
    local empty_line="${3:-false}"

    if [[ -t 1 ]] && tput sgr0 >/dev/null 2>&1; then
        # Terminal supports formatting.
        printf "%s: ${GREEN}%s${RESET}\n" "$label" "$value"
    else
        # Fallback for terminals without formatting support.
        printf "%s: %s\n" "$label" "$value"
    fi

    # Print an empty line if requested.
    if [[ "$empty_line" == "true" ]]; then
        printf "\n"
    fi
}


# Utility function to ensure all required tools are installed.
check_required_tools() {
    local tools=("curl" "jq" "chisel" "cast")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -ne 0 ]]; then
        echo -e "${BOLD}${RED}The following required tools are not installed:${RESET}"
        for tool in "${missing_tools[@]}"; do
            echo -e "${BOLD}${RED}  - $tool${RESET}"
        done
        echo -e "${BOLD}${RED}Please install them to run the script properly.${RESET}"
        exit 1
    fi
}

check_required_tools
main "$@"