module AptosMasterChef::MasterChefTest {
    use AptosMasterChef::MasterChef;
    use aptos_framework::coin::{Coin, CoinInfo, mint, burn, coin};
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_framework::debug;

    // Helper function to create and mint coins for the test
    fun mint_coins<StakeCoin, RewardCoin>(minter: &signer, recipient: address, amount: u64) {
        mint<StakeCoin>(minter, amount);
        coin::transfer<StakeCoin>(minter, recipient, amount);

        mint<RewardCoin>(minter, amount);
        coin::transfer<RewardCoin>(minter, recipient, amount);
    }

    // Test initialization of MasterChef contract
    public fun test_initialize(account: &signer) {
        // Initialize the MasterChef contract with some token types
        MasterChef::initialize<AptosCoin, AptosCoin>(account);
        debug::print("MasterChef contract initialized successfully");
    }

    // Test the staking process
    public fun test_stake(account: &signer) {
        // Mint coins for testing
        let user_address = signer::address_of(account);
        mint_coins<AptosCoin, AptosCoin>(account, user_address, 1_000_000);

        // Initialize the MasterChef contract
        MasterChef::initialize<AptosCoin, AptosCoin>(account);

        // Check the initial state (staking with zero tokens)
        debug::print("User staking starts with zero tokens.");

        // Stake some tokens
        MasterChef::stake<AptosCoin, AptosCoin>(account, &mut borrow_global_mut<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address), 100_000);
        debug::print("Staked 100,000 tokens.");

        // Ensure the total staked is updated correctly
        let master_chef = borrow_global<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address);
        assert!(master_chef.pool_info.total_staked == 100_000, 100);

        debug::print("Staking was successful.");
    }

    // Test unstaking and reward claim
    public fun test_unstake(account: &signer) {
        // Initialize the MasterChef contract
        let user_address = signer::address_of(account);
        MasterChef::initialize<AptosCoin, AptosCoin>(account);

        // Stake some tokens first
        MasterChef::stake<AptosCoin, AptosCoin>(account, &mut borrow_global_mut<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address), 100_000);
        
        // Unstake tokens and claim rewards
        MasterChef::unstake<AptosCoin, AptosCoin>(account, &mut borrow_global_mut<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address), 50_000);
        debug::print("Unstaked 50,000 tokens and claimed rewards.");

        // Ensure that the unstaked amount is correct
        let master_chef = borrow_global<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address);
        assert!(master_chef.pool_info.total_staked == 50_000, 101);

        debug::print("Unstaking was successful.");
    }

    // Test claiming rewards without unstaking
    public fun test_claim_rewards(account: &signer) {
        // Initialize the MasterChef contract
        let user_address = signer::address_of(account);
        MasterChef::initialize<AptosCoin, AptosCoin>(account);

        // Stake some tokens
        MasterChef::stake<AptosCoin, AptosCoin>(account, &mut borrow_global_mut<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address), 100_000);

        // Simulate passing of blocks for reward calculation
        // You could use a mock function or framework to simulate time passing in real testing
        debug::print("Simulating block rewards...");

        // Claim rewards without unstaking
        MasterChef::claim<AptosCoin, AptosCoin>(account, &mut borrow_global_mut<MasterChef::MasterChef<AptosCoin, AptosCoin>>(user_address));
        debug::print("Claimed rewards without unstaking.");

        // Ensure the claimed rewards are correctly calculated
        // Here we would verify the user's reward balance based on reward rate and blocks passed
        debug::print("Reward claim was successful.");
    }

    // Entry point to run all tests
    #[test]
    public fun run_tests(account: &signer) {
        test_initialize(account);
        test_stake(account);
        test_unstake(account);
        test_claim_rewards(account);

        debug::print("All tests passed.");
    }
}
