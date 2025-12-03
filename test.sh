#!/usr/bin/env bash

# Colors for test output
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Check if ZKSYNC_RPC_URL is set
if [ -z "${ZKSYNC_RPC_URL}" ]; then
    echo "Error: ZKSYNC_RPC_URL environment variable is not set"
    echo "Please set it to run the tests, for example:"
    echo "export ZKSYNC_RPC_URL=https://mainnet.era.zksync.io"
    exit 1
fi

# Utility function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"
    
    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${RESET}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: $test_name"
        if [ -n "$message" ]; then
            echo "  Error: $message"
        fi
        ((TESTS_FAILED++))
    fi
}

# Test get-zk-id command (ZIP-3)
test_get_zk_id() {
    echo "Testing get-zk-id command..."
    
    # Known transaction hash and expected proposal ID
    local tx_hash="0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1"
    local expected_id_decimal="39897055470405054808751466940888279812739313934036970931300785151980460250983"
    
    # Run the command and capture output
    local output=$(./zkgov-check.sh get-zk-id "$tx_hash" --rpc-url "$ZKSYNC_RPC_URL")
    
    # Check if the expected decimal ID is in the output
    if echo "$output" | grep -q "$expected_id_decimal"; then
        print_test_result "get-zk-id Proposal ID Check" 0
    else
        print_test_result "get-zk-id Proposal ID Check" 1 "Expected proposal ID $expected_id_decimal not found in output"
    fi
}

# Test get-upgrades command (ZIP-4)
test_get_upgrades() {
    echo "Testing get-upgrades command..."
    
    # Known transaction hash
    local tx_hash="0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1"
    
    # Run the command and capture output
    local output=$(./zkgov-check.sh get-upgrades "$tx_hash" --rpc-url "$ZKSYNC_RPC_URL")
    
    # Check if the output contains expected patterns
    if echo "$output" | grep -q "ZKsync Transactions"; then
        print_test_result "get-upgrades ZKsync Transactions Header Check" 0
    else
        print_test_result "get-upgrades ZKsync Transactions Header Check" 1 "ZKsync Transactions header not found"
    fi
    
    if echo "$output" | grep -q "Target Address"; then
        print_test_result "get-upgrades Target Address Check" 0
    else
        print_test_result "get-upgrades Target Address Check" 1 "Target Address field not found"
    fi
    
    # Check if there's at least one ETH transaction
    if echo "$output" | grep -q "Ethereum Transaction"; then
        print_test_result "get-upgrades Ethereum Transaction Check" 0
    else
        print_test_result "get-upgrades Ethereum Transaction Check" 1 "No Ethereum Transaction found"
    fi
}

# Test get-eth-id command (ZIP-4)
test_get_eth_id() {
    echo "Testing get-eth-id command..."
    
    # Known transaction hash
    local tx_hash="0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1"
    
    # Run the command and capture output
    local output=$(./zkgov-check.sh get-eth-id "$tx_hash" --rpc-url "$ZKSYNC_RPC_URL")
    
    # Check if the output contains "Ethereum proposal ID"
    if echo "$output" | grep -q "Ethereum proposal ID"; then
        print_test_result "get-eth-id Proposal ID Check" 0
    else
        print_test_result "get-eth-id Proposal ID Check" 1 "Ethereum proposal ID not found"
    fi
    
    # Run with --show-solidity and check for Solidity contract output
    output=$(./zkgov-check.sh get-eth-id "$tx_hash" --rpc-url "$ZKSYNC_RPC_URL" --show-solidity)
    
    if echo "$output" | grep -q "CONTRACT"; then
        print_test_result "get-eth-id Solidity Contract Check" 0
    else
        print_test_result "get-eth-id Solidity Contract Check" 1 "Solidity contract not found"
    fi
}

# Test get-upgrades with multisig execTransaction (ZIP-14)
test_get_upgrades_multisig() {
    echo "Testing get-upgrades with multisig transaction..."

    local tx_hash="0xbdf91e5b92893ed6d8609ef2e1bf12f953aed1b994317e493bd789470afab62f"

    # Run the command and capture both stdout and stderr
    local output=$(./zkgov-check.sh get-upgrades "$tx_hash" --rpc-url "$ZKSYNC_RPC_URL" 2>&1)

    # Check if multisig detection message is present
    if echo "$output" | grep -q "Multisig Transaction Detected"; then
        print_test_result "get-upgrades Multisig Detection" 0
    else
        print_test_result "get-upgrades Multisig Detection" 1 "Multisig Transaction Detected header not found"
    fi

    # Check if execTransaction parameters are displayed
    if echo "$output" | grep -q "SafeTxGas"; then
        print_test_result "get-upgrades Multisig Parameters" 0
    else
        print_test_result "get-upgrades Multisig Parameters" 1 "execTransaction parameters not found"
    fi

    # Check if the inner propose call is still processed
    if echo "$output" | grep -q "ZKsync Transactions"; then
        print_test_result "get-upgrades Multisig Inner Propose" 0
    else
        print_test_result "get-upgrades Multisig Inner Propose" 1 "Inner propose call not processed"
    fi
}

# Test get-eth-id with --from-file option (ZIP-5)
test_get_eth_id_from_file() {
    echo "Testing get-eth-id with --from-file option..."
    
    # Create a temporary test file
    local test_file="test_proposal.json"
    cat > "$test_file" << EOF
{
    "executor": "0xECE8e30bFc92c2a8e11e6cb2e17B70868572E3f6",
    "salt": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "calls": [
        {
            "target": "0x303a465b659cbb0ab36ee643ea362c509eeb5213",
            "value": "0x00",
            "data": "0x79ba5097"
        },
        {
            "target": "0xc2ee6b6af7d616f6e27ce7f4a451aedc2b0f5f5c",
            "value": "0x00",
            "data": "0x79ba5097"
        }
    ]
}
EOF
    
    # Run the command and capture output
    local output=$(./zkgov-check.sh get-eth-id --from-file "$test_file")
    
    # Check if the output contains "Ethereum Proposal ID" and "Encoded Proposal"
    if echo "$output" | grep -q "Proposal ID"; then
        print_test_result "get-eth-id --from-file Proposal ID Check" 0
    else
        print_test_result "get-eth-id --from-file Proposal ID Check" 1 "Proposal ID not found"
    fi
    
    if echo "$output" | grep -q "Encoded Proposal"; then
        print_test_result "get-eth-id --from-file Encoded Proposal Check" 0
    else
        print_test_result "get-eth-id --from-file Encoded Proposal Check" 1 "Encoded Proposal not found"
    fi
    
    # Clean up
    rm -f "$test_file"
}

# Run all tests
run_all_tests() {
    echo "Running zkgov-check tests..."
    echo "=========================================="
    
    test_get_zk_id
    echo "----------------------------------------"
    test_get_upgrades
    echo "----------------------------------------"
    test_get_upgrades_multisig
    echo "----------------------------------------"
    test_get_eth_id
    echo "----------------------------------------"
    test_get_eth_id_from_file
    
    echo "=========================================="
    echo "Test Results:"
    echo "============"
    echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${RESET}"
    echo -e "Tests Failed: ${RED}${TESTS_FAILED}${RESET}"
    
    # Exit with failure if any tests failed
    [ "$TESTS_FAILED" -eq 0 ] || exit 1
}

# Run all tests
run_all_tests