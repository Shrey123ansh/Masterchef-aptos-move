module AptosMasterChef::MasterChef {
    use aptos_framework::coin::{Coin, CoinInfo, coin};

    // Struct to store each pool's information
    struct Pool<StakeCoin> has store {
        total_staked: u64,     // Total amount staked in this pool
        reward_rate: u64,      // Reward rate per block
        last_reward_block: u64, // Last block where rewards were distributed
        acc_reward_per_share: u64, // Accumulated rewards per staked token
    }

    // Struct to store user information
    struct UserInfo<StakeCoin> has store {
        amount: u64,           // Amount of tokens the user has staked
        reward_debt: u64,      // Rewards debt
    }

    // Struct for managing pools
    struct MasterChef<StakeCoin, RewardCoin> has store {
        owner: address,        // Owner/Deployer of the contract
        pool_info: Pool<StakeCoin>,
        reward_coin: CoinInfo<RewardCoin>, // Information about reward coin
        stake_coin: CoinInfo<StakeCoin>,   // Information about staked token
    }

    /// Public initializer for creating the MasterChef instance
    public fun initialize<StakeCoin, RewardCoin>(account: &signer) {
        let owner = signer::address_of(account);

        move_to(account, MasterChef {
            owner,
            pool_info: Pool {
                total_staked: 0,
                reward_rate: 1000, // Arbitrary reward rate for demo
                last_reward_block: 0,
                acc_reward_per_share: 0,
            },
            reward_coin: coin::CoinInfo<RewardCoin>(),
            stake_coin: coin::CoinInfo<StakeCoin>(),
        });
    }

    /// Internal function for updating the pool state with rewards
    fun update_pool<StakeCoin, RewardCoin>(chef: &mut MasterChef<StakeCoin, RewardCoin>, block_number: u64) {
        if (block_number <= chef.pool_info.last_reward_block) return;

        if (chef.pool_info.total_staked == 0) {
            chef.pool_info.last_reward_block = block_number;
            return;
        }

        let multiplier = block_number - chef.pool_info.last_reward_block;
        let reward = multiplier * chef.pool_info.reward_rate;
        chef.pool_info.acc_reward_per_share += reward / chef.pool_info.total_staked;
        chef.pool_info.last_reward_block = block_number;
    }

    /// Function for users to stake their tokens
    public fun stake<StakeCoin, RewardCoin>(
        account: &signer, 
        chef: &mut MasterChef<StakeCoin, RewardCoin>, 
        amount: u64
    ) {
        let user_info = borrow_global_mut<UserInfo<StakeCoin>>(signer::address_of(account));

        update_pool(&mut chef, aptos_blockchain::get_current_block_number());

        if (user_info.amount > 0) {
            let pending = (user_info.amount * chef.pool_info.acc_reward_per_share) / 1_000_000 - user_info.reward_debt;
            if (pending > 0) {
                coin::transfer(account, &signer::address_of(account), pending);
            }
        }

        coin::transfer(&signer::address_of(account), &chef.owner, amount);
        user_info.amount += amount;
        user_info.reward_debt = (user_info.amount * chef.pool_info.acc_reward_per_share) / 1_000_000;
    }

    /// Function for users to withdraw staked tokens and claim rewards
    public fun unstake<StakeCoin, RewardCoin>(
        account: &signer, 
        chef: &mut MasterChef<StakeCoin, RewardCoin>, 
        amount: u64
    ) {
        let user_info = borrow_global_mut<UserInfo<StakeCoin>>(signer::address_of(account));

        update_pool(&mut chef, aptos_blockchain::get_current_block_number());

        let pending = (user_info.amount * chef.pool_info.acc_reward_per_share) / 1_000_000 - user_info.reward_debt;
        if (pending > 0) {
            coin::transfer(account, &signer::address_of(account), pending);
        }

        user_info.amount -= amount;
        user_info.reward_debt = (user_info.amount * chef.pool_info.acc_reward_per_share) / 1_000_000;

        coin::transfer(&chef.owner, &signer::address_of(account), amount);
    }

    /// Function to claim rewards without withdrawing staked tokens
    public fun claim<StakeCoin, RewardCoin>(account: &signer, chef: &mut MasterChef<StakeCoin, RewardCoin>) {
        let user_info = borrow_global_mut<UserInfo<StakeCoin>>(signer::address_of(account));

        update_pool(&mut chef, aptos_blockchain::get_current_block_number());

        let pending = (user_info.amount * chef.pool_info.acc_reward_per_share) / 1_000_000 - user_info.reward_debt;
        if (pending > 0) {
            coin::transfer(account, &signer::address_of(account), pending);
        }

        user_info.reward_debt = (user_info.amount * chef.pool_info.acc_reward_per_share) / 1_000_000;
    }
}
